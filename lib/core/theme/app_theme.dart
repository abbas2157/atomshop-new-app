import 'package:atompro/core/style/app_text_styles.dart';
import 'package:atompro/core/style/color_palette.dart';
import 'package:flutter/material.dart';

/// AtomShop theme. Built from [ColorPalette], which resolves its neutral
/// colours from [ColorPalette.isDark]. The app root sets `isDark` before
/// building, so the same builder produces the correct light or dark theme —
/// the design/layout is unchanged, only colour values adapt.
class AppTheme {
  static ThemeData get theme => _build();
  static ThemeData get lightTheme => _build();
  static ThemeData get darkTheme => _build();

  static ThemeData _build() {
    final isDark = ColorPalette.isDark;
    final brightness = isDark ? Brightness.dark : Brightness.light;

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      brightness: brightness,

      colorScheme: ColorScheme(
        brightness: brightness,
        primary: ColorPalette.primary,
        onPrimary: ColorPalette.textWhite,
        secondary: ColorPalette.secondary,
        onSecondary: ColorPalette.textWhite,
        tertiary: ColorPalette.accentBlue,
        onTertiary: ColorPalette.textWhite,
        error: ColorPalette.error,
        onError: ColorPalette.textWhite,
        surface: ColorPalette.surface,
        onSurface: ColorPalette.textPrimary,
      ),

      scaffoldBackgroundColor: ColorPalette.background,
      canvasColor: ColorPalette.background,

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

      appBarTheme: AppBarTheme(
        backgroundColor: ColorPalette.background,
        foregroundColor: ColorPalette.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.h5,
        iconTheme: IconThemeData(color: ColorPalette.textPrimary),
      ),

      cardTheme: CardThemeData(
        color: ColorPalette.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: ColorPalette.border, width: 1),
        ),
        margin: const EdgeInsets.all(8),
      ),

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

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColorPalette.surfaceGray,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ColorPalette.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ColorPalette.border, width: 1),
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

      iconTheme: IconThemeData(color: ColorPalette.textPrimary, size: 24),

      dividerTheme: DividerThemeData(
        color: ColorPalette.border,
        thickness: 1,
        space: 16,
      ),

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

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: ColorPalette.primary,
        foregroundColor: ColorPalette.textWhite,
        elevation: 4,
        shape: CircleBorder(),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: ColorPalette.surfaceGray,
        selectedColor: ColorPalette.primary,
        labelStyle: AppTextStyles.bodySmall,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: ColorPalette.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: AppTextStyles.h4,
        contentTextStyle: AppTextStyles.bodyMedium,
      ),

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
}
