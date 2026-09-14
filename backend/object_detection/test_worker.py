import argparse
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import threading
import unittest

from worker import DetectionGate, LatestFrame, run


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
        for confidence in [0, 0.64, float('nan'), float('inf'), 1.1]:
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
                run(args, lambda _: None, threading.Event())

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
