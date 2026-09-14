import 'dart:async';
import 'dart:convert';
import 'dart:io';

class ObjectDetectionService {
  Process? _process;
  Timer? _watchdog;
  bool _active = false;
  int _generation = 0;
  DateTime _lastMessage = DateTime.now();
  bool _ready = false;

  Future<void> start(
    void Function(String) onFlag, {
    void Function(String)? onStatus,
    String? referencePhotoPath,
    int? durationSeconds,
  }) async {
    if (_active) return;
    _active = true;
    final generation = ++_generation;
    void fail(String message) {
      if (!_active || generation != _generation) return;
      onStatus?.call('Unavailable');
      onFlag('Object detection unavailable: $message');
      unawaited(stop());
    }

    onStatus?.call('Starting');
    if (!Platform.isWindows) {
      fail('requires the Windows desktop app.');
      return;
    }
    try {
      final appDirectory = File(Platform.resolvedExecutable).parent.path;
      final configFile = File(
        '$appDirectory/data/object_detection/runtime.json',
      );
      final config = configFile.existsSync()
          ? jsonDecode(await configFile.readAsString()) as Map<String, dynamic>
          : <String, dynamic>{};
      final directory =
          Platform.environment['ABU_DETECTOR_DIR'] ??
          config['detectorDirectory'] as String? ??
          '$appDirectory/data/object_detection';
      final python =
          Platform.environment['ABU_DETECTOR_PYTHON'] ??
          config['pythonExecutable'] as String? ??
          '$directory/.venv/Scripts/python.exe';
      final model = '$directory/models/yolo11n.pt';
      if (!File(python).existsSync() ||
          !File(model).existsSync() ||
          !File('$directory/worker.py').existsSync()) {
        fail('run the local object-detection setup.');
        return;
      }
      final process = await Process.start(
        python,
        [
          '-u',
          '$directory/worker.py',
          '--model',
          model,
          '--camera',
          Platform.environment['ABU_CAMERA_INDEX'] ?? '0',
          if (referencePhotoPath != null && referencePhotoPath.isNotEmpty) ...[
            '--reference-photo',
            referencePhotoPath,
          ],
          if (durationSeconds != null && durationSeconds > 0) ...[
            '--duration-seconds',
            '$durationSeconds',
          ],
        ],
        environment: {'YOLO_OFFLINE': 'true', 'YOLO_AUTOINSTALL': 'false'},
      );
      if (!_active || generation != _generation) {
        process.kill();
        return;
      }
      _process = process;
      _lastMessage = DateTime.now();
      _ready = false;
      unawaited(process.stderr.drain<void>().catchError((Object _) {}));
      process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((
        line,
      ) {
        if (!_active || generation != _generation) return;
        try {
          final event = jsonDecode(line) as Map<String, dynamic>;
          if (event['kind'] == 'error') {
            fail((event['message'] ?? 'camera or model failure').toString());
          } else if (event['kind'] == 'status' && event['status'] == 'active') {
            _ready = true;
            _lastMessage = DateTime.now();
            onStatus?.call('Active');
          } else if (event['kind'] == 'phone') {
            final confidence = (event['confidence'] as num).toDouble();
            final timestamp = DateTime.parse(
              event['capturedAtIso'] as String,
            ).toUtc();
            if (!confidence.isFinite || confidence < 0.65 || confidence > 1) {
              return;
            }
            onFlag(
              'Possible phone detected at ${timestamp.toIso8601String()} '
              '(${(confidence * 100).round()}% model confidence). Officer review required.',
            );
          } else if (event['kind'] == 'identity') {
            final match = event['match'] == true;
            if (match) return; // Only anomalies are worth flagging.
            final distance = (event['distance'] as num?)?.toDouble();
            final timestamp = DateTime.tryParse(
              (event['capturedAtIso'] ?? '').toString(),
            )?.toUtc();
            onFlag(
              'Identity snapshot did not match the enrolled photo'
              '${timestamp != null ? ' at ${timestamp.toIso8601String()}' : ''}'
              '${distance != null ? ' (distance ${distance.toStringAsFixed(1)})' : ''}. '
              'Officer review required — possible impersonation.',
            );
          } else if (event['kind'] == 'talking') {
            final ratio = (event['speechRatio'] as num?)?.toDouble();
            final timestamp = DateTime.tryParse(
              (event['capturedAtIso'] ?? '').toString(),
            )?.toUtc();
            onFlag(
              'Elevated talking detected near this seat'
              '${timestamp != null ? ' at ${timestamp.toIso8601String()}' : ''}'
              '${ratio != null ? ' (${(ratio * 100).round()}% of recent audio)' : ''}. '
              'No audio was recorded or transcribed — officer should check in person.',
            );
          } else if (event['kind'] == 'status') {
            final status = (event['status'] ?? '').toString();
            if (status == 'audio_unavailable') {
              onStatus?.call('Camera active, microphone unavailable');
            } else if (status == 'identity_reference_invalid') {
              onStatus?.call('Camera active, identity checks disabled');
            }
          }
        } catch (_) {
          fail('invalid response from the local detector.');
        }
      }, onError: (_) => fail('local detector connection failed.'));
      unawaited(
        process.exitCode.then(
          (_) => fail('local detector stopped unexpectedly.'),
        ),
      );
      _watchdog = Timer.periodic(const Duration(seconds: 5), (_) {
        if (DateTime.now().difference(_lastMessage).inSeconds >
            (_ready ? 20 : 90)) {
          fail('camera or inference process stopped responding.');
        }
      });
    } catch (_) {
      fail('could not start the local Python runtime.');
    }
  }

  Future<void> stop() async {
    _active = false;
    ++_generation;
    _watchdog?.cancel();
    _watchdog = null;
    final process = _process;
    _process = null;
    if (process == null) return;
    try {
      process.stdin.writeln('stop');
      await process.stdin.flush().timeout(const Duration(seconds: 1));
      await process.exitCode.timeout(const Duration(seconds: 3));
    } catch (_) {
      process.kill();
      await process.exitCode;
    } finally {
      await process.stdin.close().catchError((Object _) {});
    }
  }
}
