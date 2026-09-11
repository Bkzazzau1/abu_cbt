import 'package:flutter/material.dart';

import '../../../data/models/center_question_models.dart';
import 'objective_single_question_widget.dart';

class TrueFalseQuestionWidget extends StatelessWidget {
  const TrueFalseQuestionWidget({
    super.key,
    required this.question,
    required this.selectedIndex,
    required this.onChanged,
  });

  final CenterQuestion question;
  final int? selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final tfQuestion = CenterQuestion(
      id: question.id,
      type: question.type,
      questionText: question.questionText,
      imagePath: question.imagePath,
      imageCaption: question.imageCaption,
      options: const ['True', 'False'],
    );

    return ObjectiveSingleQuestionWidget(
      question: tfQuestion,
      selectedIndex: selectedIndex,
      onChanged: onChanged,
    );
  }
}
