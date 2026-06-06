import 'package:flutter/widgets.dart';

/// ─────────────────────────────────────────────────────────────────────────
///  Seller Design System — Layout Tokens
///
///  Brightness-independent primitives shared across the entire Seller Mode.
///  Everything here is expressed in raw logical pixels (no ScreenUtil) so the
///  seller experience renders identically and predictably on every device.
/// ─────────────────────────────────────────────────────────────────────────

/// 8pt-based spacing scale (with a 4pt half-step for fine control).
///
/// Use these everywhere instead of ad-hoc magic numbers. Consistent spacing
/// is the single biggest driver of a calm, premium layout.
abstract final class AppSpace {
  /// 2 — hairline gaps (icon ↔ label micro spacing)
  static const double xxxs = 2;

  /// 4 — tight internal padding
  static const double xxs = 4;

  /// 8 — default small gap
  static const double xs = 8;

  /// 12 — compact section gap
  static const double sm = 12;

  /// 16 — base unit: card padding, list gaps, page gutters
  static const double md = 16;

  /// 20 — comfortable section gap
  static const double lg = 20;

  /// 24 — large section separation
  static const double xl = 24;

  /// 32 — block separation
  static const double xxl = 32;

  /// 40 — hero spacing
  static const double xxxl = 40;
}

/// Unified corner-radius scale. One rhythm across the whole app.
abstract final class AppRadius {
  /// 10 — chips, pills-with-text, small controls
  static const double sm = 10;

  /// 12 — inputs, buttons, icon badges
  static const double md = 12;

  /// 16 — cards (the default surface radius)
  static const double lg = 16;

  /// 20 — large/feature cards
  static const double xl = 20;

  /// 28 — bottom sheets, modals
  static const double xxl = 28;

  /// fully rounded — circular pills & avatars
  static const double pill = 999;

  static BorderRadius get brSm => BorderRadius.circular(sm);
  static BorderRadius get brMd => BorderRadius.circular(md);
  static BorderRadius get brLg => BorderRadius.circular(lg);
  static BorderRadius get brXl => BorderRadius.circular(xl);
  static BorderRadius get brPill => BorderRadius.circular(pill);

  /// Top-rounded radius for bottom sheets.
  static const BorderRadius sheet = BorderRadius.vertical(
    top: Radius.circular(xxl),
  );
}

/// Motion durations & curves. Subtle, consistent, never distracting.
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration base = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 360);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutBack;
}

/// Standard page gutters used by [SellerScaffold] and list views.
abstract final class AppInsets {
  static const double page = AppSpace.md;

  static const EdgeInsets pageH = EdgeInsets.symmetric(horizontal: AppSpace.md);

  /// Page content padding that leaves room for the floating bottom nav bar.
  static const EdgeInsets pageWithNav = EdgeInsets.fromLTRB(
    AppSpace.md,
    AppSpace.md,
    AppSpace.md,
    96,
  );
}

/// A tiny, const-friendly spacer. Cleaner than scattering [SizedBox]es.
///
/// ```dart
/// const Gap(AppSpace.md)            // vertical or horizontal (square)
/// const Gap.h(AppSpace.lg)          // horizontal only
/// const Gap.v(AppSpace.xl)          // vertical only
/// ```
class Gap extends StatelessWidget {
  final double size;
  final Axis? axis;

  const Gap(this.size, {super.key}) : axis = null;
  const Gap.h(this.size, {super.key}) : axis = Axis.horizontal;
  const Gap.v(this.size, {super.key}) : axis = Axis.vertical;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: axis == Axis.vertical ? null : size,
      height: axis == Axis.horizontal ? null : size,
    );
  }
}
