# Workstation Heartbeat Service (Rust + Axum)

Real-time workstation usage broadcast service for ABU Zaria CBT.

This service is part of the Rust proctoring lane. It handles secure workstation
presence telemetry, not live camera or media streaming.

## Why

- Streams workstation usage changes (`candidateLoggedIn`, `inExam`, `submitted`) with no page refresh.
- Lets invigilator dashboard update immediately when candidates submit.
- Central place to enforce workstation telemetry integrity before backend persistence.
- Keeps proctoring metadata in Rust while live media stays in the Go gateway.

## Run

```bash
cd backend/workstation_heartbeat_service
cargo run
```

Optional bind override:

```bash
HEARTBEAT_BIND_ADDR=0.0.0.0:8088 cargo run
```

## Endpoints

- `GET /` -> health (`ok`)
- `GET /ws/workstation` -> workstation clients publish heartbeat events
- `GET /ws/invigilator?centerName=ABU` -> invigilator clients receive snapshot + live updates

## Workstation Message

```json
{
  "kind": "heartbeat",
  "payload": {
    "workstationId": "ABU-CBT-A12F-93KD-7M21",
    "centerName": "ABU",
    "hallName": "Hall A",
    "seatNumber": "A-01",
    "registrationNumber": "ABU/CSC/001",
    "candidateName": "Zainab Musa",
    "examTitle": "CSC 305 - Data Structures",
    "usageState": "submitted",
    "workstationStatus": "whitelisted",
    "eventAtIso": "2026-03-07T11:42:20.102Z"
  }
}
```

## Server Broadcast

- Initial snapshot:
```json
{ "kind": "snapshot", "records": [ ... ] }
```

- Live update:
```json
{ "kind": "presenceUpdate", "record": { ... } }
```
