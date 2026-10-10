import 'package:flutter/material.dart';

enum AppVisualTheme { light, dark, football, tennis }

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
    AppVisualTheme.tennis => 'assets/theme/fondo_tenis.jpeg',
    _ => null,
  };

  static ThemeData forVisualTheme(AppVisualTheme selection) => switch (selection) {
    AppVisualTheme.light => light,
    AppVisualTheme.dark => dark,
    AppVisualTheme.football => _sportTheme(
      brightness: Brightness.dark,
      primary: const Color(0xFFB6D63A),
      secondary: const Color(0xFFE8F46A),
      background: const Color(0xFF0D2417),
      surface: const Color(0xFF193A25),
      onSurface: const Color(0xFFF2F7E9),
      border: const Color(0xFFDAF27A),
    ),
    AppVisualTheme.tennis => _sportTheme(
      brightness: Brightness.light,
      primary: const Color(0xFF176B86),
      secondary: const Color(0xFFD4E640),
      background: const Color(0xFFF1E4C8),
      surface: const Color(0xFFFCF5E7),
      onSurface: const Color(0xFF17333D),
      border: const Color(0xFF4C8CA2),
    ),
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
