import argparse
import json
from pathlib import Path
import random
import subprocess
import sys
import tempfile
import threading
import unittest

from worker import DetectionGate, IdentitySchedule, LatestFrame, TalkGate, run


class DetectionTests(unittest.TestCase):
    def test_requires_consecutive_hits_and_applies_cooldown(self):
        gate = DetectionGate()
        self.assertFalse(gate.update(0.9, 0))
        self.assertFalse(gate.update(0.4, 3))
        self.assertFalse(gate.update(0.9, 6))
        self.assertTrue(gate.update(0.9, 9))
        self.assertFalse(gate.update(0.9, 12))
        self.assertTrue(gate.update(0.9, 39))

    def test_low_confidence_and_non_finite_values_never_flag(self):
        for confidence in [0, 0.49, float('nan'), float('inf'), 1.1]:
            gate = DetectionGate()
            self.assertFalse(gate.update(confidence, 0))
            self.assertFalse(gate.update(confidence, 100))

    def test_camera_memory_is_bounded_and_released(self):
        stop = threading.Event()
        class Camera:
            count = 0
            released = False
            def read(self):
                self.count += 1
                if self.count == 10:
                    stop.set()
                return True, self.count
            def release(self):
                self.released = True
        camera = Camera()
        frames = LatestFrame(camera, stop)
        frames.run()
        self.assertEqual(frames.latest()[0], 10)
        self.assertTrue(camera.released)

    def test_missing_model_fails_without_loading_camera_libraries(self):
        with tempfile.TemporaryDirectory() as directory:
            args = argparse.Namespace(model=str(Path(directory) / 'missing.pt'))
            with self.assertRaisesRegex(RuntimeError, 'Local model missing'):
                run(args, lambda _: None, threading.Event(), lambda: None)

    def test_identity_schedule_picks_offsets_within_middle_of_exam(self):
        schedule = IdentitySchedule(3600, count=3, rng=random.Random(1))
        self.assertEqual(schedule.remaining, 3)
        for offset in schedule._due:  # noqa: SLF001 (whitebox on purpose)
            self.assertGreaterEqual(offset, 360)  # 10% of 3600
            self.assertLessEqual(offset, 3240)  # 90% of 3600

    def test_identity_schedule_offsets_are_spaced_apart(self):
        schedule = IdentitySchedule(3600, count=3, rng=random.Random(7))
        offsets = sorted(schedule._due)  # noqa: SLF001
        gaps = [b - a for a, b in zip(offsets, offsets[1:])]
        self.assertTrue(all(gap > 0 for gap in gaps))

    def test_identity_schedule_poll_consumes_each_offset_once(self):
        schedule = IdentitySchedule(300, count=3, rng=random.Random(2))
        due = sorted(schedule._due)  # noqa: SLF001
        self.assertFalse(schedule.poll(due[0] - 1))
        self.assertTrue(schedule.poll(due[0]))
        self.assertEqual(schedule.remaining, 2)
        # Polling again at the same elapsed time should not double-fire.
        self.assertFalse(schedule.poll(due[0]))

    def test_identity_schedule_falls_back_to_even_spacing_for_short_exam(self):
        # A very short window can make random spacing infeasible; the
        # schedule must still produce `count` usable offsets.
        schedule = IdentitySchedule(65, count=3, rng=random.Random(3))
        self.assertEqual(schedule.remaining, 3)

    def test_talk_gate_ignores_low_coverage_and_low_ratio(self):
        gate = TalkGate()
        self.assertFalse(gate.update(ratio=0.9, coverage=0.1, now=0))
        self.assertFalse(gate.update(ratio=0.1, coverage=1.0, now=0))

    def test_talk_gate_fires_once_then_cools_down(self):
        gate = TalkGate(cooldown=45.0)
        self.assertTrue(gate.update(ratio=0.8, coverage=1.0, now=0))
        self.assertFalse(gate.update(ratio=0.8, coverage=1.0, now=10))
        self.assertTrue(gate.update(ratio=0.8, coverage=1.0, now=46))

    def test_error_protocol_is_json_and_process_exits(self):
        result = subprocess.run(
            [sys.executable, str(Path(__file__).with_name('worker.py')),
             '--model', 'missing-model-for-test.pt', '--check'],
            capture_output=True, text=True, timeout=5,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(json.loads(result.stdout)['kind'], 'error')


if __name__ == '__main__':
    unittest.main()
