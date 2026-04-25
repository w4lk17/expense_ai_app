import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  static const Color canvas = Color(0xFFF5F1E8);
  static const Color ink = Color(0xFF1F2933);
  static const Color moss = Color(0xFF4E7B61);
  static const Color amber = Color(0xFFD6A34D);
  static const Color coral = Color(0xFFD46A5F);
  static const Color mist = Color(0xFFE7DFD1);
  static const Color slate = Color(0xFF566372);
  static const Color deep = Color(0xFF141A21);

  static ColorScheme _scheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ColorScheme(
      brightness: brightness,
      primary: isDark ? const Color(0xFF90B49C) : moss,
      onPrimary: Colors.white,
      secondary: isDark ? const Color(0xFFE0BE87) : amber,
      onSecondary: deep,
      error: coral,
      onError: Colors.white,
      surface: isDark ? const Color(0xFF1A2129) : Colors.white,
      onSurface: isDark ? const Color(0xFFF3EFE7) : ink,
      primaryContainer: isDark
          ? const Color(0xFF223428)
          : const Color(0xFFDCE8DF),
      onPrimaryContainer: isDark
          ? const Color(0xFFE4F0E7)
          : const Color(0xFF22412E),
      secondaryContainer: isDark
          ? const Color(0xFF44341D)
          : const Color(0xFFF6E7CB),
      onSecondaryContainer: isDark
          ? const Color(0xFFFFF1D7)
          : const Color(0xFF503818),
      errorContainer: isDark
          ? const Color(0xFF4B2621)
          : const Color(0xFFF7DDD9),
      onErrorContainer: isDark
          ? const Color(0xFFFFE6E2)
          : const Color(0xFF5E2A24),
      surfaceContainerHighest: isDark ? const Color(0xFF28313A) : mist,
      onSurfaceVariant: isDark ? const Color(0xFFC6D0DA) : slate,
      outline: isDark ? const Color(0xFF46505A) : const Color(0xFFC9C0B1),
      outlineVariant: isDark
          ? const Color(0xFF323C46)
          : const Color(0xFFD8CDBE),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: isDark ? canvas : deep,
      onInverseSurface: isDark ? deep : const Color(0xFFF5F1E8),
      inversePrimary: isDark ? moss : const Color(0xFFA6C5B0),
    );
  }

  static ThemeData _baseTheme(Brightness brightness) {
    final scheme = _scheme(brightness);
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? deep : canvas,
      cardColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark
            ? const Color(0xFF171D24)
            : const Color(0xFFF0EADF),
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF232B34) : Colors.white,
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark
            ? const Color(0xFF232B34)
            : const Color(0xFFEEE7DA),
        selectedColor: scheme.primaryContainer,
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        labelStyle: TextStyle(color: scheme.onSurface),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: scheme.onSurface,
          fontSize: 34,
          height: 1.05,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.2,
        ),
        headlineMedium: TextStyle(
          color: scheme.onSurface,
          fontSize: 28,
          height: 1.1,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.9,
        ),
        titleLarge: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        titleMedium: TextStyle(
          color: scheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(
          color: scheme.onSurface,
          fontSize: 16,
          height: 1.35,
        ),
        bodyMedium: TextStyle(
          color: scheme.onSurfaceVariant,
          fontSize: 14,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static ThemeData get lightTheme => _baseTheme(Brightness.light);

  static ThemeData get darkTheme => _baseTheme(Brightness.dark);
}
