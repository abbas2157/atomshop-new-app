import 'package:flutter/material.dart';

/// A semantic colour trio for a status / category.
///
/// [fg] is used for text & icons, [bg] for the soft surface behind them,
/// and [border] for an optional hairline outline.
@immutable
class SellerTone {
  final Color fg;
  final Color bg;
  final Color border;

  const SellerTone({required this.fg, required this.bg, required this.border});

  static SellerTone lerp(SellerTone a, SellerTone b, double t) => SellerTone(
    fg: Color.lerp(a.fg, b.fg, t)!,
    bg: Color.lerp(a.bg, b.bg, t)!,
    border: Color.lerp(a.border, b.border, t)!,
  );
}

/// ─────────────────────────────────────────────────────────────────────────
///  Seller Design System — Colour Tokens (ThemeExtension)
///
///  Registered on both the light and dark [ThemeData] for Seller Mode, so a
///  single `context.sellerColors` call resolves to the correct palette and
///  dark mode "just works" everywhere.
/// ─────────────────────────────────────────────────────────────────────────
@immutable
class SellerColors extends ThemeExtension<SellerColors> {
  // ── Surfaces ────────────────────────────────────────────────────────────
  /// App background — a soft, low-glare neutral.
  final Color canvas;

  /// Primary card / sheet surface.
  final Color surface;

  /// Slightly differentiated surface (nested cards, subtle fills).
  final Color surfaceAlt;

  /// Muted fill for tracks, inactive segments, chips.
  final Color surfaceMuted;

  // ── Lines ─────────────────────────────────────────────────────────────
  final Color border;
  final Color borderStrong;
  final Color divider;

  // ── Text ──────────────────────────────────────────────────────────────
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  /// Text/icon colour that sits on top of [accent] / gradients.
  final Color onAccent;

  // ── Brand accent (refined indigo) ─────────────────────────────────────
  final Color accent;
  final Color accentStrong;
  final Color accentSurface;

  /// Header / hero gradient.
  final Color gradientStart;
  final Color gradientEnd;

  // ── Semantic raw colours ──────────────────────────────────────────────
  final Color success;
  final Color successSurface;
  final Color warning;
  final Color warningSurface;
  final Color danger;
  final Color dangerSurface;
  final Color info;
  final Color infoSurface;
  final Color violet;
  final Color violetSurface;

  // ── Elevation ─────────────────────────────────────────────────────────
  final Color shadowColor;
  final bool isDark;

  const SellerColors({
    required this.canvas,
    required this.surface,
    required this.surfaceAlt,
    required this.surfaceMuted,
    required this.border,
    required this.borderStrong,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.onAccent,
    required this.accent,
    required this.accentStrong,
    required this.accentSurface,
    required this.gradientStart,
    required this.gradientEnd,
    required this.success,
    required this.successSurface,
    required this.warning,
    required this.warningSurface,
    required this.danger,
    required this.dangerSurface,
    required this.info,
    required this.infoSurface,
    required this.violet,
    required this.violetSurface,
    required this.shadowColor,
    required this.isDark,
  });

  // ── Tones (semantic trios) ─────────────────────────────────────────────
  SellerTone get accentTone =>
      SellerTone(fg: accent, bg: accentSurface, border: accent.withValues(alpha: 0.18));
  SellerTone get successTone => SellerTone(
    fg: success,
    bg: successSurface,
    border: success.withValues(alpha: 0.18),
  );
  SellerTone get warningTone => SellerTone(
    fg: warning,
    bg: warningSurface,
    border: warning.withValues(alpha: 0.18),
  );
  SellerTone get dangerTone => SellerTone(
    fg: danger,
    bg: dangerSurface,
    border: danger.withValues(alpha: 0.18),
  );
  SellerTone get infoTone =>
      SellerTone(fg: info, bg: infoSurface, border: info.withValues(alpha: 0.18));
  SellerTone get violetTone => SellerTone(
    fg: violet,
    bg: violetSurface,
    border: violet.withValues(alpha: 0.18),
  );
  SellerTone get neutralTone =>
      SellerTone(fg: textSecondary, bg: surfaceMuted, border: border);

