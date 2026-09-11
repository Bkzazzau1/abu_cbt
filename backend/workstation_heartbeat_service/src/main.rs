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
    broadcaster: broadcast::Sender<ServerMessage>,
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
}

fn default_true() -> bool {
    true
}

#[derive(Debug, Deserialize)]
#[serde(tag = "kind", rename_all = "camelCase")]
enum ClientMessage {
    Heartbeat { payload: WorkstationPresenceRecord },
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
    let state = AppState {
        live_records: Arc::new(RwLock::new(HashMap::new())),
        broadcaster: tx,
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

                        {
                            let mut records = state.live_records.write().await;
                            records.insert(payload.workstation_id.clone(), payload.clone());
                        }

                        let _ = state
                            .broadcaster
                            .send(ServerMessage::PresenceUpdate { record: payload });
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
