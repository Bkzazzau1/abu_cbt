import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../data/models/center_question_models.dart';
import 'question_shell_card.dart';

class EssayQuestionWidget extends StatefulWidget {
  const EssayQuestionWidget({
    super.key,
    required this.question,
    required this.initialValue,
    required this.onChanged,
  });

  final CenterQuestion question;
  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  State<EssayQuestionWidget> createState() => _EssayQuestionWidgetState();
}

class _EssayQuestionWidgetState extends State<EssayQuestionWidget> {
  late final QuillController controller;
  // Created once and reused across rebuilds. QuillEditor.basic() would
  // otherwise mint a brand-new FocusNode/ScrollController on every build —
  // and this widget rebuilds every second from the exam timer — silently
  // dropping keyboard focus and selection state mid-keystroke, which broke
  // Backspace (and any other editing that depends on a stable selection).
  late final FocusNode _focusNode;
  late final ScrollController _scrollController;
  String _lastEmitted = '';

  @override
  void initState() {
    super.initState();
    controller = QuillController(
      document: _documentFrom(widget.initialValue),
      selection: const TextSelection.collapsed(offset: 0),
    );
    _focusNode = FocusNode();
    _scrollController = ScrollController();
    _lastEmitted = widget.initialValue;
    controller.addListener(_handleChanged);
  }

  Document _documentFrom(String stored) {
    final trimmed = stored.trim();
    if (trimmed.isEmpty) return Document();
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is List) return Document.fromJson(decoded);
    } catch (_) {
      // Legacy plain-text answer from before the rich editor — load it as
      // a single paragraph instead of losing it.
    }
    return Document()..insert(0, trimmed);
  }

  void _handleChanged() {
    final plainText = controller.document.toPlainText().trim();
    final next = plainText.isEmpty
        ? ''
        : jsonEncode(controller.document.toDelta().toJson());
    if (next == _lastEmitted) return;
    _lastEmitted = next;
    widget.onChanged(next);
  }

  @override
  void didUpdateWidget(covariant EssayQuestionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.id != widget.question.id &&
        widget.initialValue != _lastEmitted) {
      controller.removeListener(_handleChanged);
      controller.document = _documentFrom(widget.initialValue);
      controller.updateSelection(
        const TextSelection.collapsed(offset: 0),
        ChangeSource.local,
      );
      _lastEmitted = widget.initialValue;
      controller.addListener(_handleChanged);
    }
  }

  @override
  Widget build(BuildContext context) {
    return QuestionShellCard(
      question: widget.question,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8E2)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F7F3),
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8E2))),
                borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              ),
              child: QuillSimpleToolbar(
                controller: controller,
                config: const QuillSimpleToolbarConfig(
                  showFontFamily: false,
                  showFontSize: false,
                  showSubscript: false,
                  showSuperscript: false,
                  showSearchButton: false,
                  multiRowsDisplay: true,
                ),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 220),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: QuillEditor(
                  controller: controller,
                  focusNode: _focusNode,
                  scrollController: _scrollController,
                  config: QuillEditorConfig(
                    placeholder: 'Write your essay answer here',
                    padding: EdgeInsets.zero,
                    expands: false,
                    scrollable: true,
                    // Exam integrity: candidates must type their own answer,
                    // not paste in pre-written text. This blocks Ctrl+V/⌘V;
                    // there's no context-menu paste option to begin with
                    // since we don't supply a contextMenuBuilder.
                    customActions: {
                      PasteTextIntent: CallbackAction<PasteTextIntent>(
                        onInvoke: (_) => null,
                      ),
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.removeListener(_handleChanged);
    controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
