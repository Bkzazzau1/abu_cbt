use std::collections::HashMap;
use std::net::SocketAddr;
use std::sync::Arc;

use axum::extract::ws::{Message, WebSocket, WebSocketUpgrade};
use axum::extract::{Query, State};
use axum::response::IntoResponse;
use axum::routing::get;
use axum::Router;
use futures_util::{SinkExt, StreamExt};
use serde::{Deserialize, Serialize};
use tokio::sync::{broadcast, RwLock};
use tracing::{error, info, warn};

#[derive(Clone)]
struct AppState {
    live_records: Arc<RwLock<HashMap<String, WorkstationPresenceRecord>>>,
    /// Keyed by registration number — the invigilator's physical check-in
    /// record, used to catch a candidate submitting from a different
    /// workstation/hall/seat than where they were checked in.
    check_in_records: Arc<RwLock<HashMap<String, CheckInRecord>>>,
    /// Keyed by "hall|examId|questionId" — every candidate's answer text
    /// for that question in that hall, so a new submission can be checked
    /// for similarity against the rest of the hall's answers so far.
    answer_pools: Arc<RwLock<HashMap<String, Vec<AnswerEntry>>>>,
    broadcaster: broadcast::Sender<ServerMessage>,
    http: reqwest::Client,
    similarity_service_url: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
struct AnswerEntry {
    registration_number: String,
    candidate_name: String,
    seat_number: String,
    text: String,
}

#[derive(Debug, Clone, Deserialize)]
#[serde(rename_all = "camelCase")]
struct AnswerSubmissionPayload {
    registration_number: String,
    candidate_name: String,
    hall_name: String,
    seat_number: String,
    exam_id: String,
    question_id: String,
    text_answer: String,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
struct SimilarityBatchRequest<'a> {
    entries: &'a [AnswerEntry],
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
struct SimilarityBatchResponse {
    #[serde(default)]
    flagged_pairs: Vec<FlaggedPair>,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
struct FlaggedPair {
    registration_number_a: String,
    seat_a: String,
    registration_number_b: String,
    seat_b: String,
    similarity: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
struct CheckInRecord {
    registration_number: String,
    candidate_name: String,
    hall_name: String,
    seat_number: String,
    #[serde(default)]
    checked_in_at_iso: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
struct WorkstationPresenceRecord {
    workstation_id: String,
    center_name: String,
    hall_name: String,
    seat_number: String,
    registration_number: String,
    candidate_name: String,
    exam_title: String,
    usage_state: String,
    workstation_status: String,
    event_at_iso: String,
    #[serde(default)]
    risk_flagged: bool,
    #[serde(default)]
    is_new_workstation: bool,
    #[serde(default)]
    client_ip_address: String,
    #[serde(default)]
    expected_hall_ip_range: String,
    #[serde(default = "default_true")]
    ip_in_expected_range: bool,
    #[serde(default)]
    risk_reasons: Vec<String>,
    #[serde(default)]
    workstation_approved: bool,
    #[serde(default)]
    risk_score: i32,
    #[serde(default)]
    risk_level: String,
    #[serde(default)]
    check_in_mismatch: bool,
    #[serde(default)]
    check_in_mismatch_reason: String,
    #[serde(default)]
    similarity_flagged: bool,
    #[serde(default)]
    similarity_reason: String,
}

fn default_true() -> bool {
    true
}

#[derive(Debug, Deserialize)]
#[serde(tag = "kind", rename_all = "camelCase")]
enum ClientMessage {
    Heartbeat { payload: WorkstationPresenceRecord },
    CheckIn { payload: CheckInRecord },
    AnswerSubmission { payload: AnswerSubmissionPayload },
}

/// Compares a live workstation heartbeat against the invigilator's physical
/// check-in record for the same candidate (by registration number) and
/// stamps a mismatch flag/reason onto the heartbeat if the hall or seat
/// don't line up. Empty-field check-ins are ignored (can't compare against
/// nothing) to avoid false positives before check-in data is filled in.
fn apply_check_in_mismatch(
    mut record: WorkstationPresenceRecord,
    check_in: Option<&CheckInRecord>,
) -> WorkstationPresenceRecord {
    let Some(check_in) = check_in else {
        return record;
    };
    if check_in.hall_name.trim().is_empty() && check_in.seat_number.trim().is_empty() {
        return record;
    }

    let hall_mismatch = !check_in.hall_name.trim().is_empty()
        && !check_in
            .hall_name
            .trim()
            .eq_ignore_ascii_case(record.hall_name.trim());
    let seat_mismatch = !check_in.seat_number.trim().is_empty()
        && !check_in
            .seat_number
            .trim()
            .eq_ignore_ascii_case(record.seat_number.trim());

    if hall_mismatch || seat_mismatch {
        record.check_in_mismatch = true;
        record.check_in_mismatch_reason = format!(
            "Checked in at {}/{} but active from {}/{}",
            check_in.hall_name, check_in.seat_number, record.hall_name, record.seat_number
        );
    } else {
        record.check_in_mismatch = false;
        record.check_in_mismatch_reason = String::new();
    }

    record
}

#[derive(Debug, Clone, Serialize)]
#[serde(tag = "kind", rename_all = "camelCase")]
enum ServerMessage {
    Snapshot { records: Vec<WorkstationPresenceRecord> },
    PresenceUpdate { record: WorkstationPresenceRecord },
    Error { message: String },
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
struct WsQuery {
    center_name: Option<String>,
}

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt()
        .with_env_filter(
            std::env::var("RUST_LOG")
                .unwrap_or_else(|_| "workstation_heartbeat_service=info,tower_http=info".to_string()),
        )
        .init();

