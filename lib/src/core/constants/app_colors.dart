import 'package:flutter/material.dart';

class AppColors {
  // ======== DARK THEME COLORS (Default) ========
  static const Color primary = Color(0xFFFDC800); // Yellow/Gold
  static const Color primaryForeground = Color(0xFF171717);

  // Dark theme specific
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkCard = Color(0xFF171717);
  static const Color darkCardForeground = Color(0xFFFAFAFA);
  static const Color darkTextPrimary = Color(0xFFFAFAFA);
  static const Color darkTextSecondary = Color(0xFFA1A1A1);
  static const Color darkAccent = Color(0xFF404040);
  static const Color darkBorder = Color(0xFF282828);

  // ======== LIGHT THEME COLORS ========
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardForeground = Color(0xFF171717);
  static const Color lightTextPrimary = Color(0xFF171717);
  static const Color lightTextSecondary = Color(0xFF737373);
  static const Color lightAccent = Color(0xFFE5E5E5);
  static const Color lightBorder = Color(0xFFE0E0E0);

  // ======== LEGACY (for backward compatibility) ========
  static const Color background = darkBackground;
  static const Color card = darkCard;
  static const Color cardForeground = darkCardForeground;
  static const Color textPrimary = darkTextPrimary;
  static const Color textSecondary = darkTextSecondary;
  static const Color accent = darkAccent;
  static const Color border = darkBorder;
}
