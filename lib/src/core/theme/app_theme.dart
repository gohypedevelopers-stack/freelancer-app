import 'package:flutter/material.dart';
import 'package:freelancer_flutter/src/core/constants/app_colors.dart';

class AppTheme {
  // ======== DARK THEME ========
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBackground,
    primaryColor: AppColors.primary,
    
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.primaryForeground,
      secondary: AppColors.darkCard,
      onSecondary: AppColors.darkCardForeground,
      surface: AppColors.darkCard,
      onSurface: AppColors.darkTextPrimary,
      surfaceContainer: AppColors.darkCard,
    ),

    fontFamily: 'Inter',

    textTheme: const TextTheme(
      displayLarge: TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(color: AppColors.darkTextPrimary),
      bodyMedium: TextStyle(color: AppColors.darkTextSecondary),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.primaryForeground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.darkTextSecondary,
      ),
    ),

    cardColor: AppColors.darkCard,
    dividerColor: AppColors.darkBorder,
  );

  // ======== LIGHT THEME ========
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBackground,
    primaryColor: AppColors.primary,
    
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.primaryForeground,
      secondary: AppColors.lightCard,
      onSecondary: AppColors.lightCardForeground,
      surface: AppColors.lightCard,
      onSurface: AppColors.lightTextPrimary,
      surfaceContainer: AppColors.lightCard,
    ),

    fontFamily: 'Inter',

    textTheme: const TextTheme(
      displayLarge: TextStyle(color: AppColors.lightTextPrimary, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: AppColors.lightTextPrimary, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(color: AppColors.lightTextPrimary),
      bodyMedium: TextStyle(color: AppColors.lightTextSecondary),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.primaryForeground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.lightTextSecondary,
      ),
    ),

    cardColor: AppColors.lightCard,
    dividerColor: AppColors.lightBorder,
  );
}
