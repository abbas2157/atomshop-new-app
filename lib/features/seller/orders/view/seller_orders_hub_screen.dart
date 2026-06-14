import 'package:atompro/features/seller/core/design/design.dart';
import 'package:atompro/features/seller/core/widgets/widgets.dart';
import 'package:atompro/features/seller/custom_orders/view/seller_custom_orders_screen.dart';
import 'package:atompro/features/seller/website_orders/view/seller_website_orders_screen.dart';
import 'package:flutter/material.dart';

/// Orders hub — switches between Custom and Standard orders.
/// Lives inside the shell IndexedStack, so it inherits [SellerThemeScope].
class SellerOrdersHubScreen extends StatelessWidget {
  const SellerOrdersHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;

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
                  tabs: const [
                    Tab(text: 'My Area'),
                    Tab(text: 'Website Orders'),
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
