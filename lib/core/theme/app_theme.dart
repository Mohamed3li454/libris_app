import 'package:flutter/material.dart';
import 'package:libris_app/constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static final ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.background,
      onSurface: AppColors.lightOnSurface,
      onPrimary: Colors.white,
      outline: AppColors.lightOutline,
    ),
    scaffoldBackgroundColor: AppColors.background,
    cardColor: Colors.white,
    dividerColor: AppColors.lightOutline,
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );

  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.darkPrimary,
      secondary: AppColors.accent,
      surface: AppColors.darkBackground,
      onSurface: AppColors.darkOnSurface,
      onPrimary: AppColors.darkBackground,
      outline: AppColors.darkOutline,
    ),
    scaffoldBackgroundColor: AppColors.darkBackground,
    cardColor: AppColors.darkCard,
    dividerColor: AppColors.darkOutline,
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

extension LibrisTheme on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get titleColor => colors.onSurface;

  Color get mutedColor =>
      isDark ? AppColors.darkMuted : AppColors.muted;

  Color get pillColor =>
      isDark ? AppColors.darkOutline : AppColors.lightPill;
}
