import 'package:flutter/material.dart';

import '../../../core/widgets/glass_card.dart';
import '../../demo/abu_demo_theme.dart';

/// Drop-in replacement for [GlassCard] that matches the light, ABU-branded
/// theme (`abuDemoTheme`) used on the login screen and the demo workspace,
/// instead of the dark "security console" look `GlassCard` always renders
/// regardless of the ambient `Theme` — mirrors the same fix already applied
/// to the scientific calculator dialog. Keeps [GlassCard]'s constructor
/// shape (including the unused `blur`/`showGlow` parameters) so call sites
/// only need the class name swapped, not their arguments.
class LightPanel extends StatelessWidget {
  const LightPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 18.0,
    this.blur = 0.0,
    this.tone = GlassCardTone.normal,
    this.showGlow = false,
    this.margin,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final double blur;
  final GlassCardTone tone;
  final bool showGlow;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    final (Color background, Color border) = _toneColors(tone);

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: abuInk.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: abuInk),
        child: IconTheme(
          data: const IconThemeData(color: abuInk),
          child: child,
        ),
      ),
    );
  }

  (Color, Color) _toneColors(GlassCardTone tone) {
    switch (tone) {
      case GlassCardTone.primary:
        return (Colors.white, abuGreen.withValues(alpha: 0.35));
      case GlassCardTone.danger:
        return (const Color(0xFFFFF6F5), const Color(0xFFFFC9C2));
      case GlassCardTone.warning:
        return (const Color(0xFFFFFBF1), const Color(0xFFFFE1A3));
      case GlassCardTone.success:
        return (const Color(0xFFF3FBF6), const Color(0xFFBEE6CC));
      case GlassCardTone.normal:
        return (Colors.white, abuLine);
    }
  }
}

/// Drop-in replacement for [KsStatCard] on the light theme — same public
/// API (title/value/icon/width/layout/tone) so call sites only need the
/// class name swapped.
enum LightStatCardLayout { row, column }

class LightStatCard extends StatelessWidget {
  const LightStatCard({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.width = 180,
    this.layout = LightStatCardLayout.row,
    this.tone = GlassCardTone.normal,
  });

  final String title;
  final String value;
  final IconData? icon;
  final double width;
  final LightStatCardLayout layout;
  final GlassCardTone tone;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: LightPanel(
        tone: tone,
        child: layout == LightStatCardLayout.column
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
                    style: const TextStyle(
                      color: abuMuted,
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
                        color: abuGreen.withValues(alpha: 0.10),
                      ),
                      child: Icon(icon, color: abuGreen),
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
                          style: const TextStyle(
                            color: abuMuted,
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
