import 'package:flutter/material.dart';

/// AtomShop colour palette.
///
/// Brand & semantic colours are fixed `const` (identical in light and dark —
/// the design must not change). Only the *neutrals* (backgrounds, surfaces,
/// text, borders) resolve at runtime based on [isDark], so every existing
/// `ColorPalette.background` etc. becomes dark-mode aware with no layout change.
///
/// [isDark] is set once per frame by the root `MyApp` from the persisted
/// customer theme mode.
class ColorPalette {
  /// Toggled by the app root before building the MaterialApp theme.
  static bool isDark = false;

  static Color _pick(Color light, Color dark) => isDark ? dark : light;

  // ── Primary Colors (Yellow/Gold — Brand) — UNCHANGED in dark ──────────────
  static const Color primary = Color(0xFFFFA500);
  static const Color primaryDark = Color(0xFFE6B400);
  static const Color primaryLight = Color(0xFFFFE066);

  // ── Secondary Colors (Blue/Navy) — UNCHANGED in dark ──────────────────────
  static const Color secondary = Color(0xFF213F9A);
  static const Color secondaryLight = Color(0xFF2261E5);
  static const Color secondaryDark = Color(0xFF1A3277);

  // ── Accent Colors — UNCHANGED ─────────────────────────────────────────────
  static const Color accentRed = Color(0xFFED1A2F);
  static const Color accentGreen = Color(0xFF3CAC10);
  static const Color accentBlue = Color(0xFF2261E5);
  static const Color accentPurple = Color(0xFF62449A);

  // ── Background Colors — brightness aware ──────────────────────────────────
  static Color get background => _pick(const Color(0xFFFFFFFF), const Color(0xFF0F1216));
  static Color get backgroundGray =>
      _pick(const Color(0xFFF5F5F5), const Color(0xFF161A20));
  static Color get backgroundBlueLight =>
      _pick(const Color(0xFFEBF5FF), const Color(0xFF13233B));
  static Color get backgroundGreenLight =>
      _pick(const Color(0xFFF5FAFA), const Color(0xFF12231F));
  static const Color backgroundDark = Color(0xFF3D464D);

  // ── Surface Colors — brightness aware ─────────────────────────────────────
  static Color get surface => _pick(const Color(0xFFFFFFFF), const Color(0xFF161A20));
  static Color get surfaceGray =>
      _pick(const Color(0xFFF5F5F5), const Color(0xFF20242C));
  static const Color surfaceDark = Color(0xFF3D464D);

  // ── Text Colors — brightness aware ────────────────────────────────────────
  static Color get textPrimary => _pick(const Color(0xFF000000), const Color(0xFFECEFF4));
  static Color get textSecondary =>
      _pick(const Color(0xFF6C757D), const Color(0xFF9AA3AF));
  static Color get textLight =>
      _pick(const Color(0xFF374151), const Color(0xFFAEB6C2));
  static const Color textWhite = Color(0xFFFFFFFF);
  static Color get textMuted =>
      _pick(const Color(0x661E2329), const Color(0x99FFFFFF));

  // ── Border Colors — brightness aware ──────────────────────────────────────
  static Color get border => _pick(const Color(0xFFCED4DA), const Color(0xFF2A2F37));
  static Color get borderDark =>
      _pick(const Color(0xFF6C757D), const Color(0xFF3A414B));

  // ── Status Colors — UNCHANGED ─────────────────────────────────────────────
  static const Color success = Color(0xFF28A745);
  static const Color error = Color(0xFFDC3545);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF17A2B8);

  // ── Special UI Colors — UNCHANGED ─────────────────────────────────────────
  static const Color redLight = Color(0xFFFCD4D8);
  static const Color blueLight = Color(0xFF3B7B61);
  static const Color redBackground = Color(0x30ED1A2F);

  // ── Gradient Colors — UNCHANGED ───────────────────────────────────────────
  static const List<Color> primaryGradient = [
    Color(0xFFFFD333),
    Color(0xFFE6B400),
  ];

  static const List<Color> secondaryGradient = [
    Color(0xFF213F9A),
    Color(0xFF2261E5),
  ];
}
