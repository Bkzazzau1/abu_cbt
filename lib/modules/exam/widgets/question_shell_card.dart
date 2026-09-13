import 'package:flutter/material.dart';

import '../../../data/models/center_question_models.dart';
import 'question_media_block.dart';

class QuestionShellCard extends StatelessWidget {
  const QuestionShellCard({
    super.key,
    required this.question,
    required this.child,
  });

  final CenterQuestion question;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.questionText,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              height: 1.6,
              letterSpacing: -0.3,
            ),
          ),
          if (question.imagePath != null &&
              question.imagePath!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            QuestionMediaBlock(
              imagePath: question.imagePath,
              imageCaption: question.imageCaption,
            ),
          ],
          const SizedBox(height: 26),
          child,
        ],
      ),
    );
  }
}
