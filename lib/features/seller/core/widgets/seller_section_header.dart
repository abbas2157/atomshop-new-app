import 'package:flutter/material.dart';

import '../design/design.dart';

/// A consistent section header: optional eyebrow/overline, a title, and an
/// optional trailing action (e.g. "See all"). Gives every screen the same
/// rhythm of titled, bounded content blocks.
class SellerSectionHeader extends StatelessWidget {
  final String title;
  final String? overline;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;

  const SellerSectionHeader({
    super.key,
    required this.title,
    this.overline,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (overline != null) ...[
                Text(overline!.toUpperCase(), style: text.overline),
                const Gap.v(AppSpace.xxs - 2),
              ],
              Text(title, style: text.titleSm),
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onAction,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionLabel!,
                  style: text.labelSm.copyWith(
                    color: c.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (actionIcon != null) ...[
                  const Gap.h(2),
                  Icon(actionIcon, size: 16, color: c.accent),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
