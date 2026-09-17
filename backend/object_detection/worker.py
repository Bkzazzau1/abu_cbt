"""Local exam-integrity worker. JSON lines to Flutter; frames/audio never
leave memory and are never written to disk or transmitted anywhere.

Three independent signals, each optional and independently degradable:
  1. Phone detection (YOLO11n on the camera) — unchanged from the original
     worker.
  2. Identity snapshot check — a handful of random-interval camera frames
     compared against the candidate's enrolled photo, to catch someone
     other than the enrolled candidate sitting the exam.
  3. Voice-activity ("elevated talking") — a coarse microphone energy
     heuristic. It does NOT record, store, or transcribe audio; it only
     classifies short (~30ms) blocks as "sound above threshold" or not, in
     memory, discarded immediately after classification. It cannot tell
     what was said, only that sustained sound was present near this seat.
"""
from __future__ import annotations

import argparse
import collections
import contextlib
from datetime import datetime, timedelta, timezone
import json
import math
import os
from pathlib import Path
import random
import sys
import threading
import time


class DetectionGate:
    """Require two consecutive samples; rate-limit continuing detections."""

    def __init__(self, threshold=0.65, cooldown=30.0):
        self.threshold = threshold
        self.cooldown = cooldown
        self.hits = 0
        self.last_alert = -math.inf

    def update(self, confidence, now):
        valid = math.isfinite(confidence) and self.threshold <= confidence <= 1
        self.hits = min(2, self.hits + 1) if valid else 0
        if self.hits >= 2 and now - self.last_alert >= self.cooldown:
            self.last_alert = now
            return True
        return False


class LatestFrame:
    """One camera frame in memory; continuously drain stale camera buffers."""

    def __init__(self, capture, stop):
        self.capture, self.stop = capture, stop
        self.lock = threading.Lock()
        self.frame = None
        self.captured_at = 0.0
        self.failed = False

    def run(self):
        failures = 0
        try:
            while not self.stop.is_set():
                ok, frame = self.capture.read()
                if not ok:
                    failures += 1
                    if failures >= 10:
                        self.failed = True
                        return
                    self.stop.wait(0.1)
                    continue
                failures = 0
                with self.lock:
                    self.frame, self.captured_at = frame, time.monotonic()
        finally:
            self.capture.release()

    def latest(self):
        with self.lock:
            return self.frame, self.captured_at


class IdentitySchedule:
    """Picks a handful of random check times within the exam window and
    hands them out once each as elapsed time crosses them. Pure logic —
    no camera or model access, so it's directly unit-testable.

    Checks are kept away from the very start/end of the exam (nothing
    useful to compare right as the candidate sits down or while they're
    mid-submission) and spaced apart so they don't cluster together.
    """

    def __init__(self, duration_seconds, count=3, rng=None):
        rng = rng or random.Random()
        duration = max(60.0, float(duration_seconds))
        lo, hi = duration * 0.1, duration * 0.9
        span = max(0.0, hi - lo)
        min_gap = span / (count * 2) if count else 0.0
        offsets = []
        attempts = 0
        while len(offsets) < count and attempts < count * 50:
            attempts += 1
            candidate = lo + rng.random() * span
            if all(abs(candidate - existing) >= min_gap for existing in offsets):
                offsets.append(candidate)
        # Fall back to evenly-spaced offsets if random spacing couldn't
        # satisfy the minimum gap (only possible for a very short exam).
        if len(offsets) < count and count > 0:
            offsets = [lo + span * (i + 0.5) / count for i in range(count)]
        self._due = sorted(offsets)

    def poll(self, elapsed_seconds):
        """Returns True once per scheduled offset as it's crossed."""
        if self._due and elapsed_seconds >= self._due[0]:
            self._due.pop(0)
            return True
        return False

    @property
    def remaining(self):
        return len(self._due)


class TalkGate:
    """Cooldown gate for sustained voice-activity, mirroring DetectionGate's
    shape: a burst of "someone coughed near the mic" shouldn't alert, but
    a sustained elevated ratio should — and continuing detections should
    be rate-limited the same way phone detections are."""

    def __init__(self, ratio_threshold=0.55, min_coverage=0.8, cooldown=45.0):
        self.ratio_threshold = ratio_threshold
        self.min_coverage = min_coverage
        self.cooldown = cooldown
        self.last_alert = -math.inf

    def update(self, ratio, coverage, now):
        if coverage < self.min_coverage:
            return False
        if ratio >= self.ratio_threshold and now - self.last_alert >= self.cooldown:
            self.last_alert = now
            return True
        return False


