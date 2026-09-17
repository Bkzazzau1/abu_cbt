use std::collections::HashMap;
use std::net::SocketAddr;
use std::sync::Arc;

use std::time::{SystemTime, UNIX_EPOCH};

use axum::extract::ws::{Message, WebSocket, WebSocketUpgrade};
use axum::extract::{Query, State};
use axum::response::IntoResponse;
use axum::routing::get;
use axum::Router;
use futures_util::{SinkExt, StreamExt};
use serde::{Deserialize, Serialize};
use tokio::sync::{broadcast, mpsc, RwLock};
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
    /// Bounded log of on-device detection evidence (phone, impersonation,
    /// elevated talking, unauthorized USB device, …) for invigilator review,
    /// newest last. Bounded so a long exam day can't grow this unbounded.
    evidence_events: Arc<RwLock<Vec<EvidenceEvent>>>,
    /// Keyed by report id.
    malpractice_reports: Arc<RwLock<HashMap<String, MalpracticeReport>>>,
    /// Keyed by workstation_id — the live sender half of that workstation's
    /// own socket, so an invigilator action (terminate exam) can push a
    /// command down to exactly that one candidate's connection rather than
    /// broadcasting to everyone. Populated once a workstation's first
    /// heartbeat/event arrives (its id isn't known before then) and removed
    /// when that connection closes.
    workstation_senders: Arc<RwLock<HashMap<String, mpsc::UnboundedSender<Message>>>>,
    broadcaster: broadcast::Sender<ServerMessage>,
    http: reqwest::Client,
    similarity_service_url: String,
}

const MAX_EVIDENCE_EVENTS: usize = 500;

/// A unique-enough id for a new evidence/report record. Every timestamp
/// field in this service (here and elsewhere) is supplied by the Dart
/// client's own wall-clock, not computed server-side, so this only needs to
/// be unique, not meaningful as a date.
fn generate_id(workstation_id: &str) -> String {
    let now_millis = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_millis())
        .unwrap_or(0);
    format!("{workstation_id}-{now_millis}")
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

/// Structured on-device detection evidence for invigilator review — timing
/// metadata (and a confidence score, where the detector produces one)
/// computed on the candidate's own workstation, never a saved frame/photo
/// (the camera detector never writes frames to disk; see
/// backend/object_detection/README.md) and never a recorded audio clip
/// (the microphone check classifies and immediately discards each ~30ms
/// block). This is the machine's own account of what it detected, not a
/// claim of proven misconduct. `evidence_type` is one of "phone",
/// "identity" (candidate doesn't match the enrolled photo), "talking"
/// (elevated voice activity near the seat), or "usb" (unauthorized device
/// connected) — kept as a plain string, like `usage_state`/`risk_level`
/// elsewhere in this service, so new types don't require a schema change.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
struct EvidenceEvent {
    id: String,
    workstation_id: String,
    center_name: String,
    hall_name: String,
    seat_number: String,
    registration_number: String,
    candidate_name: String,
    exam_title: String,
    evidence_type: String,
    /// Not every evidence type has a numeric confidence (e.g. a USB device
    /// connection is a plain fact, not a model score).
    confidence: Option<f64>,
    /// Human-readable specifics for evidence types without a natural
    /// single-number summary (e.g. which USB device, or the talking ratio).
    #[serde(default)]
    details: String,
    detected_at_iso: String,
    #[serde(default)]
    escalated: bool,
    #[serde(default)]
    escalated_by: String,
    #[serde(default)]
    escalated_at_iso: String,
}

#[derive(Debug, Clone, Deserialize)]
#[serde(rename_all = "camelCase")]
struct EvidencePayload {
    workstation_id: String,
    center_name: String,
    hall_name: String,
    seat_number: String,
    registration_number: String,
    candidate_name: String,
    exam_title: String,
    evidence_type: String,
    confidence: Option<f64>,
    #[serde(default)]
    details: String,
    detected_at_iso: String,
}

/// An invigilator's formal record of an exam-malpractice incident — separate
/// from (but often referencing) an automated evidence event, since not every
/// incident starts from an automated flag and not every automated flag
/// becomes a formal report.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
struct MalpracticeReport {
    id: String,
    workstation_id: String,
    center_name: String,
    hall_name: String,
    seat_number: String,
    registration_number: String,
    candidate_name: String,
    exam_title: String,
    malpractice_type: String,
    severity: String,
    description: String,
    action_taken: String,
    reported_by: String,
    reported_at_iso: String,
    #[serde(default)]
    escalated: bool,
    #[serde(default)]
    escalated_by: String,
    #[serde(default)]
    escalated_at_iso: String,
    #[serde(default)]
    exam_terminated: bool,
}

