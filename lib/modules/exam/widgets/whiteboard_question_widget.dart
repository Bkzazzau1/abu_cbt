import 'package:flutter/material.dart';

import '../../../data/models/center_question_models.dart';
import 'question_shell_card.dart';

class WhiteboardQuestionWidget extends StatelessWidget {
  const WhiteboardQuestionWidget({
    super.key,
    required this.question,
    required this.strokeCount,
    required this.onOpenWhiteboard,
  });

  final CenterQuestion question;
  final int strokeCount;
  final VoidCallback onOpenWhiteboard;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasDrawing = strokeCount > 0;

    return QuestionShellCard(
      question: question,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (question.whiteboardPrompt != null &&
              question.whiteboardPrompt!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                question.whiteboardPrompt!.trim(),
                style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Text(
                  hasDrawing
                      ? '$strokeCount drawing stroke(s) saved'
                      : 'No drawing added yet',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: onOpenWhiteboard,
                icon: const Icon(Icons.draw_outlined),
                label: Text(hasDrawing ? 'Edit Drawing' : 'Open Whiteboard'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
