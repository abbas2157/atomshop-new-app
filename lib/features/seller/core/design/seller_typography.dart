import 'package:flutter/material.dart';

import 'seller_colors.dart';

/// ─────────────────────────────────────────────────────────────────────────
///  Seller Design System — Typography
///
///  A single, professional type scale with a clear hierarchy:
///  display → title → body → label → caption → overline.
///
///  Styles are colour-aware: built from [SellerColors] so text contrast is
///  correct in both light and dark mode. Access via `context.sellerText`.
/// ─────────────────────────────────────────────────────────────────────────
class SellerTextTheme {
  final SellerColors c;
  const SellerTextTheme(this.c);

  static const String _family = 'Roboto';

  TextStyle _s(
    double size,
    FontWeight weight,
    Color color, {
    double height = 1.3,
    double? letterSpacing,
  }) => TextStyle(
    fontFamily: _family,
    fontSize: size,
    fontWeight: weight,
    height: height,
    letterSpacing: letterSpacing,
    color: color,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Page hero / big numbers in a header.
  TextStyle get display => _s(26, FontWeight.w800, c.textPrimary, height: 1.12);

  /// Screen / section title.
  TextStyle get titleLg => _s(20, FontWeight.w700, c.textPrimary, height: 1.2);

  /// Card title.
  TextStyle get titleMd => _s(17, FontWeight.w700, c.textPrimary, height: 1.25);

  /// Strong row title / list item heading.
  TextStyle get titleSm => _s(15, FontWeight.w700, c.textPrimary, height: 1.3);

  /// Emphasised body copy.
  TextStyle get bodyLg =>
      _s(15, FontWeight.w500, c.textPrimary, height: 1.45);

  /// Default body copy.
  TextStyle get body => _s(14, FontWeight.w400, c.textPrimary, height: 1.45);

  /// Secondary body copy / supporting text.
  TextStyle get bodySm =>
      _s(13, FontWeight.w400, c.textSecondary, height: 1.4);

  /// Field labels & strong inline labels.
  TextStyle get label => _s(13, FontWeight.w600, c.textSecondary, height: 1.3);

  TextStyle get labelSm => _s(12, FontWeight.w600, c.textSecondary, height: 1.3);

  /// De-emphasised metadata.
  TextStyle get caption => _s(12, FontWeight.w500, c.textTertiary, height: 1.3);

  /// All-caps eyebrow / section kicker.
  TextStyle get overline =>
      _s(11, FontWeight.w700, c.textTertiary, height: 1.2, letterSpacing: 0.6);

  /// Large metric value (KPI cards).
  TextStyle get metric => _s(23, FontWeight.w800, c.textPrimary, height: 1.05);

  /// Compact metric value.
  TextStyle get metricSm =>
      _s(18, FontWeight.w800, c.textPrimary, height: 1.1);

  /// Button / CTA label.
  TextStyle get button => _s(15, FontWeight.w700, c.onAccent, height: 1.1);
}
