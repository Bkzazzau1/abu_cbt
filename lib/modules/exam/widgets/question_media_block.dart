import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class QuestionMediaBlock extends StatelessWidget {
  const QuestionMediaBlock({
    super.key,
    required this.imagePath,
    this.imageCaption,
  });

  final String? imagePath;
  final String? imageCaption;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (imagePath == null || imagePath!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    Widget imageWidget;

    if (imagePath!.startsWith('assets/')) {
      imageWidget = Image.asset(
        imagePath!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _errorBox(cs),
      );
    } else if (!kIsWeb) {
      imageWidget = Image.file(
        File(imagePath!),
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _errorBox(cs),
      );
    } else {
      imageWidget = _errorBox(cs);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageWidget,
            ),
          ),
          if (imageCaption != null && imageCaption!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              imageCaption!.trim(),
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.72),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _errorBox(ColorScheme cs) {
    return Container(
      height: 180,
      alignment: Alignment.center,
      color: cs.surfaceContainerHighest,
      child: Text(
        'Image not available',
        style: TextStyle(
          color: cs.onSurface.withValues(alpha: 0.7),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
