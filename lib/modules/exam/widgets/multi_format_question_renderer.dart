import 'package:flutter/material.dart';

import '../../../data/models/center_question_models.dart';
import 'drag_drop_question_widget.dart';
import 'essay_question_widget.dart';
import 'fill_blank_question_widget.dart';
import 'objective_multiple_question_widget.dart';
import 'objective_single_question_widget.dart';
import 'short_answer_question_widget.dart';
import 'true_false_question_widget.dart';
import 'whiteboard_question_widget.dart';

class MultiFormatQuestionRenderer extends StatelessWidget {
  const MultiFormatQuestionRenderer({
    super.key,
    required this.question,
    required this.answer,
    required this.onSingleSelect,
    required this.onMultiToggle,
    required this.onTextChanged,
    required this.onDragAssignmentsChanged,
    required this.onOpenWhiteboard,
  });

  final CenterQuestion question;
  final CenterCandidateAnswer answer;

  final ValueChanged<int> onSingleSelect;
  final ValueChanged<int> onMultiToggle;
  final ValueChanged<String> onTextChanged;
  final ValueChanged<Map<String, String>> onDragAssignmentsChanged;
  final VoidCallback onOpenWhiteboard;

  @override
  Widget build(BuildContext context) {
    switch (question.type) {
      case CenterQuestionType.objectiveSingle:
        return ObjectiveSingleQuestionWidget(
          key: ValueKey(question.id),
          question: question,
          selectedIndex: answer.selectedIndexes.isEmpty
              ? null
              : answer.selectedIndexes.first,
          onChanged: onSingleSelect,
        );

      case CenterQuestionType.objectiveMultiple:
        return ObjectiveMultipleQuestionWidget(
          key: ValueKey(question.id),
          question: question,
          selectedIndexes: answer.selectedIndexes,
          onToggle: onMultiToggle,
        );

      case CenterQuestionType.trueFalse:
        return TrueFalseQuestionWidget(
          key: ValueKey(question.id),
          question: question,
          selectedIndex: answer.selectedIndexes.isEmpty
              ? null
              : answer.selectedIndexes.first,
          onChanged: onSingleSelect,
        );

      case CenterQuestionType.fillBlank:
        return FillBlankQuestionWidget(
          key: ValueKey(question.id),
          question: question,
          initialValue: answer.textAnswer ?? '',
          onChanged: onTextChanged,
        );

      case CenterQuestionType.shortAnswer:
        return ShortAnswerQuestionWidget(
          key: ValueKey(question.id),
          question: question,
          initialValue: answer.textAnswer ?? '',
          onChanged: onTextChanged,
        );

      case CenterQuestionType.essay:
        return EssayQuestionWidget(
          key: ValueKey(question.id),
          question: question,
          initialValue: answer.textAnswer ?? '',
          onChanged: onTextChanged,
        );

      case CenterQuestionType.dragDrop:
        return DragDropQuestionWidget(
          key: ValueKey(question.id),
          question: question,
          assignments: answer.dragAssignments,
          onChanged: onDragAssignmentsChanged,
        );

      case CenterQuestionType.whiteboard:
        return WhiteboardQuestionWidget(
          key: ValueKey(question.id),
          question: question,
          strokeCount: answer.whiteboardStrokeCount,
          onOpenWhiteboard: onOpenWhiteboard,
        );
    }
  }
}
