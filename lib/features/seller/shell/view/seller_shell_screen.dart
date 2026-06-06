import 'package:atompro/features/seller/core/design/design.dart';
import 'package:atompro/features/seller/core/widgets/widgets.dart';
import 'package:atompro/features/seller/custom_orders/view/seller_custom_orders_screen.dart';
import 'package:atompro/features/seller/customers/view/seller_customers_screen.dart';
import 'package:atompro/features/seller/dashboard/view/seller_dashboard_screen.dart';
import 'package:atompro/features/seller/finance/view/seller_finance_hub_screen.dart';
import 'package:atompro/features/seller/insights/view/seller_insights_screen.dart';
import 'package:atompro/features/seller/leads/view/seller_leads_screen.dart';
import 'package:atompro/features/seller/orders/view/seller_orders_hub_screen.dart';
import 'package:atompro/features/seller/standard_orders/view/seller_standard_orders_screen.dart';
import 'package:atompro/features/seller/subscription/model/seller_subscription_model.dart';
import 'package:atompro/features/seller/subscription/view/seller_subscription_screen.dart';
import 'package:atompro/features/seller/subscription/viewmodel/seller_subscription_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ─────────────────────────────────────────────────────────────────────────
///  Seller Shell — workflow-oriented navigation.
///
///  5 sections (Home · Leads · Orders · Finance · Insights), a global Create
///  action, and account/settings behind the Home header avatar. Wraps the
///  whole experience in [SellerThemeScope] for unified, dark-mode-capable theming.
/// ─────────────────────────────────────────────────────────────────────────
class SellerShellScreen extends ConsumerStatefulWidget {
  const SellerShellScreen({super.key});

  @override
  ConsumerState<SellerShellScreen> createState() => _SellerShellScreenState();
}

class _SellerShellScreenState extends ConsumerState<SellerShellScreen> {
  int _index = 0;

  static const _navItems = <_NavItem>[
    _NavItem(label: 'Home', icon: Icons.space_dashboard_rounded),
    _NavItem(label: 'Leads', icon: Icons.trending_up_rounded),
    _NavItem(label: 'Orders', icon: Icons.receipt_long_rounded),
    _NavItem(label: 'Finance', icon: Icons.account_balance_wallet_rounded),
    _NavItem(label: 'Insights', icon: Icons.insights_rounded),
  ];

  late final List<Widget> _pages = [
    SellerDashboardScreen(onNavigateToTab: _select),
    const SellerLeadsScreen(),
    const SellerOrdersHubScreen(),
    const SellerFinanceHubScreen(),
    const SellerInsightsScreen(),
  ];

