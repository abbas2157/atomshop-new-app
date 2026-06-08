import 'package:flutter/material.dart';

import '../design/design.dart';

/// The canonical surface in Seller Mode.
///
/// One radius, one border treatment, one shadow language — used for every
/// card, list row and grouped section so the whole app feels unified.
class SellerCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final double radius;

  /// When false the soft drop shadow is omitted (e.g. for nested cards).
  final bool elevated;

  /// Optional coloured accent strip down the leading edge (status emphasis).
  final Color? accentEdge;

  const SellerCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.md),
    this.onTap,
    this.color,
    this.borderColor,
    this.radius = AppRadius.lg,
    this.elevated = true,
    this.accentEdge,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final br = BorderRadius.circular(radius);

    Widget content = Padding(padding: padding, child: child);

    if (accentEdge != null) {
      // A Stack sizes itself from the (non-positioned) content, then lays the
      // strip out to match — unlike IntrinsicHeight, this never needs to probe
      // intrinsic dimensions, so it stays compatible with content that uses
      // LayoutBuilder (e.g. SellerProgressBar) and stays safe inside
      // vertically-unbounded parents (ListView items, Columns).
      content = Stack(
        children: [
          Padding(padding: const EdgeInsets.only(left: 4), child: content),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 4,
            child: Container(color: accentEdge),
          ),
        ],
      );
    }

    final decorated = DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? c.surface,
        borderRadius: br,
        border: Border.all(color: borderColor ?? c.border, width: 1),
        boxShadow: elevated ? c.cardShadow : null,
      ),
      child: ClipRRect(borderRadius: br, child: content),
    );

    if (onTap == null) return decorated;

    return Material(
      color: Colors.transparent,
      borderRadius: br,
      child: InkWell(
        onTap: onTap,
        borderRadius: br,
        splashColor: c.accent.withValues(alpha: 0.06),
        highlightColor: c.accent.withValues(alpha: 0.03),
        child: decorated,
      ),
    );
  }
}
