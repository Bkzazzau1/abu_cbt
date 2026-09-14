# Windows USB monitoring

Rust subscribes to `GUID_DEVINTERFACE_USB_DEVICE` arrival notifications using
`CM_Register_Notification` (Windows 8+). Existing connected devices do not generate
arrival notifications. Reconnecting a device generates a new review flag. A USB
hub may produce several events. This detects connections, not malicious intent,
file access, or all forms of hardware tampering. No Python or ML is involved.

Flutter starts the subscription before the exam timer, drains Rust's bounded
event queue every 500 ms, and stops/unregisters at time expiry, submission, or
controller disposal. Rust frees each event string after Flutter copies it.
Missing DLLs, unsupported platforms and queue overflow produce coverage warnings.

The Windows CMake build requires Cargo and the matching Rust MSVC toolchain.
It builds and bundles `usb_monitor.dll` beside the Flutter executable. For an
ARM64 build, use an ARM64 Rust host toolchain. Browser/mobile builds report USB
monitoring unavailable; they cannot monitor the candidate's Windows USB bus.

Events appear in the existing invigilator workstation risk details, with the
candidate/hall/seat from the presence record. A ten-second heartbeat repeats the
session flags after transient disconnections. Up to 100 flags are retained per
session in shared preferences under `usb.audit.<workstation>.<exam>.<attempt>`;
overflow is explicitly flagged. This local audit is not a tamper-proof archive
or an acknowledged server delivery queue. The existing heartbeat backend keeps
its live records in memory. No new server endpoint is required.

Checks:

```
cargo test --locked --manifest-path backend/usb_monitor/Cargo.toml
flutter test test/usb_monitor_flow_test.dart
```

Hardware acceptance: begin an exam with keyboard/mouse already connected; verify
no arrival flags for them. Connect a USB device and check officer risk details
for its ID/time/seat; unplug and reconnect to verify a second flag. End the exam
and verify subsequent connections generate no flags. Repeat with the heartbeat
server temporarily unavailable and verify the flags arrive after reconnecting
while the exam remains active.

API reference: https://learn.microsoft.com/en-us/windows/win32/api/cfgmgr32/nf-cfgmgr32-cm_register_notification
