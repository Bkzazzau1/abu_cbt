import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/ks_ui_tokens.dart';

enum GlassCardTone { normal, primary, danger, success, warning }

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = KsUiTokens.cardPadding,
    this.radius = KsUiTokens.radiusLg,
    this.blur = KsUiTokens.blurMd,
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
    final glowColor = _toneGlowColor(tone);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
          if (showGlow)
            BoxShadow(
              color: glowColor.withValues(alpha: 0.16),
              blurRadius: 28,
              spreadRadius: 1,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  KsUiTokens.panelStrong,
                  KsUiTokens.panel,
                  KsUiTokens.panelSoft,
                ],
              ),
              border: Border.all(color: _toneBorderColor(tone), width: 1.1),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -30,
                  right: -10,
                  child: IgnorePointer(
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            glowColor.withValues(alpha: 0.16),
                            glowColor.withValues(alpha: 0.00),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(radius),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.06),
                            Colors.white.withValues(alpha: 0.015),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.18, 0.45],
                        ),
                      ),
                    ),
                  ),
                ),
                DefaultTextStyle.merge(
                  style: const TextStyle(color: KsUiTokens.textPrimary),
                  child: IconTheme(
                    data: const IconThemeData(color: KsUiTokens.textPrimary),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _toneGlowColor(GlassCardTone tone) {
    switch (tone) {
      case GlassCardTone.primary:
        return KsUiTokens.glow;
      case GlassCardTone.danger:
        return KsUiTokens.danger;
      case GlassCardTone.success:
        return KsUiTokens.success;
      case GlassCardTone.warning:
        return KsUiTokens.warning;
      case GlassCardTone.normal:
        return KsUiTokens.glowSecondary;
    }
  }

  Color _toneBorderColor(GlassCardTone tone) {
    switch (tone) {
      case GlassCardTone.primary:
        return KsUiTokens.borderBright.withValues(alpha: 0.60);
      case GlassCardTone.danger:
        return KsUiTokens.danger.withValues(alpha: 0.35);
      case GlassCardTone.success:
        return KsUiTokens.success.withValues(alpha: 0.32);
      case GlassCardTone.warning:
        return KsUiTokens.warning.withValues(alpha: 0.32);
      case GlassCardTone.normal:
        return KsUiTokens.border;
    }
  }
}
