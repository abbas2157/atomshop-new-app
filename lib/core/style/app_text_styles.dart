import 'package:atompro/core/style/color_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class AppTextStyles {
  static const String _fontFamily = 'Roboto';

  // Display Styles
  static TextStyle get display1 => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 96.sp,
    fontWeight: FontWeight.w300,
    height: 1.2,
    color: ColorPalette.textPrimary,
  );

  static TextStyle get display2 => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 88.sp,
    fontWeight: FontWeight.w300,
    height: 1.2,
    color: ColorPalette.textPrimary,
  );

  // Heading Styles
  static TextStyle get h1 => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 40.sp,
    fontWeight: FontWeight.w500,
    height: 1.2,
    color: ColorPalette.textPrimary,
  );

  static TextStyle get h2 => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32.sp,
    fontWeight: FontWeight.w500,
    height: 1.2,
    color: ColorPalette.textPrimary,
  );

  static TextStyle get h3 => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28.sp,
    fontWeight: FontWeight.w500,
    height: 1.2,
    color: ColorPalette.textPrimary,
  );

  static TextStyle get h4 => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24.sp,
    fontWeight: FontWeight.w500,
    height: 1.2,
    color: ColorPalette.textPrimary,
  );

  static TextStyle get h5 => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20.sp,
    fontWeight: FontWeight.w500,
    height: 1.2,
    color: ColorPalette.textPrimary,
  );

  static TextStyle get h6 => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16.sp,
    fontWeight: FontWeight.w500,
    height: 1.2,
    color: ColorPalette.textPrimary,
  );

  // Body Text Styles
  static TextStyle get bodyLarge => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16.sp,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: ColorPalette.textPrimary,
  );

  static TextStyle get bodyMedium => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: ColorPalette.textPrimary,
  );

  static TextStyle get bodySmall => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12.sp,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: ColorPalette.textSecondary,
  );

  // Subtitle Styles
  static TextStyle get subtitle1 => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16.sp,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: ColorPalette.textSecondary,
  );

  static TextStyle get subtitle2 => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: ColorPalette.textSecondary,
  );

  // Caption & Label Styles
  static TextStyle get caption => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12.sp,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: ColorPalette.textLight,
  );

  static TextStyle get overline => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 10.sp,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 1.5,
    color: ColorPalette.textLight,
  );

  // Button Text Styles
  static TextStyle get buttonLarge => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 17.sp,
    fontWeight: FontWeight.w500,
    height: 1.2,
    textBaseline: TextBaseline.alphabetic,
  );

  static TextStyle get buttonMedium => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16.sp,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );

  static TextStyle get buttonSmall => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );

  static TextStyle get bodyBold =>
      bodyMedium.copyWith(fontWeight: FontWeight.w600);

  static TextStyle get bodySemiBold =>
      bodyMedium.copyWith(fontWeight: FontWeight.w500);
}

extension AppTextStyleExtensions on TextStyle {
  TextStyle get white => copyWith(color: Colors.white);
  TextStyle get primary => copyWith(color: Colors.yellow);
  TextStyle get secondary => copyWith(color: Colors.blue);
  TextStyle get textSecondary => copyWith(color: ColorPalette.textSecondary);
  TextStyle get red => copyWith(color: Colors.red);
  TextStyle get green => copyWith(color: Colors.green);
  TextStyle get purple => copyWith(color: Colors.purple);
  TextStyle get bold => copyWith(fontWeight: FontWeight.bold);
  TextStyle get semiBold => copyWith(fontWeight: FontWeight.w600);
  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);
}
