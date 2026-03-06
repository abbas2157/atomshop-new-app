import 'package:flutter/material.dart';

class ColorPalette {
  // Primary Colors (Yellow/Gold - Brand Color)
  static const Color primary = Color(0xFFFFA500); // Yellow/Gold
  static const Color primaryDark = Color(
    0xFFE6B400,
  ); // Darker Yellow (from hover state)
  static const Color primaryLight = Color(0xFFFFE066);

  // Secondary Colors (Blue/Navy)
  static const Color secondary = Color(0xFF213F9A); // Navy Blue
  static const Color secondaryLight = Color(0xFF2261E5); // Light Blue
  static const Color secondaryDark = Color(0xFF1A3277);

  // Accent Colors
  static const Color accentRed = Color(0xFFED1A2F); // Red
  static const Color accentGreen = Color(0xFF3CAC10); // Green
  static const Color accentBlue = Color(0xFF2261E5); // Blue
  static const Color accentPurple = Color(0xFF62449A); // Blue

  // Background Colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundGray = Color(0xFFF5F5F5);
  static const Color backgroundBlueLight = Color(0xFFEBF5FF);
  static const Color backgroundGreenLight = Color(0xFFF5FAFA);
  static const Color backgroundDark = Color(0xFF3D464D);

  // Surface Colors
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceGray = Color(0xFFF5F5F5);
  static const Color surfaceDark = Color(0xFF3D464D);

  // Text Colors
  static const Color textPrimary = Color(0xFF000000); // Black
  static const Color textSecondary = Color(0xFF6C757D); // Gray
  static const Color textLight = Color(0xFF374151);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0x661E2329); // Muted text (rgba)

  // Border Colors
  static const Color border = Color(0xFFCED4DA);
  static const Color borderDark = Color(0xFF6C757D);

  // Status Colors
  static const Color success = Color(0xFF28A745); // Bootstrap green
  static const Color error = Color(0xFFDC3545); // Bootstrap red
  static const Color warning = Color(0xFFFFC107); // Bootstrap warning
  static const Color info = Color(0xFF17A2B8); // Bootstrap info

  // Special UI Colors
  static const Color redLight = Color(0xFFFCD4D8); // Light red background
  static const Color blueLight = Color(0xFF3B7B61); // Light blue background
  static const Color redBackground = Color(0x30ED1A2F); // Red with opacity

  // Gradient Colors
  static const List<Color> primaryGradient = [
    Color(0xFFFFD333),
    Color(0xFFE6B400),
  ];

  static const List<Color> secondaryGradient = [
    Color(0xFF213F9A),
    Color(0xFF2261E5),
  ];
}
