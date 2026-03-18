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
    if (isDark != null) {
      state = isDark ? ThemeMode.dark : ThemeMode.light;
    }
  }

  // NOUVELLE LOGIQUE : Détection du thème effectif
  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();

    // On détermine si on est ACTUELLEMENT en mode sombre
    // (Soit forcé, soit à cause du système)
    bool isCurrentlyDark;

    if (state == ThemeMode.dark) {
      isCurrentlyDark = true;
    } else if (state == ThemeMode.light) {
      isCurrentlyDark = false;
    } else {
      // Mode System : on regarde la luminosité du platform
      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      isCurrentlyDark = brightness == Brightness.dark;
    }

    // On inverse l'état réel
    final newMode = isCurrentlyDark ? ThemeMode.light : ThemeMode.dark;

    state = newMode;
    await prefs.setBool(_themeKey, newMode == ThemeMode.dark);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});