  // ── Elevation helpers ──────────────────────────────────────────────────
  /// Soft shadow for resting cards. In dark mode we lean on borders instead,
  /// so this is near-invisible by design.
  List<BoxShadow> get cardShadow => isDark
      ? const []
      : [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.04),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ];

  /// Stronger shadow for floating surfaces (nav bar, FAB, sheets).
  List<BoxShadow> get floatingShadow => isDark
      ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ]
      : [
          BoxShadow(
            color: accent.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ];

  LinearGradient get headerGradient => LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Palettes ────────────────────────────────────────────────────────────
  static const SellerColors light = SellerColors(
    canvas: Color(0xFFF4F6FB),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF8FAFD),
    surfaceMuted: Color(0xFFEEF1F8),
    border: Color(0xFFE7EBF3),
    borderStrong: Color(0xFFD6DCEA),
    divider: Color(0xFFEDF0F7),
    textPrimary: Color(0xFF0F1729),
    textSecondary: Color(0xFF5B6577),
    textTertiary: Color(0xFF98A1B3),
    onAccent: Color(0xFFFFFFFF),
    accent: Color(0xFF3B5BDB),
    accentStrong: Color(0xFF2F49C9),
    accentSurface: Color(0xFFEDF0FE),
    gradientStart: Color(0xFF1E2A78),
    gradientEnd: Color(0xFF3B5BDB),
    success: Color(0xFF15A05A),
    successSurface: Color(0xFFE6F6EC),
    warning: Color(0xFFC77600),
    warningSurface: Color(0xFFFBF0DC),
    danger: Color(0xFFDC2A36),
    dangerSurface: Color(0xFFFCE8E9),
    info: Color(0xFF2563EB),
    infoSurface: Color(0xFFE7EEFD),
    violet: Color(0xFF7C3AED),
    violetSurface: Color(0xFFF0EAFD),
    shadowColor: Color(0xFF1B2A4A),
    isDark: false,
  );

  static const SellerColors dark = SellerColors(
    canvas: Color(0xFF0B0F17),
    surface: Color(0xFF151A24),
    surfaceAlt: Color(0xFF1A2030),
    surfaceMuted: Color(0xFF222A3B),
    border: Color(0xFF242C3E),
    borderStrong: Color(0xFF333D54),
    divider: Color(0xFF1F2736),
    textPrimary: Color(0xFFEAF0FB),
    textSecondary: Color(0xFF9BA7BF),
    textTertiary: Color(0xFF6A7588),
    onAccent: Color(0xFFFFFFFF),
    accent: Color(0xFF5B79F0),
    accentStrong: Color(0xFF7390F5),
    accentSurface: Color(0xFF1D2647),
    gradientStart: Color(0xFF1A2350),
    gradientEnd: Color(0xFF3B5BDB),
    success: Color(0xFF34D399),
    successSurface: Color(0xFF112A20),
    warning: Color(0xFFFBBF24),
    warningSurface: Color(0xFF2B2112),
    danger: Color(0xFFF87171),
    dangerSurface: Color(0xFF2C1618),
    info: Color(0xFF60A5FA),
    infoSurface: Color(0xFF14233F),
    violet: Color(0xFFA78BFA),
    violetSurface: Color(0xFF221B38),
    shadowColor: Color(0xFF000000),
    isDark: true,
  );

  @override
  SellerColors copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceAlt,
    Color? surfaceMuted,
    Color? border,
    Color? borderStrong,
    Color? divider,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? onAccent,
    Color? accent,
    Color? accentStrong,
    Color? accentSurface,
    Color? gradientStart,
    Color? gradientEnd,
    Color? success,
    Color? successSurface,
    Color? warning,
    Color? warningSurface,
    Color? danger,
    Color? dangerSurface,
    Color? info,
    Color? infoSurface,
    Color? violet,
    Color? violetSurface,
    Color? shadowColor,
    bool? isDark,
  }) {
    return SellerColors(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      divider: divider ?? this.divider,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      onAccent: onAccent ?? this.onAccent,
      accent: accent ?? this.accent,
      accentStrong: accentStrong ?? this.accentStrong,
      accentSurface: accentSurface ?? this.accentSurface,
      gradientStart: gradientStart ?? this.gradientStart,
      gradientEnd: gradientEnd ?? this.gradientEnd,
      success: success ?? this.success,
      successSurface: successSurface ?? this.successSurface,
      warning: warning ?? this.warning,
      warningSurface: warningSurface ?? this.warningSurface,
      danger: danger ?? this.danger,
      dangerSurface: dangerSurface ?? this.dangerSurface,
      info: info ?? this.info,
      infoSurface: infoSurface ?? this.infoSurface,
      violet: violet ?? this.violet,
      violetSurface: violetSurface ?? this.violetSurface,
      shadowColor: shadowColor ?? this.shadowColor,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  SellerColors lerp(ThemeExtension<SellerColors>? other, double t) {
    if (other is! SellerColors) return this;
    return SellerColors(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentStrong: Color.lerp(accentStrong, other.accentStrong, t)!,
      accentSurface: Color.lerp(accentSurface, other.accentSurface, t)!,
      gradientStart: Color.lerp(gradientStart, other.gradientStart, t)!,
      gradientEnd: Color.lerp(gradientEnd, other.gradientEnd, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSurface: Color.lerp(successSurface, other.successSurface, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSurface: Color.lerp(warningSurface, other.warningSurface, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerSurface: Color.lerp(dangerSurface, other.dangerSurface, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoSurface: Color.lerp(infoSurface, other.infoSurface, t)!,
      violet: Color.lerp(violet, other.violet, t)!,
      violetSurface: Color.lerp(violetSurface, other.violetSurface, t)!,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}
