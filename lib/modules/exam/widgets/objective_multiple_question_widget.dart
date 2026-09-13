import 'package:flutter/material.dart';

import '../../../data/models/center_question_models.dart';
import 'question_shell_card.dart';

class ObjectiveMultipleQuestionWidget extends StatelessWidget {
  const ObjectiveMultipleQuestionWidget({
    super.key,
    required this.question,
    required this.selectedIndexes,
    required this.onToggle,
  });

  final CenterQuestion question;
  final List<int> selectedIndexes;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return QuestionShellCard(
      question: question,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select all that apply.',
            style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...List.generate(question.options.length, (i) {
            final selected = selectedIndexes.contains(i);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => onToggle(i),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: selected
                        ? cs.primary.withValues(alpha: 0.10)
                        : cs.surface,
                    border: Border.all(
                      color: selected
                          ? cs.primary.withValues(alpha: 0.28)
                          : cs.onSurface.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Checkbox(value: selected, onChanged: (_) => onToggle(i)),
                      Expanded(
                        child: Text(
                          question.options[i],
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
