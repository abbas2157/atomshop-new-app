import 'package:flutter/widgets.dart';

/// App v2 design tokens, matching the storefront v2 (public/web/v2/css/site.css)
/// and the "Atomshop App Redesign" canvas. Prefixed `Atom` so they never clash
/// with the seller design system (`AppSpace`, `AppRadius`).
abstract final class AtomColors {
  static const ink = Color(0xFF14213D);
  static const primary = Color(0xFF2747C7);
  static const primaryDark = Color(0xFF1D3AA6);
  static const primarySoft = Color(0xFFEEF2FD);
  static const amber = Color(0xFFF7A928);
  static const amberSoft = Color(0xFFFFF5E0);
  static const amberInk = Color(0xFF8A5A00);
  static const surface = Color(0xFFF5F7FB);
  static const line = Color(0xFFE3E8F1);
  static const line2 = Color(0xFFDCE2EC);

  /// Input outlines: 3:1 on white so an empty field is still visible
  /// (WCAG 1.4.11). [line] and [line2] are for decorative dividers only.
  static const fieldLine = Color(0xFF848EA5);
  static const body = Color(0xFF4F5B76);
  // muted and placeholder keep 4.5:1 on both white and [surface] (WCAG AA).
  static const muted = Color(0xFF646E87);
  static const placeholder = Color(0xFF67718A);
  static const onDark = Color(0xFFC9D1E4);
  static const white = Color(0xFFFFFFFF);

  static const green = Color(0xFF18794A);
  static const greenSoft = Color(0xFFE8F7EF);
  static const rose = Color(0xFFB0283F);
  static const roseSoft = Color(0xFFFDEEF1);
  static const violet = Color(0xFF5A3FA6);
  static const violetSoft = Color(0xFFF1EDFB);
  static const teal = Color(0xFF0E7490);
  static const tealSoft = Color(0xFFE6F6FA);
}

/// 4-pt spacing scale. Screen gutter is [md] + 4 = 20 on phones.
abstract final class AtomSpace {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double gutter = 20;
  static const double lg = 24;
  static const double xl = 32;
}

abstract final class AtomRadius {
  static const double chip = 14;
  static const double input = 16;
  static const double card = 20;
  static const double hero = 24;
  static const double pill = 999;
}

/// Heights that keep every tap target at 44 px or more.
abstract final class AtomSize {
  static const double buttonLg = 52;
  static const double button = 44;
  static const double buttonSm = 36;
  static const double input = 50;
  static const double iconButton = 44;
  static const double bottomNav = 76;
}
