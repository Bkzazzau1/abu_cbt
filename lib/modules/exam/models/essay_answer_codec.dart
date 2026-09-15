import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart';

/// Converts a stored essay answer (a Quill Delta JSON string produced by
/// [EssayQuestionWidget]) back into plain text — used wherever the answer
/// needs to be compared or scored as plain text rather than rendered
/// richly (e.g. the AI answer-similarity check, which must never compare
/// formatting markup between two candidates instead of their actual
/// words). Falls back to returning the input unchanged for legacy
/// plain-text answers that predate the rich editor.
String essayAnswerToPlainText(String storedAnswer) {
  final trimmed = storedAnswer.trim();
  if (trimmed.isEmpty) return '';
  try {
    final decoded = jsonDecode(trimmed);
    if (decoded is List) {
      return Document.fromJson(decoded).toPlainText().trim();
    }
  } catch (_) {
    // Not Delta JSON — use as-is.
  }
  return trimmed;
}
