import 'package:flutter/material.dart';

import '../../../data/models/center_question_models.dart';
import 'question_shell_card.dart';

class ShortAnswerQuestionWidget extends StatefulWidget {
  const ShortAnswerQuestionWidget({
    super.key,
    required this.question,
    required this.initialValue,
    required this.onChanged,
  });

  final CenterQuestion question;
  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  State<ShortAnswerQuestionWidget> createState() =>
      _ShortAnswerQuestionWidgetState();
}

class _ShortAnswerQuestionWidgetState extends State<ShortAnswerQuestionWidget> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant ShortAnswerQuestionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue &&
        controller.text != widget.initialValue) {
      controller.text = widget.initialValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return QuestionShellCard(
      question: widget.question,
      child: TextField(
        controller: controller,
        onChanged: widget.onChanged,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: 'Write a short answer',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
