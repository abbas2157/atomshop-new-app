import 'package:atompro/features/seller/core/design/design.dart';
import 'package:atompro/features/seller/core/widgets/widgets.dart';
import 'package:atompro/features/seller/custom_orders/view/seller_custom_orders_screen.dart';
import 'package:atompro/features/seller/custom_orders/viewmodel/seller_custom_orders_viewmodel.dart';
import 'package:atompro/features/seller/website_orders/view/seller_website_orders_screen.dart';
import 'package:atompro/features/seller/website_orders/viewmodel/seller_website_orders_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Orders hub — switches between Custom (My Area) and Website orders.
/// Displays live order counts in each tab label.
class SellerOrdersHubScreen extends ConsumerWidget {
  const SellerOrdersHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.sellerColors;
    final text = context.sellerText;

    final myAreaTotal =
        ref.watch(sellerMyAreaOrdersTotalProvider).whenOrNull(data: (v) => v);
    final websiteTotal =
        ref.watch(sellerWebsiteOrdersTotalProvider).whenOrNull(data: (v) => v);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: c.canvas,
        body: Column(
          children: [
            // ── Gradient header ──────────────────────────────────────────
            SellerGradientHeader(
              automaticallyImplyLeading: false,
              leading: SellerIconBadge(
                icon: Icons.receipt_long_rounded,
                tone: SellerTone(
                  fg: Colors.white,
                  bg: Colors.white.withValues(alpha: 0.16),
                  border: Colors.white.withValues(alpha: 0.18),
                ),
                size: 44,
                iconSize: 24,
              ),
              title: 'Orders',
              subtitle: 'Custom & website orders',
              actions: [
                const SellerNotificationBell(),
                const SellerHeaderProfileButton(),
              ],
            ),

            // ── Tab switcher (My Area / Website Orders) ──────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.md,
                AppSpace.md,
                AppSpace.md,
                AppSpace.sm,
              ),
              child: Container(
                height: 44,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: c.surfaceMuted,
                  borderRadius: AppRadius.brMd,
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    boxShadow: c.cardShadow,
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: c.accent,
                  unselectedLabelColor: c.textSecondary,
                  labelStyle:
                      text.labelSm.copyWith(fontWeight: FontWeight.w700),
                  unselectedLabelStyle: text.labelSm,
                  tabs: [
                    _CountTab(
                      label: 'My Area',
                      count: myAreaTotal,
                    ),
                    _CountTab(
                      label: 'Website Orders',
                      count: websiteTotal,
                    ),
                  ],
                ),
              ),
            ),

            const Expanded(
              child: TabBarView(
                children: [
                  SellerCustomOrdersScreen(),
                  SellerWebsiteOrdersScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountTab extends StatelessWidget {
  final String label;
  final int? count;

  const _CountTab({required this.label, this.count});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label),
          if (count != null && count! > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: c.accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count!.toString(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: c.onAccent,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
