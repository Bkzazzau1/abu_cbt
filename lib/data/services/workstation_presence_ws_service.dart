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

  Uri _buildUri({
    required String path,
    Map<String, String>? query,
  }) {
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
