import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/ks_ui_tokens.dart';

class KsPageShell extends StatelessWidget {
  const KsPageShell({
    super.key,
    required this.child,
    this.padding = KsUiTokens.pagePadding,
    this.maxContentWidth,
    this.safeArea = true,
    this.showTopGlow = true,
    this.showBottomGlow = true,
    this.showGrid = true,
  });

  final Widget child;
  final EdgeInsets padding;
  final double? maxContentWidth;
  final bool safeArea;
  final bool showTopGlow;
  final bool showBottomGlow;
  final bool showGrid;

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [KsUiTokens.bgTop, Color(0xFF10251D), KsUiTokens.bgBottom],
        ),
      ),
      child: Stack(
        children: [
          if (showGrid) const Positioned.fill(child: _GridOverlay()),
          if (showTopGlow)
            const Positioned(
              top: -120,
              left: -80,
              child: _GlowOrb(size: 360, color: KsUiTokens.glow, opacity: 0.14),
            ),
          if (showTopGlow)
            const Positioned(
              top: 40,
              right: -70,
              child: _GlowOrb(
                size: 280,
                color: KsUiTokens.glowSecondary,
                opacity: 0.12,
              ),
            ),
          if (showBottomGlow)
            const Positioned(
              bottom: -140,
              right: -100,
              child: _GlowOrb(size: 400, color: KsUiTokens.glow, opacity: 0.10),
            ),
          if (showBottomGlow)
            const Positioned(
              bottom: 30,
              left: -60,
              child: _GlowOrb(
                size: 240,
                color: KsUiTokens.glowSecondary,
                opacity: 0.08,
              ),
            ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.02),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.08),
                  ],
                ),
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final body = Padding(
                padding: padding,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: maxContentWidth ?? 1400,
                      minHeight: constraints.maxHeight - padding.vertical,
                    ),
                    child: child,
                  ),
                ),
              );

              return safeArea ? SafeArea(child: body) : body;
            },
          ),
        ],
      ),
    );

    return Scaffold(backgroundColor: Colors.transparent, body: content);
  }
}

class KsPageSection extends StatelessWidget {
  const KsPageSection({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.child,
    this.spacing = 14,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleLarge),
                  if (subtitle != null) ...[
                    const SizedBox(height: 6),
                    Text(subtitle!, style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 12), trailing!],
          ],
        ),
        SizedBox(height: spacing),
        child,
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: opacity),
                color.withValues(alpha: opacity * 0.45),
                color.withValues(alpha: 0),
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

class _GridOverlay extends StatelessWidget {
  const _GridOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(child: CustomPaint(painter: _GridPainter()));
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 36.0;

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1;

    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final accent = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x0039D2FF), Color(0x4439D2FF), Color(0x007C5CFF)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 120))
      ..strokeWidth = 1.2;

    canvas.drawLine(Offset(0, 110), Offset(size.width * 0.65, 110), accent);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
