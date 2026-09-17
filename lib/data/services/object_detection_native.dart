import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Fired when the local detector flags something worth structured evidence
/// (not every plain-text flag needs one). `confidence` is null for evidence
/// types without a natural numeric score.
typedef EvidenceCallback =
    void Function({
      required String evidenceType,
      double? confidence,
      required String details,
      required DateTime capturedAt,
    });

class ObjectDetectionService {
  Process? _process;
  Timer? _watchdog;
  bool _active = false;
  int _generation = 0;
  DateTime _lastMessage = DateTime.now();
  bool _ready = false;

  // Mutable so a later caller (the exam screen re-attaching to monitoring
  // that was already started at login) can redirect where flags/status/
  // popups go without tearing down and re-opening the camera.
  void Function(String) _onFlag = (_) {};
  void Function(String)? _onStatus;
  EvidenceCallback? _onEvidence;

  /// Starts local detection, or — if it's already running (typically because
  /// [start] was already called once at login) — just re-targets the given
  /// callbacks onto the running process instead of restarting it. This lets
  /// monitoring begin the moment a candidate logs in and keep running
  /// uninterrupted as they move from the portal into an exam, while each
  /// screen still gets its own flag/audit handling.
  Future<void> start(
    void Function(String) onFlag, {
    void Function(String)? onStatus,
    EvidenceCallback? onEvidence,
    String? referencePhotoPath,
    int? durationSeconds,
  }) async {
    _onFlag = onFlag;
    _onStatus = onStatus;
    _onEvidence = onEvidence;
    if (_active) {
      onStatus?.call(_ready ? 'Active' : 'Starting');
      return;
    }
    _active = true;
    final generation = ++_generation;
    void fail(String message) {
      if (!_active || generation != _generation) return;
      _onStatus?.call('Unavailable');
      _onFlag('Object detection unavailable: $message');
      unawaited(stop());
    }

    _onStatus?.call('Starting');
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
          // Sample every second (the fastest the worker allows) instead of
          // the 3s default, so a phone in view is caught and flagged almost
          // immediately rather than after several seconds of visible delay.
          '--interval',
          '1',
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
            _onStatus?.call('Active');
          } else if (event['kind'] == 'phone') {
            // The worker's own DetectionGate already applies the
            // alert-worthy confidence threshold before ever emitting a
            // "phone" event — duplicating that number here just risks the
            // two drifting apart (as they did: this used to hardcode 0.65
            // independently of the worker's own threshold).
            final confidence = (event['confidence'] as num).toDouble();
            final timestamp = DateTime.parse(
              event['capturedAtIso'] as String,
            ).toUtc();
            _onFlag(
              'Possible phone detected at ${timestamp.toIso8601String()} '
              '(${(confidence * 100).round()}% model confidence). Officer review required.',
            );
            _onEvidence?.call(
              evidenceType: 'phone',
              confidence: confidence,
              details: 'Possible phone in view.',
              capturedAt: timestamp,
            );
          } else if (event['kind'] == 'identity') {
            final match = event['match'] == true;
            if (match) return; // Only anomalies are worth flagging.
            final distance = (event['distance'] as num?)?.toDouble();
            final timestamp = DateTime.tryParse(
              (event['capturedAtIso'] ?? '').toString(),
            )?.toUtc();
            _onFlag(
              'Identity snapshot did not match the enrolled photo'
              '${timestamp != null ? ' at ${timestamp.toIso8601String()}' : ''}'
              '${distance != null ? ' (distance ${distance.toStringAsFixed(1)})' : ''}. '
              'Officer review required — possible impersonation.',
            );
            _onEvidence?.call(
              evidenceType: 'identity',
              details: distance != null
                  ? 'Identity snapshot did not match the enrolled photo '
                        '(distance ${distance.toStringAsFixed(1)}).'
                  : 'Identity snapshot did not match the enrolled photo.',
              capturedAt: timestamp ?? DateTime.now().toUtc(),
            );
          } else if (event['kind'] == 'talking') {
            final ratio = (event['speechRatio'] as num?)?.toDouble();
            final timestamp = DateTime.tryParse(
              (event['capturedAtIso'] ?? '').toString(),
            )?.toUtc();
            _onFlag(
              'Elevated talking detected near this seat'
              '${timestamp != null ? ' at ${timestamp.toIso8601String()}' : ''}'
              '${ratio != null ? ' (${(ratio * 100).round()}% of recent audio)' : ''}. '
              'No audio was recorded or transcribed — officer should check in person.',
            );
            _onEvidence?.call(
              evidenceType: 'talking',
              confidence: ratio,
              details: 'Elevated talking near this seat. No audio was '
                  'recorded or transcribed.',
              capturedAt: timestamp ?? DateTime.now().toUtc(),
            );
          } else if (event['kind'] == 'status') {
            final status = (event['status'] ?? '').toString();
            if (status == 'audio_unavailable') {
              _onStatus?.call('Camera active, microphone unavailable');
            } else if (status == 'identity_reference_invalid') {
              _onStatus?.call('Camera active, identity checks disabled');
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

  /// Detaches the caller's callbacks without stopping the underlying
  /// process — used when a screen (e.g. the exam view) is done with
  /// monitoring but the session-level detector (started at login) should
  /// keep running for the rest of the candidate's time at this workstation.
  void detach() {
    _onFlag = (_) {};
    _onStatus = null;
    _onEvidence = null;
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
