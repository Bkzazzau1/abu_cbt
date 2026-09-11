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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            offset: const Offset(0, 8),
            color: Colors.black.withValues(alpha: 0.03),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.questionText,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          if (question.imagePath != null &&
              question.imagePath!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            QuestionMediaBlock(
              imagePath: question.imagePath,
              imageCaption: question.imageCaption,
            ),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
