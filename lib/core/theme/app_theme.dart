import 'package:flutter/material.dart';
import 'package:libris_app/constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static const Color _lightOnSurface = Color(0xFF2C2416);
  static const Color _darkBackground = Color(0xFF1A1610);
  static const Color _darkCard = Color(0xFF252017);
  static const Color _darkPrimary = Color(0xFFD4B56A);
  static const Color _darkOnSurface = Color(0xFFF0EADE);

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.background,
        onSurface: _lightOnSurface,
        onPrimary: Colors.white,
        outline: Color(0xFFE5DDD0),
      ),
      scaffoldBackgroundColor: AppColors.background,
      cardColor: Colors.white,
      dividerColor: const Color(0xFFE5DDD0),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: _darkPrimary,
        secondary: AppColors.accent,
        surface: _darkBackground,
        onSurface: _darkOnSurface,
        onPrimary: _darkBackground,
        outline: Color(0xFF3A3224),
      ),
      scaffoldBackgroundColor: _darkBackground,
      cardColor: _darkCard,
      dividerColor: const Color(0xFF3A3224),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}

extension LibrisTheme on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get titleColor => colors.onSurface;

  Color get mutedColor =>
      isDark ? const Color(0xFFB0A898) : AppColors.muted;

  Color get pillColor =>
      isDark ? const Color(0xFF3A3224) : const Color(0xFFE8DFC8);
}
