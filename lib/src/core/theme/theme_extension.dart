import 'package:flutter/material.dart';
import 'package:freelancer_flutter/src/core/constants/app_colors.dart';

/// Extension to easily get theme-aware colors
extension ThemeColors on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  
  Color get backgroundColor => Theme.of(this).scaffoldBackgroundColor;
  Color get cardColor => Theme.of(this).cardColor;
  Color get textPrimary => Theme.of(this).textTheme.bodyLarge?.color ?? 
      (isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);
  Color get textSecondary => Theme.of(this).textTheme.bodyMedium?.color ?? 
      (isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary);
  Color get borderColor => Theme.of(this).dividerColor;
  Color get primary => AppColors.primary;
}