class VoiceActivity:
    """Rolling estimate of speech-like sound presence from microphone
    energy. Each ~30ms block is classified as "above threshold" or not and
    immediately discarded — no audio sample is ever retained, written to
    disk, or sent anywhere. This is an amplitude heuristic, not speech
    recognition: it has no way to know what was said, by whom, or whether
    it was exam-related at all. Treat it as "check this seat", not proof.
    """

    def __init__(self, stop, window_seconds=5.0, sample_rate=16000, threshold=0.02):
        self.stop = stop
        self.sample_rate = sample_rate
        self.threshold = threshold
        self.block_size = 480  # ~30ms at 16kHz
        window_blocks = max(1, int(window_seconds * sample_rate / self.block_size))
        self.lock = threading.Lock()
        self.recent = collections.deque(maxlen=window_blocks)
        self.window_blocks = window_blocks
        self.failed = False
        self.available = True

    def _callback(self, indata, frames, time_info, status):  # noqa: ARG002
        import numpy as np

        level = float(np.abs(indata).mean())
        with self.lock:
            self.recent.append(level >= self.threshold)

    def run(self):
        try:
            import sounddevice as sd
        except Exception:
            self.available = False
            return
        try:
            with sd.InputStream(
                channels=1,
                samplerate=self.sample_rate,
                blocksize=self.block_size,
                callback=self._callback,
            ):
                while not self.stop.is_set():
                    self.stop.wait(0.2)
        except Exception:
            self.failed = True

    def ratio_and_coverage(self):
        with self.lock:
            filled = len(self.recent)
            coverage = filled / self.window_blocks
            ratio = (sum(self.recent) / filled) if filled else 0.0
        return ratio, coverage


def load_reference_face(path, cascade):
    """Detects the largest face in a reference photo and returns it as a
    normalized grayscale crop, or None if no face could be found."""
    import cv2

    image = cv2.imread(str(path), cv2.IMREAD_GRAYSCALE)
    if image is None:
        return None
    faces = cascade.detectMultiScale(
        image, scaleFactor=1.1, minNeighbors=5, minSize=(80, 80)
    )
    if len(faces) == 0:
        return None
    x, y, w, h = max(faces, key=lambda f: f[2] * f[3])
    return cv2.resize(image[y : y + h, x : x + w], (200, 200))


