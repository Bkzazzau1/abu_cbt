import 'package:flutter/material.dart';

const abuGreen = Color(0xFF125C45);
const abuInk = Color(0xFF20372E);
const abuMuted = Color(0xFF728078);
const abuLine = Color(0xFFE2E8E2);
const abuCanvas = Color(0xFFF5F7F3);

ThemeData abuDemoTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: abuGreen,
    brightness: Brightness.light,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme.copyWith(primary: abuGreen, surface: Colors.white),
    scaffoldBackgroundColor: abuCanvas,
    fontFamily: 'Segoe UI',
    textTheme: ThemeData.light().textTheme.apply(
      bodyColor: abuInk,
      displayColor: abuInk,
    ),
    dividerColor: abuLine,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: abuLine),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: abuLine),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        side: const BorderSide(color: abuLine),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
    ),
  );
}
