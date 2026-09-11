import 'package:flutter/material.dart';

import 'glass_card.dart';

enum KsStatCardLayout {
  row,
  column,
}

class KsStatCard extends StatelessWidget {
  const KsStatCard({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.width = 180,
    this.layout = KsStatCardLayout.row,
    this.tone = GlassCardTone.normal,
  });

  final String title;
  final String value;
  final IconData? icon;
  final double width;
  final KsStatCardLayout layout;
  final GlassCardTone tone;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: width,
      child: GlassCard(
        tone: tone,
        child: layout == KsStatCardLayout.column
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  if (icon != null)
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: cs.primary.withValues(alpha: 0.10),
                      ),
                      child: Icon(icon, color: cs.primary),
                    ),
                  if (icon != null) const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          value,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          title,
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.72),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
