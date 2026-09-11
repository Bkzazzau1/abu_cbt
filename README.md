# K-SLAS CBT

Computer-based testing application with Flutter on the client and native
backend/runtime services for secure exam delivery.

## Service Ownership

- Flutter app: exam flow, invigilator dashboard, workstation UI, and service
  orchestration.
- Go live camera and streaming lane: `backend/live_camera_gateway`
- Rust proctoring and secure telemetry lane:
  `native/ks_sentinel`, `backend/workstation_heartbeat_service`

## Boundary Rule

- Live camera transport, signaling, and stream fan-out belong in Go.
- Proctoring, workstation integrity, USB/process monitoring, signing, and
  presence telemetry belong in Rust.

## Repository Notes

- The Rust services are already active in this repo.
- The Go live camera gateway is scaffolded here so future streaming work lands
  in the correct language boundary from the start.
