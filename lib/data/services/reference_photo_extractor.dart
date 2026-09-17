import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;

/// Copies a bundled Flutter asset (the candidate's enrolled photo) out to a
/// plain file the local detector subprocess can open directly — Flutter
/// assets live inside the app bundle, not on the filesystem, so the Python
/// worker has no other way to read one.
class ReferencePhotoExtractor {
  Directory? _dir;

  /// Returns null (identity checks are simply skipped) if the asset can't be
  /// loaded. Bounded by a short timeout so a slow/broken disk never delays
  /// login or exam launch — this is an auxiliary integrity feature, not
  /// something worth blocking on.
  Future<String?> extract(String assetPath) async {
    if (assetPath.trim().isEmpty) return null;
    try {
      return await _copy(assetPath).timeout(const Duration(seconds: 2));
    } catch (_) {
      return null;
    }
  }

  Future<String> _copy(String assetPath) async {
    final bytes = await rootBundle.load(assetPath);
    final dir = await Directory.systemTemp.createTemp('abu_reference_photo_');
    _dir = dir;
    final extension = assetPath.contains('.')
        ? assetPath.substring(assetPath.lastIndexOf('.'))
        : '.jpg';
    final file = File('${dir.path}/reference$extension');
    await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    return file.path;
  }

  Future<void> dispose() async {
    final dir = _dir;
    _dir = null;
    if (dir == null) return;
    try {
      await dir.delete(recursive: true);
    } catch (_) {
      // Best-effort cleanup; a leftover temp file isn't worth failing over.
    }
  }
}
