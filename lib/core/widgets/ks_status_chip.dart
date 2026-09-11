import 'package:flutter/material.dart';

enum KsStatusChipTone {
  neutral,
  info,
  success,
  warning,
  warningSoft,
  danger,
  accent,
}

class KsStatusChip extends StatelessWidget {
  const KsStatusChip({
    super.key,
    required this.label,
    this.tone = KsStatusChipTone.neutral,
    this.margin,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.borderRadius = 999,
    this.textStyle,
  });

  final String label;
  final KsStatusChipTone tone;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final colors = _chipColors(tone);

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Text(
        label,
        style:
            textStyle ??
            TextStyle(
              color: colors.fg,
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }

  _ChipColors _chipColors(KsStatusChipTone tone) {
    switch (tone) {
      case KsStatusChipTone.neutral:
        return const _ChipColors(
          fg: Color(0xFF667085),
          bg: Color(0xFFF2F4F7),
        );
      case KsStatusChipTone.info:
        return const _ChipColors(
          fg: Color(0xFF155EEF),
          bg: Color(0xFFDCEBFF),
        );
      case KsStatusChipTone.success:
        return const _ChipColors(
          fg: Color(0xFF0F8A4B),
          bg: Color(0xFFDFF7E8),
        );
      case KsStatusChipTone.warning:
        return const _ChipColors(
          fg: Color(0xFFB26A00),
          bg: Color(0xFFFFF3CD),
        );
      case KsStatusChipTone.warningSoft:
        return const _ChipColors(
          fg: Color(0xFF8A5A00),
          bg: Color(0xFFFFE8BF),
        );
      case KsStatusChipTone.danger:
        return const _ChipColors(
          fg: Color(0xFFB42318),
          bg: Color(0xFFFFE4E2),
        );
      case KsStatusChipTone.accent:
        return const _ChipColors(
          fg: Color(0xFF6941C6),
          bg: Color(0xFFEDE9FE),
        );
    }
  }
}

class _ChipColors {
  const _ChipColors({required this.fg, required this.bg});

  final Color fg;
  final Color bg;
}