def run(args, emit, stop, start_stdin_watcher):
    # Never ask the inference library to resolve/download a missing model.
    model_path = Path(args.model).resolve()
    if not model_path.is_file():
        raise RuntimeError("Local model missing. Run object-detection setup first.")
    os.environ["YOLO_OFFLINE"] = "true"
    os.environ["YOLO_AUTOINSTALL"] = "false"
    os.environ.setdefault("YOLO_CONFIG_DIR", str(model_path.parent.parent / ".config"))
    Path(os.environ["YOLO_CONFIG_DIR"]).mkdir(parents=True, exist_ok=True)
    import cv2
    from ultralytics import YOLO
    from ultralytics.utils import SETTINGS

    SETTINGS.update({"sync": False})

    model = YOLO(str(model_path), task="detect")
    phone_ids = [key for key, value in model.names.items() if value == "cell phone"]
    if len(phone_ids) != 1:
        raise RuntimeError("Model must contain the COCO 'cell phone' class.")
    if args.check:
        import numpy as np
        model.predict(np.zeros((480, 640, 3), dtype=np.uint8), device="cpu",
                      classes=phone_ids, imgsz=640, verbose=False, save=False)
        emit({"kind": "checked", "model": model_path.name})
        return

    # Starting this thread earlier (e.g. before the torch/ultralytics imports
    # above) reliably wedges those libraries' native thread-pool init on
    # Windows — the process never crashes or errors, it just never emits
    # another line. Only start it once the heavy native imports are done.
    start_stdin_watcher()

    # --- Identity snapshot check (optional; needs a reference photo). ---
    face_cascade = None
    recognizer = None
    identity_schedule = None
    if args.reference_photo:
        face_cascade = cv2.CascadeClassifier(
            cv2.data.haarcascades + "haarcascade_frontalface_default.xml"
        )
        reference_face = load_reference_face(args.reference_photo, face_cascade)
        if reference_face is None:
            emit({"kind": "status", "status": "identity_reference_invalid"})
        else:
            import numpy as np

            recognizer = cv2.face.LBPHFaceRecognizer_create()
            recognizer.train([reference_face], np.array([0]))
            identity_schedule = IdentitySchedule(args.duration_seconds)

    # --- Voice-activity check (optional; needs a working microphone). ---
    voice = None
    talk_gate = None
    audio_thread = None
    if args.enable_audio:
        voice = VoiceActivity(stop)
        audio_thread = threading.Thread(target=voice.run, daemon=True)
        audio_thread.start()
        talk_gate = TalkGate()

    if stop.is_set():
        return
    capture = cv2.VideoCapture(args.camera, cv2.CAP_DSHOW) if sys.platform == "win32" else cv2.VideoCapture(args.camera)
    if not capture.isOpened():
        capture.release()
        raise RuntimeError("Camera unavailable or permission denied.")
    capture.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
    capture.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
    frames = LatestFrame(capture, stop)
    camera_thread = threading.Thread(target=frames.run, daemon=True)
    camera_thread.start()
    gate = DetectionGate()
    last_sample = 0.0
    started = time.monotonic()
    audio_warned = False
    try:
        while not stop.is_set():
            frame, captured_at = frames.latest()
            if frames.failed or (time.monotonic() - max(captured_at, started) > 10):
                raise RuntimeError("Camera stopped supplying fresh frames.")
            if frame is None or captured_at <= last_sample:
                stop.wait(0.1)
                continue
            last_sample = captured_at
            frame_time = datetime.now(timezone.utc) - timedelta(
                seconds=max(0, time.monotonic() - captured_at))
            results = model.predict(frame, device="cpu", classes=phone_ids,
                                    conf=0.65, imgsz=640, verbose=False, save=False)
            boxes = results[0].boxes
            confidence = max((float(value) for value in boxes.conf), default=0.0)
            emit({"kind": "status", "status": "active"})
            if gate.update(confidence, time.monotonic()) and not stop.is_set():
                emit({"kind": "phone", "confidence": round(confidence, 4),
                      "capturedAtIso": frame_time.isoformat(),
                      "model": model_path.name})

            if identity_schedule is not None and identity_schedule.poll(
                time.monotonic() - started
            ):
                gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
                faces = face_cascade.detectMultiScale(
                    gray, scaleFactor=1.1, minNeighbors=5, minSize=(80, 80)
                )
                if len(faces) == 0:
                    emit({"kind": "status", "status": "identity_check_no_face"})
                else:
                    x, y, w, h = max(faces, key=lambda f: f[2] * f[3])
                    crop = cv2.resize(gray[y : y + h, x : x + w], (200, 200))
                    _, distance = recognizer.predict(crop)
                    # LBPH distance: lower means more similar. This threshold
                    # is an initial estimate, not a calibrated accuracy claim
                    # — validate it against real hall lighting/cameras before
                    # relying on it, same as the phone-detection thresholds.
                    match = distance <= 75.0
                    emit({
                        "kind": "identity",
                        "match": match,
                        "distance": round(float(distance), 2),
                        "capturedAtIso": frame_time.isoformat(),
                    })

            if voice is not None:
                if voice.failed and not audio_warned:
                    audio_warned = True
                    emit({"kind": "status", "status": "audio_unavailable"})
                elif not voice.available and not audio_warned:
                    audio_warned = True
                    emit({"kind": "status", "status": "audio_unavailable"})
                elif not voice.failed and voice.available:
                    ratio, coverage = voice.ratio_and_coverage()
                    if talk_gate.update(ratio, coverage, time.monotonic()):
                        emit({
                            "kind": "talking",
                            "speechRatio": round(ratio, 2),
                            "capturedAtIso": frame_time.isoformat(),
                        })

            # Only sample inference periodically, independent of camera frame rate.
            stop.wait(args.interval)
    finally:
        stop.set()
        camera_thread.join(timeout=2)
        if audio_thread is not None:
            audio_thread.join(timeout=2)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", required=True)
    parser.add_argument("--camera", type=int, default=0)
    parser.add_argument("--interval", type=float, default=3.0)
    parser.add_argument("--check", action="store_true", help="Load model and run synthetic inference without camera")
    parser.add_argument("--reference-photo", default=None,
                         help="Path to the candidate's enrolled photo, for periodic identity snapshot checks")
    parser.add_argument("--duration-seconds", type=float, default=3600.0,
                         help="Exam duration, used to schedule identity checks away from start/end")
    parser.add_argument("--enable-audio", dest="enable_audio", action="store_true", default=True)
    parser.add_argument("--no-audio", dest="enable_audio", action="store_false")
    args = parser.parse_args()
    if not math.isfinite(args.interval) or not 1 <= args.interval <= 10:
        parser.error("interval must be between 1 and 10 seconds")
    output = sys.stdout
    def emit(event):
        output.write(json.dumps(event, allow_nan=False) + "\n")
        output.flush()
    stop = threading.Event()
    def parent_commands():
        # EOF means the Flutter parent exited. No orphaned camera capture.
        for line in sys.stdin:
            if line.strip() == "stop":
                break
        stop.set()
    def start_stdin_watcher():
        threading.Thread(target=parent_commands, daemon=True).start()
    try:
        # Library diagnostics must never corrupt the JSON protocol on stdout.
        with contextlib.redirect_stdout(sys.stderr):
            run(args, emit, stop, start_stdin_watcher)
        return 0
    except Exception as error:
        emit({"kind": "error", "message": str(error)[:300]})
        return 1
    finally:
        stop.set()


if __name__ == "__main__":
    raise SystemExit(main())
