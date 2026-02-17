import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get darkTheme {
    const accent = Color(0xFF58E6A9);
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: base.colorScheme.copyWith(
        primary: accent,
        secondary: const Color(0xFF6DD5FA),
        surface: const Color(0xFF1C1C1E),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF121212),
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1F1F22),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF252529),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
