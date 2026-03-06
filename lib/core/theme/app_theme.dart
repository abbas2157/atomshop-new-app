import 'package:atompro/core/style/app_text_styles.dart';
import 'package:atompro/core/style/color_palette.dart';
import 'package:flutter/material.dart';

/// AtomShop Theme Configuration
class AppTheme {
  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',

      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: ColorPalette.primary,
        onPrimary: ColorPalette.textWhite,
        secondary: ColorPalette.secondary,
        onSecondary: ColorPalette.textWhite,
        onTertiary: ColorPalette.textWhite,
        error: ColorPalette.error,
        onError: ColorPalette.textWhite,
        surface: ColorPalette.surface,
        onSurface: ColorPalette.textPrimary,
        background: ColorPalette.background,
        onBackground: ColorPalette.textPrimary,
      ),

      // Scaffold
      scaffoldBackgroundColor: ColorPalette.background,

      // Text Theme
      textTheme: TextTheme(
        displayLarge: AppTextStyles.display1,
        displayMedium: AppTextStyles.display2,
        headlineLarge: AppTextStyles.h1,
        headlineMedium: AppTextStyles.h2,
        headlineSmall: AppTextStyles.h3,
        titleLarge: AppTextStyles.h4,
        titleMedium: AppTextStyles.h5,
        titleSmall: AppTextStyles.h6,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.buttonLarge,
        labelMedium: AppTextStyles.buttonMedium,
        labelSmall: AppTextStyles.buttonSmall,
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: ColorPalette.background,
        foregroundColor: ColorPalette.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.h5,
        iconTheme: const IconThemeData(color: ColorPalette.textPrimary),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: ColorPalette.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: ColorPalette.border, width: 1),
        ),
        margin: const EdgeInsets.all(8),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorPalette.primary,
          foregroundColor: ColorPalette.textWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.buttonMedium,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorPalette.primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: const BorderSide(color: ColorPalette.primary, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.buttonMedium,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ColorPalette.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: AppTextStyles.buttonMedium,
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColorPalette.surfaceGray,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColorPalette.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColorPalette.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColorPalette.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColorPalette.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColorPalette.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: ColorPalette.textLight,
        ),
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: ColorPalette.textSecondary,
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(color: ColorPalette.textPrimary, size: 24),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: ColorPalette.border,
        thickness: 1,
        space: 16,
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: ColorPalette.surface,
        selectedItemColor: ColorPalette.primary,
        unselectedItemColor: ColorPalette.textLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTextStyles.caption,
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: ColorPalette.primary,
        foregroundColor: ColorPalette.textWhite,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: ColorPalette.surfaceGray,
        selectedColor: ColorPalette.primary,
        labelStyle: AppTextStyles.bodySmall,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: ColorPalette.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: AppTextStyles.h4,
        contentTextStyle: AppTextStyles.bodyMedium,
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ColorPalette.backgroundDark,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: ColorPalette.textWhite,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Dark Theme (Optional - based on light theme with dark colors)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,

      colorScheme: const ColorScheme.dark(
        primary: ColorPalette.primary,
        onPrimary: ColorPalette.textWhite,
        secondary: ColorPalette.secondary,
        onSecondary: ColorPalette.textWhite,
        onTertiary: ColorPalette.textWhite,
        error: ColorPalette.error,
        onError: ColorPalette.textWhite,
        surface: ColorPalette.surfaceDark,
        onSurface: ColorPalette.textWhite,
      ),

      scaffoldBackgroundColor: ColorPalette.backgroundDark,

      // You can customize dark theme further if needed
    );
  }
}