#[derive(Debug, Clone, Deserialize)]
#[serde(rename_all = "camelCase")]
struct MalpracticeReportPayload {
    workstation_id: String,
    center_name: String,
    hall_name: String,
    seat_number: String,
    registration_number: String,
    candidate_name: String,
    exam_title: String,
    malpractice_type: String,
    severity: String,
    description: String,
    action_taken: String,
    reported_by: String,
    reported_at_iso: String,
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
    /// Workstation -> server: the local detector flagged something
    /// (phone/identity/talking/usb — see `EvidencePayload::evidence_type`).
    EvidenceDetected { payload: EvidencePayload },
    /// Invigilator -> server: force this one workstation's exam to end now.
    ///
    /// `rename_all` on the enum only renames variant names used as the
    /// `kind` tag, not each struct-variant's own fields — those need their
    /// own `rename_all` to get camelCase wire field names too.
    #[serde(rename_all = "camelCase")]
    TerminateExam {
        workstation_id: String,
        reason: String,
        issued_by: String,
        issued_at_iso: String,
    },
    /// Invigilator -> server: hand an evidence event to the exam officer
    /// for review.
    #[serde(rename_all = "camelCase")]
    EscalateEvidenceEvent {
        event_id: String,
        escalated_by: String,
        escalated_at_iso: String,
    },
    /// Invigilator -> server: file a formal malpractice report.
    SubmitMalpracticeReport { payload: MalpracticeReportPayload },
    /// Invigilator -> server: hand a filed report to the exam officer.
    #[serde(rename_all = "camelCase")]
    EscalateMalpracticeReport {
        report_id: String,
        escalated_by: String,
        escalated_at_iso: String,
    },
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
    EvidenceSnapshot { events: Vec<EvidenceEvent> },
    EvidenceUpdate { event: EvidenceEvent },
    MalpracticeSnapshot { reports: Vec<MalpracticeReport> },
    MalpracticeUpdate { report: MalpracticeReport },
    /// Sent to exactly one workstation's own connection (looked up by id),
    /// never broadcast — see `AppState::workstation_senders`.
    #[serde(rename_all = "camelCase")]
    Command {
        action: String,
        reason: String,
        issued_by: String,
    },
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
        evidence_events: Arc::new(RwLock::new(Vec::new())),
        malpractice_reports: Arc::new(RwLock::new(HashMap::new())),
        workstation_senders: Arc::new(RwLock::new(HashMap::new())),
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

async fn handle_workstation_socket(socket: WebSocket, state: AppState) {
    info!("workstation websocket connected");

    let (mut ws_sender, mut ws_receiver) = socket.split();
    // A dedicated channel for this one connection so an invigilator's
    // TerminateExam command (looked up by workstation id in
    // `workstation_senders`) can be pushed straight to this candidate's
    // socket, bypassing the general broadcaster entirely.
    let (cmd_tx, mut cmd_rx) = mpsc::unbounded_channel::<Message>();
    let forward_task = tokio::spawn(async move {
        while let Some(message) = cmd_rx.recv().await {
            if ws_sender.send(message).await.is_err() {
                break;
            }
        }
    });

    async fn send_error(cmd_tx: &mpsc::UnboundedSender<Message>, message: &str) {
        let _ = cmd_tx.send(Message::Text(
            serde_json::to_string(&ServerMessage::Error {
                message: message.to_string(),
            })
            .unwrap_or_else(|_| "{\"kind\":\"error\",\"message\":\"bad request\"}".to_string()),
        ));
    }

    let mut registered_id: Option<String> = None;

    while let Some(message_result) = ws_receiver.next().await {
        match message_result {
            Ok(Message::Text(text)) => {
                let parsed = serde_json::from_str::<ClientMessage>(&text);
                match parsed {
                    Ok(ClientMessage::Heartbeat { payload }) => {
                        if payload.workstation_id.trim().is_empty() {
                            send_error(&cmd_tx, "workstationId is required").await;
                            continue;
                        }

                        {
                            let mut senders = state.workstation_senders.write().await;
                            senders.insert(payload.workstation_id.clone(), cmd_tx.clone());
                        }
                        registered_id = Some(payload.workstation_id.clone());

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
                    Ok(ClientMessage::EvidenceDetected { payload }) => {
                        if payload.workstation_id.trim().is_empty() {
                            send_error(&cmd_tx, "workstationId is required").await;
                            continue;
                        }

                        {
                            let mut senders = state.workstation_senders.write().await;
                            senders.insert(payload.workstation_id.clone(), cmd_tx.clone());
                        }
                        registered_id = Some(payload.workstation_id.clone());

                        record_evidence(&state, payload).await;
                    }
                    Ok(
                        ClientMessage::TerminateExam { .. }
                        | ClientMessage::EscalateEvidenceEvent { .. }
                        | ClientMessage::SubmitMalpracticeReport { .. }
                        | ClientMessage::EscalateMalpracticeReport { .. },
                    ) => {
                        warn!("invigilator-only message sent on workstation socket; ignored");
                    }
                    Err(err) => {
                        warn!("invalid workstation payload: {err}");
                        send_error(&cmd_tx, "invalid payload").await;
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

    if let Some(id) = registered_id {
        let mut senders = state.workstation_senders.write().await;
        // Only remove if this connection is still the registered one — a
        // reconnect may have already replaced it with a newer sender.
        if senders.get(&id).map(|s| s.same_channel(&cmd_tx)).unwrap_or(false) {
            senders.remove(&id);
        }
    }
    forward_task.abort();

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

/// Records an on-device detection event from a workstation's local detector
/// and broadcasts it to every connected invigilator immediately, so it
/// shows up as evidence to review without waiting for a heartbeat cycle.
async fn record_evidence(state: &AppState, payload: EvidencePayload) {
    let event = EvidenceEvent {
        id: generate_id(&payload.workstation_id),
        workstation_id: payload.workstation_id,
        center_name: payload.center_name,
        hall_name: payload.hall_name,
        seat_number: payload.seat_number,
        registration_number: payload.registration_number,
        candidate_name: payload.candidate_name,
        exam_title: payload.exam_title,
        evidence_type: payload.evidence_type,
        confidence: payload.confidence,
        details: payload.details,
        detected_at_iso: payload.detected_at_iso,
        escalated: false,
        escalated_by: String::new(),
        escalated_at_iso: String::new(),
    };

    {
        let mut events = state.evidence_events.write().await;
        events.push(event.clone());
        if events.len() > MAX_EVIDENCE_EVENTS {
            let overflow = events.len() - MAX_EVIDENCE_EVENTS;
            events.drain(0..overflow);
        }
    }

    let _ = state
        .broadcaster
        .send(ServerMessage::EvidenceUpdate { event });
}

/// Marks a previously-recorded evidence event as escalated to the exam
/// officer and re-broadcasts it. A no-op (with a warning) if the event id
/// is unknown, e.g. a stale id from a client that hasn't caught up.
async fn escalate_evidence_event(
    state: &AppState,
    event_id: String,
    escalated_by: String,
    escalated_at_iso: String,
) {
    let updated = {
        let mut events = state.evidence_events.write().await;
        let event = events.iter_mut().find(|e| e.id == event_id);
        match event {
            Some(event) => {
                event.escalated = true;
                event.escalated_by = escalated_by;
                event.escalated_at_iso = escalated_at_iso;
                Some(event.clone())
            }
            None => None,
        }
    };

    match updated {
        Some(event) => {
            let _ = state
                .broadcaster
                .send(ServerMessage::EvidenceUpdate { event });
        }
        None => warn!("escalate requested for unknown evidence event id {event_id}"),
    }
}

/// Files a new formal malpractice report and broadcasts it to invigilators.
async fn record_malpractice_report(state: &AppState, payload: MalpracticeReportPayload) {
    let report = MalpracticeReport {
        id: generate_id(&payload.workstation_id),
        workstation_id: payload.workstation_id,
        center_name: payload.center_name,
        hall_name: payload.hall_name,
        seat_number: payload.seat_number,
        registration_number: payload.registration_number,
        candidate_name: payload.candidate_name,
        exam_title: payload.exam_title,
        malpractice_type: payload.malpractice_type,
        severity: payload.severity,
        description: payload.description,
        action_taken: payload.action_taken,
        reported_by: payload.reported_by,
        reported_at_iso: payload.reported_at_iso,
        escalated: false,
        escalated_by: String::new(),
        escalated_at_iso: String::new(),
        exam_terminated: false,
    };

    {
        let mut reports = state.malpractice_reports.write().await;
        reports.insert(report.id.clone(), report.clone());
    }

    let _ = state
        .broadcaster
        .send(ServerMessage::MalpracticeUpdate { report });
}

/// Marks a filed malpractice report as escalated to the exam officer.
async fn escalate_malpractice_report(
    state: &AppState,
    report_id: String,
    escalated_by: String,
    escalated_at_iso: String,
) {
    let updated = {
        let mut reports = state.malpractice_reports.write().await;
        reports.get_mut(&report_id).map(|report| {
            report.escalated = true;
            report.escalated_by = escalated_by;
            report.escalated_at_iso = escalated_at_iso;
            report.clone()
        })
    };

    match updated {
        Some(report) => {
            let _ = state
                .broadcaster
                .send(ServerMessage::MalpracticeUpdate { report });
        }
        None => warn!("escalate requested for unknown malpractice report id {report_id}"),
    }
}

/// Pushes a command straight to one workstation's own connection (looked up
/// by id in the registry) rather than the general broadcaster, and stamps
/// the corresponding presence record so every invigilator sees the outcome.
/// Silently does nothing beyond logging if that workstation isn't currently
/// connected — there is no queued/offline delivery in this service.
async fn terminate_exam(
    state: &AppState,
    workstation_id: String,
    reason: String,
    issued_by: String,
    issued_at_iso: String,
) {
    let sender = {
        let senders = state.workstation_senders.read().await;
        senders.get(&workstation_id).cloned()
    };

    let Some(sender) = sender else {
        warn!("terminate requested for workstation {workstation_id} with no live connection");
        return;
    };

    let command = ServerMessage::Command {
        action: "terminate_exam".to_string(),
        reason: reason.clone(),
        issued_by: issued_by.clone(),
    };
    if let Ok(text) = serde_json::to_string(&command) {
        let _ = sender.send(Message::Text(text));
    }

    let updated = {
        let mut records = state.live_records.write().await;
        records.get_mut(&workstation_id).map(|record| {
            record.risk_flagged = true;
            record.risk_reasons.push(format!(
                "Exam terminated by invigilator {issued_by} at {issued_at_iso}: {reason}"
            ));
            record.clone()
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

    let evidence_events = {
        let events = state.evidence_events.read().await;
        events
            .iter()
            .filter(|event| {
                if let Some(center_name) = center_filter.as_ref() {
                    return event.center_name.eq_ignore_ascii_case(center_name);
                }
                true
            })
            .cloned()
            .collect::<Vec<_>>()
    };
    if let Ok(payload) =
        serde_json::to_string(&ServerMessage::EvidenceSnapshot { events: evidence_events })
    {
        if sender.send(Message::Text(payload)).await.is_err() {
            return;
        }
    }

    let malpractice_reports = {
        let reports = state.malpractice_reports.read().await;
        reports
            .values()
            .filter(|report| {
                if let Some(center_name) = center_filter.as_ref() {
                    return report.center_name.eq_ignore_ascii_case(center_name);
                }
                true
            })
            .cloned()
            .collect::<Vec<_>>()
    };
    if let Ok(payload) = serde_json::to_string(&ServerMessage::MalpracticeSnapshot {
        reports: malpractice_reports,
    }) {
        if sender.send(Message::Text(payload)).await.is_err() {
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
                        (Some(center_name), ServerMessage::EvidenceUpdate { event }) => {
                            event.center_name.eq_ignore_ascii_case(center_name)
                        }
                        (Some(center_name), ServerMessage::MalpracticeUpdate { report }) => {
                            report.center_name.eq_ignore_ascii_case(center_name)
                        }
                        (
                            Some(_),
                            ServerMessage::Snapshot { .. }
                            | ServerMessage::EvidenceSnapshot { .. }
                            | ServerMessage::MalpracticeSnapshot { .. },
                        ) => false,
                        (Some(_), ServerMessage::Error { .. } | ServerMessage::Command { .. }) => {
                            true
                        }
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
                Ok(ClientMessage::TerminateExam {
                    workstation_id,
                    reason,
                    issued_by,
                    issued_at_iso,
                }) => {
                    terminate_exam(&state, workstation_id, reason, issued_by, issued_at_iso).await;
                }
                Ok(ClientMessage::EscalateEvidenceEvent {
                    event_id,
                    escalated_by,
                    escalated_at_iso,
                }) => {
                    escalate_evidence_event(&state, event_id, escalated_by, escalated_at_iso).await;
                }
                Ok(ClientMessage::SubmitMalpracticeReport { payload }) => {
                    record_malpractice_report(&state, payload).await;
                }
                Ok(ClientMessage::EscalateMalpracticeReport {
                    report_id,
                    escalated_by,
                    escalated_at_iso,
                }) => {
                    escalate_malpractice_report(&state, report_id, escalated_by, escalated_at_iso)
                        .await;
                }
                Ok(ClientMessage::Heartbeat { .. })
                | Ok(ClientMessage::AnswerSubmission { .. })
                | Ok(ClientMessage::EvidenceDetected { .. }) => {
                    warn!("workstation-only message sent on invigilator socket; ignored");
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
