import 'package:flutter/material.dart';

import '../design/design.dart';

/// A soft, rounded container holding a single icon — the recurring "icon box"
/// that appears in headers, list rows and stat cards. Tinted from a [SellerTone].
class SellerIconBadge extends StatelessWidget {
  final IconData icon;
  final SellerTone? tone;
  final double size;
  final double iconSize;
  final double radius;

  const SellerIconBadge({
    super.key,
    required this.icon,
    this.tone,
    this.size = 44,
    this.iconSize = 22,
    this.radius = AppRadius.md,
  });

  @override
  Widget build(BuildContext context) {
    final t = tone ?? context.sellerColors.accentTone;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: t.bg,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon, size: iconSize, color: t.fg),
    );
  }
}
