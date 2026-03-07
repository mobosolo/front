import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFFF9FAFB);
  static const Color foreground = Color(0xFF1F2937);
  static const Color card = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF1E7F5C);
  static const Color secondary = Color(0xFFFF9F1C);
  static const Color muted = Color(0xFFF3F4F6);
  static const Color mutedForeground = Color(0xFF6B7280);
  static const Color destructive = Color(0xFFEF4444);
  static const Color success = Color(0xFF22C55E);
  static const Color border = Color(0x1A000000); // rgba(0,0,0,0.1)

  static ThemeData light() {
    final colorScheme = const ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      secondary: secondary,
      onSecondary: foreground,
      error: destructive,
      onError: Colors.white,
      background: background,
      onBackground: foreground,
      surface: card,
      onSurface: foreground,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: foreground,
        elevation: 0,
      ),
      dividerColor: border,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: foreground),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: foreground),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: foreground),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: foreground),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: foreground),
        labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: foreground),
      ),
    );
  }
}
