import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF4F46E5); // Indigo
  static const Color secondaryColor = Color(0xFF10B981); // Emerald
  static const Color expenseColor = Color(0xFFEF4444); // Red

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: primaryColor, brightness: Brightness.light),
      scaffoldBackgroundColor: const Color(0xFFF9FAFB),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        surface: const Color(0xFF1E1E1E), // Fond des cartes
      ),
      scaffoldBackgroundColor: const Color(0xFF121212), // Fond principal
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor.withBlue(200), // Un peu plus clair pour le dark
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(color: const Color(0xFF1E1E1E), elevation: 2),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[850],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
      ),
    );
  }
}