    let (tx, _rx) = broadcast::channel::<ServerMessage>(2048);
    let similarity_service_url = std::env::var("ANSWER_SIMILARITY_URL")
        .unwrap_or_else(|_| "http://127.0.0.1:8099/similarity/batch".to_string());
    let state = AppState {
        live_records: Arc::new(RwLock::new(HashMap::new())),
        check_in_records: Arc::new(RwLock::new(HashMap::new())),
        answer_pools: Arc::new(RwLock::new(HashMap::new())),
        broadcaster: tx,
        http: reqwest::Client::builder()
            .timeout(std::time::Duration::from_secs(5))
            .build()
            .expect("failed to build http client"),
        similarity_service_url,
    };

    let app = Router::new()
        .route("/", get(health))
        .route("/ws/workstation", get(workstation_ws))
        .route("/ws/invigilator", get(invigilator_ws))
        .with_state(state);

    let addr: SocketAddr = std::env::var("HEARTBEAT_BIND_ADDR")
        .unwrap_or_else(|_| "0.0.0.0:8088".to_string())
        .parse()
        .expect("invalid HEARTBEAT_BIND_ADDR");

    info!("heartbeat service listening on {addr}");
    let listener = tokio::net::TcpListener::bind(addr).await.expect("bind failed");
    axum::serve(listener, app).await.expect("server failed");
}

async fn health() -> &'static str {
    "ok"
}

async fn workstation_ws(ws: WebSocketUpgrade, State(state): State<AppState>) -> impl IntoResponse {
    ws.on_upgrade(move |socket| handle_workstation_socket(socket, state))
}

async fn invigilator_ws(
    ws: WebSocketUpgrade,
    State(state): State<AppState>,
    Query(query): Query<WsQuery>,
) -> impl IntoResponse {
    ws.on_upgrade(move |socket| handle_invigilator_socket(socket, state, query.center_name))
}

async fn handle_workstation_socket(mut socket: WebSocket, state: AppState) {
    info!("workstation websocket connected");

    while let Some(message_result) = socket.next().await {
        match message_result {
            Ok(Message::Text(text)) => {
                let parsed = serde_json::from_str::<ClientMessage>(&text);
                match parsed {
                    Ok(ClientMessage::Heartbeat { payload }) => {
                        if payload.workstation_id.trim().is_empty() {
                            let _ = socket
                                .send(Message::Text(
                                    serde_json::to_string(&ServerMessage::Error {
                                        message: "workstationId is required".to_string(),
                                    })
                                    .unwrap_or_else(|_| {
                                        "{\"kind\":\"error\",\"message\":\"bad request\"}".to_string()
                                    }),
                                ))
                                .await;
                            continue;
                        }

                        let check_in = {
                            let check_ins = state.check_in_records.read().await;
                            check_ins.get(&payload.registration_number).cloned()
                        };
                        let payload = apply_check_in_mismatch(payload, check_in.as_ref());

                        {
                            let mut records = state.live_records.write().await;
                            records.insert(payload.workstation_id.clone(), payload.clone());
                        }

                        let _ = state
                            .broadcaster
                            .send(ServerMessage::PresenceUpdate { record: payload });
                    }
                    Ok(ClientMessage::CheckIn { .. }) => {
                        warn!("check-in message sent on workstation socket; ignored");
                    }
                    Ok(ClientMessage::AnswerSubmission { payload }) => {
                        record_answer_submission(&state, payload).await;
                    }
                    Err(err) => {
                        warn!("invalid workstation payload: {err}");
                        let _ = socket
                            .send(Message::Text(
                                serde_json::to_string(&ServerMessage::Error {
                                    message: "invalid payload".to_string(),
                                })
                                .unwrap_or_else(|_| {
                                    "{\"kind\":\"error\",\"message\":\"invalid payload\"}".to_string()
                                }),
                            ))
                            .await;
                    }
                }
            }
            Ok(Message::Close(_)) => break,
            Ok(_) => {}
            Err(err) => {
                warn!("workstation websocket error: {err}");
                break;
            }
        }
    }

    info!("workstation websocket disconnected");
}

/// Stores an invigilator's check-in record and, if that candidate already
/// has a live workstation heartbeat on file, re-evaluates and re-broadcasts
/// it immediately rather than waiting for the next heartbeat to catch up.
async fn record_check_in(state: &AppState, payload: CheckInRecord) {
    if payload.registration_number.trim().is_empty() {
        return;
    }

    {
        let mut check_ins = state.check_in_records.write().await;
        check_ins.insert(payload.registration_number.clone(), payload.clone());
    }

    let updated = {
        let mut records = state.live_records.write().await;
        let existing = records
            .values()
            .find(|r| r.registration_number == payload.registration_number)
            .cloned();
        existing.map(|record| {
            let updated = apply_check_in_mismatch(record, Some(&payload));
            records.insert(updated.workstation_id.clone(), updated.clone());
            updated
        })
    };

    if let Some(record) = updated {
        let _ = state
            .broadcaster
            .send(ServerMessage::PresenceUpdate { record });
    }
}

/// Minimum trimmed answer length before we bother comparing it. Short
/// answers (numbers, single words) collide by coincidence, not collusion.
const MIN_ANSWER_LENGTH_FOR_SIMILARITY_CHECK: usize = 15;

/// Records a candidate's free-text answer into the shared per-hall pool for
/// that question, then asks the Python answer-similarity service to compare
/// it against every other answer in the pool so far. Any flagged pair gets
/// stamped onto both candidates' live workstation records and re-broadcast.
/// The AI call is best-effort: if the Python service is unreachable or
/// returns an error, we log and move on rather than blocking submission.
async fn record_answer_submission(state: &AppState, payload: AnswerSubmissionPayload) {
    let text = payload.text_answer.trim().to_string();
    if payload.registration_number.trim().is_empty()
        || text.chars().count() < MIN_ANSWER_LENGTH_FOR_SIMILARITY_CHECK
    {
        return;
    }

    let pool_key = format!(
        "{}|{}|{}",
        payload.hall_name.trim(),
        payload.exam_id.trim(),
        payload.question_id.trim()
    );

    let entry = AnswerEntry {
        registration_number: payload.registration_number.clone(),
        candidate_name: payload.candidate_name.clone(),
        seat_number: payload.seat_number.clone(),
        text,
    };

    let pool_snapshot = {
        let mut pools = state.answer_pools.write().await;
        let pool = pools.entry(pool_key).or_default();
        pool.retain(|e| e.registration_number != entry.registration_number);
        pool.push(entry);
        pool.clone()
    };

    if pool_snapshot.len() < 2 {
        return;
    }

    let response = state
        .http
        .post(&state.similarity_service_url)
        .json(&SimilarityBatchRequest {
            entries: &pool_snapshot,
        })
        .send()
        .await;

    let body = match response {
        Ok(resp) => resp.json::<SimilarityBatchResponse>().await,
        Err(err) => {
            warn!("answer similarity service unreachable: {err}");
            return;
        }
    };

    let flagged_pairs = match body {
        Ok(parsed) => parsed.flagged_pairs,
        Err(err) => {
            warn!("invalid answer similarity response: {err}");
            return;
        }
    };

    for pair in flagged_pairs {
        let percent = (pair.similarity * 100.0).round() as i32;
        let mut records = state.live_records.write().await;

        for (reg, other_seat) in [
            (&pair.registration_number_a, &pair.seat_b),
            (&pair.registration_number_b, &pair.seat_a),
        ] {
            if let Some(record) = records.values_mut().find(|r| &r.registration_number == reg) {
                record.similarity_flagged = true;
                record.similarity_reason = format!(
                    "Answer {percent}% similar to seat {other_seat}'s answer on the same question."
                );
                let _ = state.broadcaster.send(ServerMessage::PresenceUpdate {
                    record: record.clone(),
                });
            }
        }
    }
}

async fn handle_invigilator_socket(
    socket: WebSocket,
    state: AppState,
    center_filter: Option<String>,
) {
    let (mut sender, mut receiver) = socket.split();
    let mut stream = state.broadcaster.subscribe();

    let records = {
        let records = state.live_records.read().await;
        records
            .values()
            .filter(|record| {
                if let Some(center_name) = center_filter.as_ref() {
                    return record.center_name.eq_ignore_ascii_case(center_name);
                }
                true
            })
            .cloned()
            .collect::<Vec<_>>()
    };

    if let Ok(snapshot_payload) = serde_json::to_string(&ServerMessage::Snapshot { records }) {
        if sender.send(Message::Text(snapshot_payload)).await.is_err() {
            return;
        }
    }

    let send_task = tokio::spawn(async move {
        loop {
            match stream.recv().await {
                Ok(msg) => {
                    let allowed = match (&center_filter, &msg) {
                        (Some(center_name), ServerMessage::PresenceUpdate { record }) => {
                            record.center_name.eq_ignore_ascii_case(center_name)
                        }
                        (Some(_), ServerMessage::Snapshot { .. }) => false,
                        (Some(_), ServerMessage::Error { .. }) => true,
                        (None, _) => true,
                    };

                    if !allowed {
                        continue;
                    }

                    match serde_json::to_string(&msg) {
                        Ok(text) => {
                            if sender.send(Message::Text(text)).await.is_err() {
                                break;
                            }
                        }
                        Err(err) => {
                            error!("failed to serialize server message: {err}");
                        }
                    }
                }
                Err(err) => {
                    warn!("broadcast recv error: {err}");
                    break;
                }
            }
        }
    });

    while let Some(result) = receiver.next().await {
        match result {
            Ok(Message::Text(text)) => match serde_json::from_str::<ClientMessage>(&text) {
                Ok(ClientMessage::CheckIn { payload }) => {
                    record_check_in(&state, payload).await;
                }
                Ok(ClientMessage::Heartbeat { .. }) | Ok(ClientMessage::AnswerSubmission { .. }) => {
                    warn!("heartbeat/answer message sent on invigilator socket; ignored");
                }
                Err(err) => {
                    warn!("invalid invigilator payload: {err}");
                }
            },
            Ok(Message::Close(_)) => break,
            Ok(_) => {}
            Err(err) => {
                warn!("invigilator websocket read error: {err}");
                break;
            }
        }
    }

    send_task.abort();
}
