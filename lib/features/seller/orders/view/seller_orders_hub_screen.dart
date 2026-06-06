import 'package:atompro/features/seller/core/design/design.dart';
import 'package:atompro/features/seller/custom_orders/view/seller_custom_orders_screen.dart';
import 'package:atompro/features/seller/standard_orders/view/seller_standard_orders_screen.dart';
import 'package:flutter/material.dart';

/// Orders hub — switches between Custom and Standard orders.
/// Lives inside the shell IndexedStack, so it inherits [SellerThemeScope].
class SellerOrdersHubScreen extends StatelessWidget {
  const SellerOrdersHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final topInset = MediaQuery.of(context).padding.top;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: c.canvas,
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpace.md,
                topInset + AppSpace.md,
                AppSpace.md,
                AppSpace.sm,
              ),
              child: Row(
                children: [
                  Expanded(child: Text('Orders', style: text.titleLg)),
                ],
              ),
            ),
            Padding(
              padding: AppInsets.pageH,
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
                  labelStyle: text.labelSm.copyWith(fontWeight: FontWeight.w700),
                  unselectedLabelStyle: text.labelSm,
                  tabs: const [
                    Tab(text: 'Custom'),
                    Tab(text: 'Standard'),
                  ],
                ),
              ),
            ),
            const Gap.v(AppSpace.sm),
            const Expanded(
              child: TabBarView(
                children: [
                  SellerCustomOrdersScreen(),
                  SellerStandardOrdersScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
