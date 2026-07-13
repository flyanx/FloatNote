/// Material 3 主题配置

import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme() {
    const colorScheme = ColorScheme.light(
      primary: Color(0xFF5b5ef4),
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFE8E8FE),
      onPrimaryContainer: Color(0xFF1A1B4B),
      secondary: Color(0xFF5b5ef4),
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: Color(0xFF1a1a1a),
      error: Color(0xFFe8453c),
      onError: Colors.white,
      outline: Color(0xFFE0E0E0),
    );
    return _buildTheme(colorScheme);
  }

  static ThemeData darkTheme() {
    const colorScheme = ColorScheme.dark(
      primary: Color(0xFF7c7ff5),
      onPrimary: Colors.white,
      primaryContainer: Color(0xFF2A2B5B),
      onPrimaryContainer: Color(0xFFE8E8FE),
      secondary: Color(0xFF7c7ff5),
      onSecondary: Colors.white,
      surface: Color(0xFF24242a),
      onSurface: Color(0xFFf0f0f2),
      error: Color(0xFFe8453c),
      onError: Colors.white,
      outline: Color(0xFF3A3A42),
    );
    return _buildTheme(colorScheme);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withOpacity(0.5),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outline, width: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outline,
        thickness: 0.5,
        space: 0,
      ),
    );
  }
}
