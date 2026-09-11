# K-SLAS Sentinel Migration Plan

This project now includes:

- Realtime presence backend: `backend/workstation_heartbeat_service`
- Sentinel security crate: `native/ks_sentinel`
- Live camera gateway scaffold: `backend/live_camera_gateway`

## Language boundary

- Go owns live camera and streaming responsibilities.
- Rust owns proctoring, workstation trust, and signed telemetry.

## Migration steps

1. FRB integration
- Add FRB bindings for `native/ks_sentinel`.
- Start sentinel runtime from Flutter app bootstrap.

2. Workstation registration hardening
- During registration, store:
  - `fingerprintSha256`
  - derived `workstationId`
  - public signing key

3. Exam telemetry signing
- For each heartbeat/submit event:
  - sign payload in Rust
  - send payload + signature + public key id

4. Backend verification
- Axum verifies signature and workstation fingerprint binding.
- Reject mismatched or untrusted workstation submissions.

5. Offline recovery
- Rust writes encrypted autosaves (`AES-256-GCM`) every few seconds.
- On restore, decrypted snapshots are replayed into current answer store.

## Immediate next implementation targets

- Add FRB generated bindings and a `KsSentinelService` in Flutter.
- Move existing Dart autosave calls to `ks_sentinel::secure_fog_sync`.
- Send sentinel violation events (USB/process) to invigilator websocket feed.
