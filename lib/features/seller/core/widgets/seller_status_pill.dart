import 'package:flutter/material.dart';

import '../design/design.dart';

/// A compact status badge with a leading dot. Colour is resolved centrally
/// from the status text via [SellerStatus], so statuses read consistently
/// across leads, orders, instalments, customers and the dashboard.
class SellerStatusPill extends StatelessWidget {
  final String label;

  /// Override the auto-resolved tone (rarely needed).
  final SellerTone? tone;

  /// Hide the leading status dot.
  final bool showDot;
  final bool dense;

  const SellerStatusPill({
    super.key,
    required this.label,
    this.tone,
    this.showDot = true,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final t = tone ?? SellerStatus.toneFor(label, c);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? AppSpace.xs : AppSpace.sm,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: t.bg,
        borderRadius: AppRadius.brPill,
        border: Border.all(color: t.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: t.fg, shape: BoxShape.circle),
            ),
            const Gap.h(AppSpace.xs - 2),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: dense ? 11 : 12,
                height: 1.1,
                fontWeight: FontWeight.w700,
                color: t.fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
