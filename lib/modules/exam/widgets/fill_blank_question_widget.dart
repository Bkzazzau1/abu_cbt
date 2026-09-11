import 'package:flutter/material.dart';

import '../../../data/models/center_question_models.dart';
import 'question_shell_card.dart';

class FillBlankQuestionWidget extends StatefulWidget {
  const FillBlankQuestionWidget({
    super.key,
    required this.question,
    required this.initialValue,
    required this.onChanged,
  });

  final CenterQuestion question;
  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  State<FillBlankQuestionWidget> createState() =>
      _FillBlankQuestionWidgetState();
}

class _FillBlankQuestionWidgetState extends State<FillBlankQuestionWidget> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant FillBlankQuestionWidget oldWidget) {
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
        decoration: const InputDecoration(
          hintText: 'Type your answer here',
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
