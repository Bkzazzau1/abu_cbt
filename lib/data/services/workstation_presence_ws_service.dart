import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/workstation_presence_models.dart';

class WorkstationPresenceWsService extends GetxService {
  final isConnected = false.obs;
  final _incoming = StreamController<WorkstationPresenceEnvelope>.broadcast();
  Stream<WorkstationPresenceEnvelope> get incoming => _incoming.stream;

  WebSocketChannel? _channel;
  Uri? _connectedUri;
  StreamSubscription<dynamic>? _subscription;

  Future<void> connectInvigilator({required String centerName}) async {
    final endpoint = _buildUri(
      path: '/ws/invigilator',
      query: <String, String>{'centerName': centerName.trim()},
    );
    await _connect(endpoint);
  }

  Future<void> connectWorkstation() async {
    final endpoint = _buildUri(path: '/ws/workstation');
    await _connect(endpoint);
  }

  void sendHeartbeat(WorkstationPresenceRecord payload) {
    if (_channel == null) return;
    final envelope = <String, dynamic>{
      'kind': 'heartbeat',
      'payload': payload.toJson(),
    };
    _channel!.sink.add(jsonEncode(envelope));
  }

  /// Sent by the invigilator app when a candidate is physically checked in,
  /// so the backend can flag a candidate later submitting from a different
  /// workstation/hall/seat than where they checked in.
  void sendCheckIn({
    required String registrationNumber,
    required String candidateName,
    required String hallName,
    required String seatNumber,
  }) {
    if (_channel == null) return;
    final envelope = <String, dynamic>{
      'kind': 'checkIn',
      'payload': {
        'registrationNumber': registrationNumber,
        'candidateName': candidateName,
        'hallName': hallName,
        'seatNumber': seatNumber,
        'checkedInAtIso': DateTime.now().toIso8601String(),
      },
    };
    _channel!.sink.add(jsonEncode(envelope));
  }

  /// Sent by a candidate's exam workstation at submission time for each
  /// free-text answer, so the backend can run AI answer-similarity checks
  /// against the rest of the hall and flag likely collusion.
  void sendAnswerSubmission({
    required String registrationNumber,
    required String candidateName,
    required String hallName,
    required String seatNumber,
    required String examId,
    required String questionId,
    required String textAnswer,
  }) {
    if (_channel == null) return;
    final envelope = <String, dynamic>{
      'kind': 'answerSubmission',
      'payload': {
        'registrationNumber': registrationNumber,
        'candidateName': candidateName,
        'hallName': hallName,
        'seatNumber': seatNumber,
        'examId': examId,
        'questionId': questionId,
        'textAnswer': textAnswer,
      },
    };
    _channel!.sink.add(jsonEncode(envelope));
  }

  /// Sent by a candidate's exam workstation the moment the local detector
  /// flags something (phone, identity mismatch, elevated talking, an
  /// unauthorized USB device — see [EvidenceType]), so it shows up as
  /// evidence on the invigilator dashboard immediately rather than waiting
  /// for the next heartbeat/submission.
  void sendEvidenceEvent({
    required String workstationId,
    required String centerName,
    required String hallName,
    required String seatNumber,
    required String registrationNumber,
    required String candidateName,
    required String examTitle,
    required String evidenceType,
    double? confidence,
    String details = '',
    required String detectedAtIso,
  }) {
    if (_channel == null) return;
    final envelope = <String, dynamic>{
      'kind': 'evidenceDetected',
      'payload': {
        'workstationId': workstationId,
        'centerName': centerName,
        'hallName': hallName,
        'seatNumber': seatNumber,
        'registrationNumber': registrationNumber,
        'candidateName': candidateName,
        'examTitle': examTitle,
        'evidenceType': evidenceType,
        'confidence': confidence,
        'details': details,
        'detectedAtIso': detectedAtIso,
      },
    };
    _channel!.sink.add(jsonEncode(envelope));
  }

  /// Sent by the invigilator app to force one specific candidate's exam to
  /// end immediately. Delivered only if that workstation is currently
  /// connected — there is no queued/offline delivery.
  void sendTerminateExam({
    required String workstationId,
    required String reason,
    required String issuedBy,
  }) {
    if (_channel == null) return;
    final envelope = <String, dynamic>{
      'kind': 'terminateExam',
      'workstationId': workstationId,
      'reason': reason,
      'issuedBy': issuedBy,
      'issuedAtIso': DateTime.now().toIso8601String(),
    };
    _channel!.sink.add(jsonEncode(envelope));
  }

  /// Sent by the invigilator app to hand an evidence event to the exam
  /// officer for review.
  void sendEscalateEvidenceEvent({
    required String eventId,
    required String escalatedBy,
  }) {
    if (_channel == null) return;
    final envelope = <String, dynamic>{
      'kind': 'escalateEvidenceEvent',
      'eventId': eventId,
      'escalatedBy': escalatedBy,
      'escalatedAtIso': DateTime.now().toIso8601String(),
    };
    _channel!.sink.add(jsonEncode(envelope));
  }

  /// Sent by the invigilator app to file a formal malpractice report.
  void sendMalpracticeReport(Map<String, dynamic> payload) {
    if (_channel == null) return;
    final envelope = <String, dynamic>{
      'kind': 'submitMalpracticeReport',
      'payload': payload,
    };
    _channel!.sink.add(jsonEncode(envelope));
  }

  /// Sent by the invigilator app to hand a filed malpractice report to the
  /// exam officer for review.
  void sendEscalateMalpracticeReport({
    required String reportId,
    required String escalatedBy,
  }) {
    if (_channel == null) return;
    final envelope = <String, dynamic>{
      'kind': 'escalateMalpracticeReport',
      'reportId': reportId,
      'escalatedBy': escalatedBy,
      'escalatedAtIso': DateTime.now().toIso8601String(),
    };
    _channel!.sink.add(jsonEncode(envelope));
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
    _connectedUri = null;
    isConnected.value = false;
  }

  Future<void> _connect(Uri uri) async {
    if (_channel != null && isConnected.value && _connectedUri == uri) {
      return;
    }

    await disconnect();
    try {
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      _connectedUri = uri;
      isConnected.value = true;
      _subscription = channel.stream.listen(
        _onMessage,
        onDone: () => isConnected.value = false,
        onError: (_) => isConnected.value = false,
      );
    } catch (_) {
      isConnected.value = false;
    }
  }

  void _onMessage(dynamic raw) {
    if (raw is! String) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final payload = Map<String, dynamic>.from(decoded);
      _incoming.add(WorkstationPresenceEnvelope.fromJson(payload));
    } catch (_) {
      // Ignore malformed messages and keep stream alive.
    }
  }

  Uri _buildUri({required String path, Map<String, String>? query}) {
    final host = kIsWeb ? Uri.base.host : '127.0.0.1';
    final secure = kIsWeb && Uri.base.scheme == 'https';
    final scheme = secure ? 'wss' : 'ws';

    return Uri(
      scheme: scheme,
      host: host,
      port: 8088,
      path: path,
      queryParameters: query,
    );
  }

  @override
  void onClose() {
    _subscription?.cancel();
    _incoming.close();
    _channel?.sink.close();
    _connectedUri = null;
    super.onClose();
  }
}
