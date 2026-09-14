# Local object detection, identity snapshot and voice-activity checks

Python runs YOLO11 nano on CPU, filtering its COCO `cell phone` class. OpenCV
holds only the newest camera frame; inference samples every three seconds. Two
consecutive samples at confidence >= 0.65 trigger a **possible phone** flag;
continued detections are limited to one flag every 30 seconds. These are initial
settings requiring validation in the actual hall, not measured accuracy claims.
Phones out of view, concealed objects and poor lighting may be missed.

Flutter starts/stops the worker with the exam and shows camera status. It sends
timestamped flags through the existing Rust heartbeat backend to invigilator
risk details and keeps a bounded local audit under `objects.audit.*`. Review is
manual. Detector frames are neither saved nor uploaded.

Rust continues to own USB notification memory and backend presence state. Python
owns the model, camera and microphone buffers. No Go camera gateway is required.

## Identity snapshot check (impersonation)

When Flutter passes `--reference-photo`, the worker detects the largest face in
that enrolled photo once at startup (OpenCV Haar cascade) and trains an LBPH
face recognizer on it — a lightweight, fully local/offline technique, not a
deep embedding model. At three random points within the middle 10%-90% of the
exam window (`IdentitySchedule`, spaced apart so checks don't cluster), it
grabs the current camera frame, detects a face, and compares it against the
reference. A mismatch above the distance threshold emits an `identity` flag
through the same risk-details path as phone detection; a match, or no face
found in that frame, emits nothing (a missed frame due to camera angle isn't
evidence of anything). The distance threshold (75.0) is an initial estimate
needing hall validation, exactly like the phone-detection confidence threshold
— this is a coarse single-reference-photo comparison, not proof of identity.
No frame is ever saved; only the enrolled photo (already bundled with the app)
and the momentary comparison result exist.

## Voice-activity check ("elevated talking near this seat")

An optional microphone thread (`sounddevice`) classifies ~30ms blocks of audio
as above/below an amplitude threshold and immediately discards each block —
**no audio is ever recorded, stored, buffered beyond the rolling classification
window, or transcribed.** This is an amplitude heuristic, not speech
recognition: it has no way to know what was said, by whom, or whether it was
exam-related. When the speech-like ratio over a rolling 5-second window stays
elevated (default >= 55%, gated by `TalkGate` with the same
require-sustained/rate-limit shape as `DetectionGate`), it emits a `talking`
flag meaning "an officer should check this seat", never a claim of what was
said or that collusion occurred. If no microphone is available the worker
degrades gracefully — phone/identity detection are unaffected — and reports
`audio_unavailable`. Disable explicitly with `--no-audio`.

## Set up this workstation

Install Python 3.12, then run from the repo root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File backend/object_detection/setup.ps1
$env:ABU_DETECTOR_DIR = (Resolve-Path backend/object_detection).Path
flutter run -d windows
```

For an already built app, activate the workspace runtime persistently:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File backend/object_detection/activate.ps1
```

Use `-AppDirectory <folder>` for another Windows build. This writes a local
`data/object_detection/runtime.json` containing this workstation's runtime paths.
Environment variables take precedence. The local configuration is not shipped
to other workstations by CMake. Restart the app after activation.

For a supervised hardware test with the production exam controller and UI:

```powershell
flutter run -d windows -t tool/object_detection_live.dart
```

The test starts when its button is pressed and stops automatically after
three minutes. For an explicitly supervised automatic run, add
`--dart-define=DETECTOR_AUTOSTART=true`. It logs camera status and the Rust officer-feed responses.
It uses a clearly labelled test exam, without modifying production login routes.
After testing, rebuild/run the normal app with `-t lib/main.dart`.

Setup creates an isolated CPU Python environment, downloads the official YOLO11n
weights, and verifies inference on a synthetic image without opening the camera.
Downloads are setup-only. The exam worker requires a local model and disables
automatic dependency installation. Model binaries and the virtual environment
are excluded from Git. Python/model startup does not block the exam timer.

Windows builds bundle worker code, setup instructions and available weights in
`data/object_detection`. On a deployed workstation run its `setup.ps1` once to
create the runtime beside the worker. Alternatively provision a managed runtime
and set `ABU_DETECTOR_PYTHON` to its absolute python.exe path. `ABU_DETECTOR_DIR`
overrides the worker/model directory; `ABU_CAMERA_INDEX` selects the camera (0 by
default). Camera permission must be enabled for desktop apps. Browser/mobile
clients report monitoring unavailable.

Missing runtime/model, camera failure, worker exit, or stalled inference produce
an explicit coverage warning. Flutter stops the process at expiry, submission or
exam exit; stdin closure stops an orphaned worker. Flags are retried by periodic
heartbeats while the exam is active. Existing server storage is in-memory;
shared preferences are not a tamper-proof archive or acknowledged upload queue.

## Validation

```powershell
python -m unittest discover -s backend/object_detection -p 'test_*.py'
flutter test test/usb_monitor_flow_test.dart test/practice_flow_test.dart
```

Hardware acceptance: start an exam, confirm `Camera: Active`, show a phone for
two samples, and check the candidate/seat/time flag in invigilator risk details.
Remove it; check no continuing flags. Test camera disconnect and exam termination.
Validate thresholds across lighting, desks, calculators and other lookalike
objects before operational use. Do not interpret confidence as proof of misconduct.

Identity check: run a short exam with `--reference-photo` pointed at a known
candidate photo, have a different person sit in for one of the three scheduled
snapshots, and confirm a mismatch flag with a reasonable distance value appears
in risk details — then repeat with the correct candidate and confirm no flag.

Voice-activity check: start an exam with a microphone connected, talk
continuously near the seat for several seconds, and confirm a `talking` flag
appears with no continuing flags for at least the cooldown window afterward.
Disconnect the microphone and confirm phone/identity detection continue
unaffected with an `audio_unavailable` status. Confirm no audio file or buffer
is ever written to disk during any of this.

References: [YOLO11](https://docs.ultralytics.com/models/yolo11/),
[prediction API](https://docs.ultralytics.com/modes/predict/),
[OpenCV camera capture](https://opencv.org/reading-and-writing-videos-using-opencv/).
The Ultralytics dependency/model is distributed under its upstream license;
see the installed package and model supplier's licensing terms.
