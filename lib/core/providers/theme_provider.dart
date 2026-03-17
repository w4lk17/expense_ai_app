import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _themeKey = 'isDarkMode';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_themeKey);

    // Si null, on suit le système, sinon on applique le choix
    if (isDark != null) {
      state = isDark ? ThemeMode.dark : ThemeMode.light;
    }
  }

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = state == ThemeMode.dark;

    // On inverse
    state = isDark ? ThemeMode.light : ThemeMode.dark;

    // On sauvegarde
    await prefs.setBool(_themeKey, !isDark);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});
