// lib/core/themes/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // Couleurs de base (à personnaliser plus tard)
  static const Color primaryColor = Color(0xFF4F46E5); // Indigo
  static const Color secondaryColor = Color(0xFF10B981); // Emerald (pour les revenus)
  static const Color expenseColor = Color(0xFFEF4444); // Red (pour les dépenses)

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true, // Activation de Material 3 (le standard actuel)
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
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
      ),
    );
  }

  // On préparera le thème sombre pour plus tard
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: primaryColor, brightness: Brightness.dark),
    );
  }
}
