# ABU Zaria CBT

## Interactive UI demo

Run `flutter run -d chrome` or `flutter run -d windows`. The app opens the sign-in
screen. Students enter their registration number, click Next and complete the
fingerprint demo. Invigilators and administrators use username/password sign-in. See [Demo login accounts](docs/demo-accounts.md) for all accounts.
Sign out before switching accounts.

- Administrator: create exam drafts, publish/start/end sessions, add and approve
  single-choice questions, register candidates and publish illustrative results.
- Invigilator: verify attendance, inspect hall seating and resolve incidents.
- Student: preview published results and open the existing practice exam journey.

The Student role’s practice button opens a dedicated practice centre with course
search, instructions, identity confirmation, a responsive question player, answer
review and a session summary. Answers are retained during the running session;
refreshing or closing the app does not preserve the attempt. Use
`flutter test test/practice_flow_test.dart` to check the practice journey.

Workspace data is in memory and resets when the app restarts. The question bank
and sample timetable demonstrate administration; the practice player uses its
existing multi-format question set. These are separate demo flows.

Validation: `flutter test` and `flutter analyze`. On Windows,
`flutter test tool/ui_preview_test.dart` renders a desktop preview in
`docs/previews/abu-overview.png` using the installed Segoe UI font.

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
