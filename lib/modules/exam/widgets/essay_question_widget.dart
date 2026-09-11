import 'package:flutter/material.dart';

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
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant EssayQuestionWidget oldWidget) {
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
        minLines: 6,
        maxLines: 10,
        decoration: const InputDecoration(
          hintText: 'Write your essay answer here',
          border: OutlineInputBorder(),
          alignLabelWithHint: true,
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
