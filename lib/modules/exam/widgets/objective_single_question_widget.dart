import 'package:flutter/material.dart';

import '../../../data/models/center_question_models.dart';
import 'question_shell_card.dart';

class ObjectiveSingleQuestionWidget extends StatelessWidget {
  const ObjectiveSingleQuestionWidget({
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
    final cs = Theme.of(context).colorScheme;

    return QuestionShellCard(
      question: question,
      child: Column(
        children: List.generate(question.options.length, (i) {
          final selected = selectedIndex == i;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => onChanged(i),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 20,
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
                    Icon(
                      selected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: selected
                          ? cs.primary
                          : cs.onSurface.withValues(alpha: 0.55),
                    ),
                    const SizedBox(width: 10),
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
      ),
    );
  }
}
