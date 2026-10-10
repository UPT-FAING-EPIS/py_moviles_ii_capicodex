import 'package:flutter/material.dart';

enum AppVisualTheme {
  light, dark, football, wimbledon, rolandGarros, usOpen, volleyball, basketball,
}

/// Paleta compartida de GameOn. Mantiene el modo claro existente y aporta una
/// base oscura consistente para las nuevas pantallas.
abstract final class AppColors {
  static const primary = Color(0xFF007F56);
  static const primaryDark = Color(0xFF006644);
  static const accent = Color(0xFF00BCD4);
  static const darkBackground = Color(0xFF1E1E1E);
  static const darkSurface = Color(0xFF333333);
  static const darkText = Color(0xFFB0B0B0);
}

abstract final class AppTheme {
  static String? headerBackgroundFor(AppVisualTheme selection) => switch (selection) {
    AppVisualTheme.football => 'assets/theme/fondo_futbol.jpeg',
    AppVisualTheme.wimbledon => 'assets/theme/fondo_tenis_estilo_wimbledon_cesped.jpeg',
    AppVisualTheme.rolandGarros => 'assets/theme/fondo_tenis_estilo_roland_garros_polvoladrillo.jpeg',
    AppVisualTheme.usOpen => 'assets/theme/fondo_tenis_estilo_usopen_acrilicobitonoazul.jpeg',
    AppVisualTheme.volleyball => 'assets/theme/fondo_voley.jpeg',
    AppVisualTheme.basketball => 'assets/theme/fondo_basquet.png',
    _ => null,
  };

  static ThemeData forVisualTheme(AppVisualTheme selection) => switch (selection) {
    AppVisualTheme.light => light,
    AppVisualTheme.dark => dark,
    AppVisualTheme.football => _sportTheme(
      brightness: Brightness.dark,
      primary: const Color(0xFF1F8A55),
      secondary: const Color(0xFFC7E84A),
      background: const Color(0xFF0B1710),
      surface: const Color(0xFF15281B),
      onSurface: const Color(0xFFF2F7E9),
      border: const Color(0xFF4D6F3D),
    ),
    AppVisualTheme.wimbledon => _sportTheme(brightness: Brightness.dark, primary: const Color(0xFF5F8F25), secondary: const Color(0xFFC8E84E), background: const Color(0xFF13200F), surface: const Color(0xFF24361B), onSurface: const Color(0xFFF6F7E8), border: const Color(0xFF8A5BA8)),
    AppVisualTheme.rolandGarros => _sportTheme(brightness: Brightness.dark, primary: const Color(0xFFC65A2E), secondary: const Color(0xFFFFC85A), background: const Color(0xFF28150F), surface: const Color(0xFF472419), onSurface: const Color(0xFFFFF3E9), border: const Color(0xFFE6894D)),
    AppVisualTheme.usOpen => _sportTheme(brightness: Brightness.dark, primary: const Color(0xFF0789D1), secondary: const Color(0xFF4ED7FF), background: const Color(0xFF081B35), surface: const Color(0xFF102E52), onSurface: const Color(0xFFF0F8FF), border: const Color(0xFF2875B8)),
    AppVisualTheme.volleyball => _sportTheme(brightness: Brightness.light, primary: const Color(0xFF2B6F88), secondary: const Color(0xFFFFB547), background: const Color(0xFFE9D1A8), surface: const Color(0xFFFFF7E9), onSurface: const Color(0xFF20333A), border: const Color(0xFFB68348)),
    AppVisualTheme.basketball => _sportTheme(brightness: Brightness.dark, primary: const Color(0xFFD86922), secondary: const Color(0xFFFFB547), background: const Color(0xFF211007), surface: const Color(0xFF402112), onSurface: const Color(0xFFFFF4E8), border: const Color(0xFF98542B)),
  };

  static ThemeData _sportTheme({
    required Brightness brightness,
    required Color primary,
    required Color secondary,
    required Color background,
    required Color surface,
    required Color onSurface,
    required Color border,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      primary: primary,
      secondary: secondary,
      surface: surface,
      onSurface: onSurface,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      dividerColor: border.withValues(alpha: .55),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: brightness == Brightness.dark
              ? Colors.black
              : Colors.white,
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: TextStyle(color: onSurface.withValues(alpha: .65)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
      ),
    );
  }
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF8FAF9),
    appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE0E7E4)),
      ),
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.accent,
      surface: AppColors.darkSurface,
      onSurface: Color(0xFFF4F4F4),
    ),
    scaffoldBackgroundColor: AppColors.darkBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkBackground,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.primaryDark),
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.darkText),
      bodyMedium: TextStyle(color: AppColors.darkText),
      bodySmall: TextStyle(color: AppColors.darkText),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.primaryDark),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurface,
      hintStyle: const TextStyle(color: AppColors.darkText),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primaryDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primaryDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
    ),
    dividerColor: AppColors.primaryDark,
  );
}
