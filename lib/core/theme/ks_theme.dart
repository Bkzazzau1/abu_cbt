import 'package:flutter/material.dart';

import 'ks_ui_tokens.dart';

class KsTheme {
  KsTheme._();

  static ThemeData get darkAcademic {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF39D2FF),
      onPrimary: Color(0xFF03111C),
      primaryContainer: Color(0xFF12324A),
      onPrimaryContainer: Color(0xFFE6F9FF),
      secondary: Color(0xFF7C5CFF),
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFF2A2156),
      onSecondaryContainer: Color(0xFFF1EEFF),
      tertiary: Color(0xFF22C55E),
      onTertiary: Color(0xFF04130A),
      tertiaryContainer: Color(0xFF123822),
      onTertiaryContainer: Color(0xFFE7FCEE),
      error: Color(0xFFEF4444),
      onError: Colors.white,
      errorContainer: Color(0xFF4B1616),
      onErrorContainer: Color(0xFFFFE7E7),
      surface: Color(0xFF0D1B2A),
      onSurface: Color(0xFFF5F7FA),
      surfaceContainerHighest: Color(0xFF18283A),
      onSurfaceVariant: Color(0xFF94A3B8),
      outline: Color(0x33FFFFFF),
      outlineVariant: Color(0x1FFFFFFF),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Color(0xFFF5F7FA),
      onInverseSurface: Color(0xFF0D1B2A),
      inversePrimary: Color(0xFF1D8FFF),
    );

    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: KsUiTokens.bgTop,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: KsUiTokens.textPrimary,
          letterSpacing: -0.8,
        ),
        headlineMedium: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w900,
          color: KsUiTokens.textPrimary,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: KsUiTokens.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: KsUiTokens.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: KsUiTokens.textPrimary,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: KsUiTokens.textPrimary,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: KsUiTokens.textSecondary,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: KsUiTokens.textPrimary,
          letterSpacing: 0.2,
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: KsUiTokens.textPrimary,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: KsUiTokens.textPrimary,
          letterSpacing: -0.4,
        ),
      ),
      dividerColor: Colors.white.withValues(alpha: 0.08),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        labelStyle: const TextStyle(
          color: KsUiTokens.textSecondary,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: TextStyle(
          color: KsUiTokens.textSecondary.withValues(alpha: 0.82),
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: KsUiTokens.textSecondary,
        suffixIconColor: KsUiTokens.textSecondary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KsUiTokens.radiusMd),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KsUiTokens.radiusMd),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KsUiTokens.radiusMd),
          borderSide: const BorderSide(color: KsUiTokens.glow, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KsUiTokens.radiusMd),
          borderSide: const BorderSide(color: KsUiTokens.danger, width: 1.1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KsUiTokens.radiusMd),
          borderSide: const BorderSide(color: KsUiTokens.danger, width: 1.2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: KsUiTokens.glow,
          foregroundColor: const Color(0xFF03111C),
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.10),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.35),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KsUiTokens.radiusMd),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: KsUiTokens.textPrimary,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KsUiTokens.radiusMd),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: KsUiTokens.glow,
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KsUiTokens.radiusMd),
          ),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: KsUiTokens.glow,
        linearTrackColor: Color(0x1FFFFFFF),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.06),
        disabledColor: Colors.white.withValues(alpha: 0.04),
        selectedColor: KsUiTokens.glow.withValues(alpha: 0.18),
        secondarySelectedColor: KsUiTokens.glow.withValues(alpha: 0.18),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: const TextStyle(
          color: KsUiTokens.textPrimary,
          fontWeight: FontWeight.w800,
        ),
        secondaryLabelStyle: const TextStyle(
          color: KsUiTokens.textPrimary,
          fontWeight: FontWeight.w800,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
      checkboxTheme: CheckboxThemeData(
        side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}
