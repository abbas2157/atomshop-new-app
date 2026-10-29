import 'package:flutter/material.dart';

import 'atom_tokens.dart';

/// Type scale for app v2 (Plus Jakarta Sans). Sizes are logical pixels; the
/// app clamps the system text scale in [AtomApp] so layouts never break.
abstract final class AtomText {
  static const family = 'PlusJakartaSans';

  static const title = TextStyle(fontFamily: family, fontSize: 24, height: 1.15, fontWeight: FontWeight.w800, letterSpacing: -0.6, color: AtomColors.ink);
  static const heading = TextStyle(fontFamily: family, fontSize: 18, height: 1.25, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: AtomColors.ink);
  static const subheading = TextStyle(fontFamily: family, fontSize: 15, height: 1.3, fontWeight: FontWeight.w700, color: AtomColors.ink);
  static const body = TextStyle(fontFamily: family, fontSize: 14, height: 1.5, fontWeight: FontWeight.w500, color: AtomColors.body);
  static const small = TextStyle(fontFamily: family, fontSize: 12, height: 1.4, fontWeight: FontWeight.w600, color: AtomColors.muted);
  static const label = TextStyle(fontFamily: family, fontSize: 14, fontWeight: FontWeight.w700, color: AtomColors.ink);
  static const button = TextStyle(fontFamily: family, fontSize: 15, fontWeight: FontWeight.w700);
  static const eyebrow = TextStyle(fontFamily: family, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.6, color: AtomColors.primary);
  static const amount = TextStyle(fontFamily: family, fontSize: 16, fontWeight: FontWeight.w800, color: AtomColors.primary);
}