  void _select(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return SellerThemeScope(
      child: Builder(
        builder: (context) {
          final c = context.sellerColors;
          // ── Subscription access gate ──────────────────────────────────
          // No plan → full access. Plan assigned but no payment confirmed →
          // locked on the subscription page (fail-open on network error; the
          // backend enforces the same rule on every API call).
          final gate = ref.watch(sellerSubscriptionProvider);
          return gate.when(
            loading: () => Scaffold(
              backgroundColor: c.canvas,
              body: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: c.accent,
                  ),
                ),
              ),
            ),
            error: (_, _) => _buildShell(context, c),
            data: (sub) {
              final locked =
                  sub.hasActivePlan && !sub.payments.any((p) => p.isReceived);
              if (!locked) return _buildShell(context, c);
              final underReview = _hasPendingPayment(sub);
              return SellerSubscriptionScreen(
                locked: true,
                underReview: underReview,
              );
            },
          );
        },
      ),
    );
  }

  bool _hasPendingPayment(SellerSubscriptionData sub) {
    if (sub.payments.any((p) => p.status.toLowerCase() == 'pending')) {
      return true;
    }
    final plan = sub.plan;
    return plan != null &&
        (plan.monthly.isPending || plan.commissionAction.isPending);
  }

  Widget _buildShell(BuildContext context, SellerColors c) {
    return Scaffold(
      backgroundColor: c.canvas,
      extendBody: true,
      body: IndexedStack(index: _index, children: _pages),
      // Orders surfaces its own create FAB; hide the global one there to
      // avoid two stacked FABs.
      floatingActionButton:
          _index == 2 ? null : _CreateButton(onTap: () => _showCreate(context)),
      bottomNavigationBar: _FloatingNavBar(
        items: _navItems,
        selectedIndex: _index,
        onTap: _select,
      ),
    );
  }

  // ── Global quick-create ────────────────────────────────────────────────
  void _showCreate(BuildContext context) {
    final dark = context.sellerIsDark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Theme(
        data: dark ? SellerTheme.dark : SellerTheme.light,
        child: Builder(
          builder: (sheetContext) {
            final c = sheetContext.sellerColors;
            final text = sheetContext.sellerText;
            return Container(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: AppRadius.sheet,
              ),
              padding: EdgeInsets.fromLTRB(
                AppSpace.lg,
                AppSpace.sm,
                AppSpace.lg,
                AppSpace.lg + MediaQuery.of(sheetContext).padding.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: c.borderStrong,
                        borderRadius: AppRadius.brPill,
                      ),
                    ),
                  ),
                  const Gap.v(AppSpace.md),
                  Text('Create', style: text.titleMd),
                  const Gap.v(AppSpace.md),
                  _CreateAction(
                    icon: Icons.receipt_long_rounded,
                    tone: c.accentTone,
                    title: 'New custom order',
                    subtitle: 'Installment deal with a buyer',
                    onTap: () {
                      Navigator.pop(sheetContext);
                      showSellerCreateCustomOrderSheet(context, ref);
                    },
                  ),
                  _CreateAction(
                    icon: Icons.shopping_bag_rounded,
                    tone: c.infoTone,
                    title: 'New standard order',
                    subtitle: 'Regular platform order',
                    onTap: () {
                      Navigator.pop(sheetContext);
                      showSellerCreateStandardOrderSheet(context, ref);
                    },
                  ),
                  _CreateAction(
                    icon: Icons.person_add_alt_1_rounded,
                    tone: c.violetTone,
                    title: 'New customer',
                    subtitle: 'Add a buyer to your book',
                    onTap: () {
                      Navigator.pop(sheetContext);
                      showSellerAddCustomerSheet(context, ref);
                    },
                  ),
                  _CreateAction(
                    icon: Icons.payments_rounded,
                    tone: c.warningTone,
                    title: 'Collect a payment',
                    subtitle: 'Go to dues to record an instalment',
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _select(3);
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  const _NavItem({required this.label, required this.icon});
}

// ── Global create FAB ────────────────────────────────────────────────────
class _CreateButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CreateButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 70),
      child: Material(
        color: c.accent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: c.accent.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(Icons.add_rounded, color: c.onAccent, size: 28),
          ),
        ),
      ),
    );
  }
}

class _CreateAction extends StatelessWidget {
  final IconData icon;
  final SellerTone tone;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CreateAction({
    required this.icon,
    required this.tone,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
        child: Row(
          children: [
            SellerIconBadge(icon: icon, tone: tone),
            const Gap.h(AppSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.titleSm),
                  const Gap.v(2),
                  Text(subtitle, style: text.bodySm),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: c.textTertiary),
          ],
        ),
      ),
    );
  }
}

// ── Floating bottom nav ──────────────────────────────────────────────────
class _FloatingNavBar extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _FloatingNavBar({
    required this.items,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpace.md,
        0,
        AppSpace.md,
        bottomInset > 0 ? bottomInset : AppSpace.md,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.xs,
          vertical: AppSpace.xs + 2,
        ),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: AppRadius.brXl,
          border: Border.all(color: c.border, width: 1),
          boxShadow: c.floatingShadow,
        ),
        child: Row(
          children: List.generate(items.length, (i) {
            return Expanded(
              child: _NavButton(
                item: items[i],
                selected: i == selectedIndex,
                onTap: () => onTap(i),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: AppMotion.base,
            curve: AppMotion.standard,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.sm,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: selected ? c.accentSurface : Colors.transparent,
              borderRadius: AppRadius.brPill,
            ),
            child: Icon(
              item.icon,
              size: 22,
              color: selected ? c.accent : c.textTertiary,
            ),
          ),
          const Gap.v(AppSpace.xxs),
          AnimatedDefaultTextStyle(
            duration: AppMotion.fast,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 10.5,
              height: 1,
              fontWeight: FontWeight.w700,
              color: selected ? c.accent : c.textTertiary,
            ),
            child: Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
