import 'package:flutter/material.dart';
import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';

export 'package:dekorin_apps/config/theme/app_colors.dart';
export 'package:dekorin_apps/config/theme/app_typography.dart';

/// Dekorin brand colors and theme configuration.
class AppTheme {
  AppTheme._();

  // Alias untuk kompatibilitas mundur
  static const Color primaryGold = AppColors.primaryGold;
  static const Color primaryDark = AppColors.primaryDark;
  static const Color backgroundDark = AppColors.backgroundDark;
  static const Color backgroundLight = AppColors.backgroundLight;
  static const Color surfaceLight = AppColors.surfaceLight;
  static const Color textDark = AppColors.textDark;
  static const Color textLight = AppColors.textLight;
  static const Color errorRed = AppColors.errorRed;
  static const Color successGreen = AppColors.successGreen;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryGold,
        primary: AppColors.primaryGold,
        onPrimary: AppColors.textWhite,
        surface: AppColors.surfaceLight,
        onSurface: AppColors.textDark,
        error: AppColors.errorRed,
      ),
      scaffoldBackgroundColor: AppColors.backgroundLight,
      textTheme: AppTypography.textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.titleLarge.copyWith(fontSize: 20),
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGold,
          foregroundColor: AppColors.textWhite,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTypography.button,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryGold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.errorRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.errorRed, width: 2),
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textLight),
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textLight.withValues(alpha: 0.7)),
      ),
    );
  }
}
