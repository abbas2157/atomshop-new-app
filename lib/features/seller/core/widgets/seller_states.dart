import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../design/design.dart';
import 'seller_button.dart';
import 'seller_icon_badge.dart';

/// A calm, modern empty state — soft icon, a clear message, optional action.
class SellerEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SellerEmptyState({
    super.key,
    this.icon = Icons.inbox_rounded,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final text = context.sellerText;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SellerIconBadge(
              icon: icon,
              size: 64,
              iconSize: 30,
              radius: AppRadius.xl,
            ),
            const Gap.v(AppSpace.md),
            Text(title, textAlign: TextAlign.center, style: text.titleSm),
            if (message != null) ...[
              const Gap.v(AppSpace.xs),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: text.bodySm,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const Gap.v(AppSpace.lg),
              SellerButton(
                label: actionLabel!,
                onPressed: onAction,
                expand: false,
                size: SellerButtonSize.small,
                icon: Icons.add_rounded,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A friendly error state with a retry affordance.
class SellerErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const SellerErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SellerIconBadge(
              icon: Icons.error_outline_rounded,
              tone: c.dangerTone,
              size: 64,
              iconSize: 30,
              radius: AppRadius.xl,
            ),
            const Gap.v(AppSpace.md),
            Text('Something went wrong', style: text.titleSm),
            const Gap.v(AppSpace.xs),
            Text(message, textAlign: TextAlign.center, style: text.bodySm),
            if (onRetry != null) ...[
              const Gap.v(AppSpace.lg),
              SellerButton.secondary(
                label: 'Try again',
                onPressed: onRetry,
                expand: false,
                size: SellerButtonSize.small,
                icon: Icons.refresh_rounded,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A shimmering placeholder block — compose these into skeleton screens.
class SellerSkeleton extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const SellerSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.radius = AppRadius.sm,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: c.isDark ? c.surfaceAlt : Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Wraps skeleton content in a brightness-aware shimmer sweep.
class SellerShimmer extends StatelessWidget {
  final Widget child;
  const SellerShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    return Shimmer.fromColors(
      baseColor: c.isDark ? c.surfaceAlt : c.surfaceMuted,
      highlightColor: c.isDark ? c.surfaceMuted : Colors.white,
      period: const Duration(milliseconds: 1300),
      child: child,
    );
  }
}

/// A ready-made skeleton list of card-shaped rows.
class SellerListSkeleton extends StatelessWidget {
  final int count;
  final double itemHeight;

  const SellerListSkeleton({super.key, this.count = 6, this.itemHeight = 84});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    return SellerShimmer(
      child: ListView.separated(
        padding: AppInsets.pageWithNav,
        // Self-sizing so the skeleton is safe in any container (Expanded,
        // Column, or a parent scrollable) without an unbounded-height crash.
        shrinkWrap: true,
        primary: false,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        separatorBuilder: (_, _) => const Gap.v(AppSpace.sm),
        itemBuilder: (_, _) => Container(
          height: itemHeight,
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: AppRadius.brLg,
          ),
        ),
      ),
    );
  }
}
