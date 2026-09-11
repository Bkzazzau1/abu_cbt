# Runtime Boundaries

This repository uses a split runtime model so the media lane and the
proctoring lane stay separate.

## Ownership

- Go owns live camera and streaming responsibilities.
- Rust owns proctoring and secure workstation services.
- Flutter owns the user interface and client-side coordination.

## Go Responsibilities

Path: `backend/live_camera_gateway`

- Camera session ingress
- Live stream transport
- Signaling and relay coordination
- Stream fan-out to invigilator-facing consumers

## Rust Responsibilities

Paths:

- `native/ks_sentinel`
- `backend/workstation_heartbeat_service`

- Workstation fingerprinting
- USB and process sentinel checks
- Telemetry signing and verification
- Presence heartbeat broadcast
- Risk evaluation metadata for invigilators

## Guardrail

Media payload handling should not be added to the Rust services.
Proctoring policy and secure telemetry should not be moved into the Go media
service.
