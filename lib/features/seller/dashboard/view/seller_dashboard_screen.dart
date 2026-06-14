// ============================================================
//  seller_dashboard_screen.dart  —  v4  (Action-first Home)
//
//  Home is now the seller's command center, not a report. It
//  leads with "what needs attention right now" (balanced across
//  leads, orders and dues), quick create/do actions, a condensed
//  KPI snapshot, and recent activity. Analytics moved to the
//  Insights section; account/settings live behind the header
//  avatar. Business logic & data model unchanged.
// ============================================================

import 'package:atompro/core/seller_plan_upgrade_exception.dart';
import 'package:atompro/features/seller/core/design/design.dart';
import 'package:atompro/features/seller/core/widgets/widgets.dart';
import 'package:atompro/features/seller/custom_orders/view/seller_custom_orders_screen.dart';
import 'package:atompro/features/seller/profile/viewmodel/seller_profile_viewmodel.dart';
import 'package:atompro/features/seller/dashboard/model/seller_dashboard_model.dart';
import 'package:atompro/features/seller/dashboard/viewmodel/seller_dashboard_viewmodel.dart';
import 'package:atompro/features/seller/instalments/view/seller_instalments_screen.dart';
import 'package:atompro/features/seller/profile/view/seller_profile_screen.dart';
import 'package:atompro/features/seller/subscription/viewmodel/seller_subscription_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tab indices the shell owns, used for cross-section deep links.
class SellerTab {
  static const home = 0;
  static const leads = 1;
  static const orders = 2;
  static const customers = 3;
  static const reports = 4;
}

class SellerDashboardScreen extends ConsumerWidget {
  /// Switch the shell's active tab (deep-link from action center / quick actions).
  final void Function(int index)? onNavigateToTab;

  const SellerDashboardScreen({super.key, this.onNavigateToTab});

  static const _query = SellerDashboardQuery();

  void _go(int index) => onNavigateToTab?.call(index);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.sellerColors;
    final bundle = ref.watch(sellerDashboardProvider(_query));
    final pictureUrl = ref.watch(sellerProfileBundleProvider).asData?.value.profile.profilePictureUrl;
    final hasMarketing = ref.watch(sellerSubscriptionProvider).asData?.value.plan?.featureMarketing ?? false;

    return Scaffold(
      backgroundColor: c.canvas,
      body: bundle.when(
        loading: () => const _HomeSkeleton(),
        error: (e, _) => SafeArea(
          child: e is SellerPlanUpgradeException
              ? SellerPlanGateState(exception: e)
              : SellerErrorState(
                  message: e.toString().replaceFirst('Exception: ', ''),
                  onRetry: () => ref.invalidate(sellerDashboardProvider(_query)),
                ),
        ),
        data: (data) {
          final d = data.dashboard;

          return Column(
            children: [
              SellerGradientHeader(
                leading: GestureDetector(
                  onTap: () =>
                      context.pushSeller(const SellerProfileScreen()),
                  child: SellerMonogram(name: d.businessName, imageUrl: pictureUrl),
                ),
                title: d.businessName,
                subtitle: 'Hi, ${d.userName}',
                actions: const [
                  SellerNotificationBell(),
                ],
              ),
              Expanded(
                child: RefreshIndicator(
                  color: c.accent,
                  backgroundColor: c.surface,
                  onRefresh: () async {
                    ref.invalidate(sellerDashboardProvider(_query));
                    await ref.read(sellerDashboardProvider(_query).future);
                  },
                  child: ListView(
                    padding: AppInsets.pageWithNav,
                    children: [
                      // ── Welcome ─────────────────────────────────
                      _WelcomeBanner(userName: d.userName),
                      const Gap.v(AppSpace.lg),

                      // ── Snapshot ────────────────────────────────
                      const SellerSectionHeader(
                        title: 'Snapshot',
                      ),
                      const Gap.v(AppSpace.sm),
                      SellerGrid(
                        children: [
                          SellerKpiCard(
                            label: 'Sales',
                            value: d.totalCustomSales,
                            icon: Icons.payments_rounded,
                            tone: c.infoTone,
                          ),
                          SellerKpiCard(
                            label: 'Recovered',
                            value: d.totalCustomRecovery,
                            icon: Icons.savings_rounded,
                            tone: c.successTone,
                            caption: '${d.totalCustomRecoveryPercentage} recovered',
                          ),
                          SellerKpiCard(
                            label: 'Outstanding',
                            value: d.outstandingBalance,
                            icon: Icons.account_balance_wallet_rounded,
                            tone: c.warningTone,
                          ),
                          SellerKpiCard(
                            label: 'Customers',
                            value: '${d.totalCustomers}',
                            icon: Icons.groups_rounded,
                            tone: c.violetTone,
                          ),
                        ],
                      ),

                      // ── Quick actions ───────────────────────────
                      const Gap.v(AppSpace.lg),
                      const SellerSectionHeader(title: 'Quick actions'),
                      const Gap.v(AppSpace.sm),
                      SellerGrid(
                        columns: hasMarketing ? 2 : 4,
                        children: [
                          if (!hasMarketing) ...[
                            _QuickAction(
                              icon: Icons.add_box_rounded,
                              label: 'New order',
                              tone: c.accentTone,
                              onTap: () =>
                                  showSellerCreateCustomOrderSheet(context, ref),
                            ),
                            _QuickAction(
                              icon: Icons.groups_rounded,
                              label: 'Customers',
                              tone: c.violetTone,
                              onTap: () => _go(SellerTab.customers),
                            ),
                          ],
                          _QuickAction(
                            icon: Icons.payments_rounded,
                            label: 'Instalments & Dues',
                            tone: c.warningTone,
                            onTap: () => context
                                .pushSeller(const SellerInstalmentsScreen()),
                          ),
                          _QuickAction(
                            icon: Icons.bar_chart_rounded,
                            label: 'Reports',
                            tone: c.infoTone,
                            onTap: () => _go(SellerTab.reports),
                          ),
                        ],
                      ),

                      // ── Needs attention ──────────────────────────
                      const Gap.v(AppSpace.lg),
                      const SellerSectionHeader(
                        overline: 'Today',
                        title: 'Needs attention',
                      ),
                      const Gap.v(AppSpace.sm),
                      _AttentionCard(
                        icon: Icons.account_balance_wallet_rounded,
                        tone: c.warningTone,
                        title: 'Collect dues',
                        value: d.pendingRecoverySum,
                        meta: '${d.pendingRecoveryCount} accounts pending',
                        onTap: () => _go(SellerTab.reports),
                      ),
                      const Gap.v(AppSpace.sm),
                      _AttentionCard(
                        icon: Icons.trending_up_rounded,
                        tone: c.infoTone,
                        title: 'Leads this month',
                        value: '${d.monthlyLeads}',
                        meta:
                            '${d.monthlyWonLeads} won · ${d.monthlyLostLeads} lost',
                        onTap: hasMarketing ? () => _go(SellerTab.leads) : null,
                        locked: !hasMarketing,
                      ),
                      const Gap.v(AppSpace.sm),
                      _AttentionCard(
                        icon: Icons.receipt_long_rounded,
                        tone: c.successTone,
                        title: 'Orders to process',
                        value: '${d.totalCustomOrders}',
                        meta: 'Custom orders pending action',
                        onTap: () => _go(SellerTab.orders),
                      ),

                      // ── Recent orders ───────────────────────────
                      if (d.customOrders.isNotEmpty) ...[
                        const Gap.v(AppSpace.lg),
                        SellerSectionHeader(
                          title: 'Recent orders',
                          actionLabel: 'See all',
                          actionIcon: Icons.chevron_right_rounded,
                          onAction: () => _go(SellerTab.orders),
                        ),
                        const Gap.v(AppSpace.sm),
                        _RecentList(
                          records: d.customOrders.take(4).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Welcome banner ────────────────────────────────────────────
class _WelcomeBanner extends StatelessWidget {
  final String userName;
  const _WelcomeBanner({required this.userName});

  @override
  Widget build(BuildContext context) {
    final text = context.sellerText;
    final c = context.sellerColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back,',
          style: text.bodySm.copyWith(color: c.textSecondary),
        ),
        const Gap.v(2),
        Text(
          userName,
          style: text.titleLg.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

// ── Needs-attention card ──────────────────────────────────────
class _AttentionCard extends StatelessWidget {
  final IconData icon;
  final SellerTone tone;
  final String title;
  final String value;
  final String meta;
  final VoidCallback? onTap;
  final bool locked;

  const _AttentionCard({
    required this.icon,
    required this.tone,
    required this.title,
    required this.value,
    required this.meta,
    required this.onTap,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;

    return SellerCard(
      onTap: onTap,
      accentEdge: tone.fg,
      child: Row(
        children: [
          SellerIconBadge(icon: icon, tone: tone),
          const Gap.h(AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.bodySm),
                const Gap.v(2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleMd,
                ),
                const Gap.v(2),
                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.caption,
                ),
              ],
            ),
          ),
          const Gap.h(AppSpace.xs),
          locked
              ? Icon(Icons.lock_outline_rounded, size: 16, color: c.textTertiary)
              : Icon(Icons.chevron_right_rounded, size: 20, color: c.textTertiary),
        ],
      ),
    );
  }
}

// ── Quick action tile ─────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final SellerTone tone;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.tone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = context.sellerText;
    return SellerCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpace.sm,
        horizontal: AppSpace.xs,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SellerIconBadge(icon: icon, tone: tone, size: 40, iconSize: 20),
          const Gap.v(AppSpace.xs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: text.caption.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ── Recent activity list ──────────────────────────────────────
class _RecentList extends StatelessWidget {
  final List<SellerDashboardRecord> records;
  const _RecentList({required this.records});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;

    return SellerCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < records.length; i++) ...[
            if (i > 0) Divider(color: c.divider, height: 1, indent: AppSpace.md),
            Padding(
              padding: const EdgeInsets.all(AppSpace.md),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          records[i].title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodyLg.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const Gap.v(2),
                        Text(
                          records[i].subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySm,
                        ),
                      ],
                    ),
                  ),
                  const Gap.h(AppSpace.sm),
                  SellerStatusPill(label: records[i].badge, dense: true),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Loading skeleton ──────────────────────────────────────────
class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    return Column(
      children: [
        Container(
          height: 120,
          decoration: BoxDecoration(
            gradient: c.headerGradient,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(AppRadius.xxl),
            ),
          ),
        ),
        const Gap.v(AppSpace.md),
        Expanded(
          child: SellerShimmer(
            child: ListView(
              padding: AppInsets.pageWithNav,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (var i = 0; i < 3; i++) ...[
                  _box(c, 76),
                  const Gap.v(AppSpace.sm),
                ],
                const Gap.v(AppSpace.sm),
                Row(
                  children: [
                    Expanded(child: _box(c, 110)),
                    const Gap.h(AppSpace.sm),
                    Expanded(child: _box(c, 110)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _box(SellerColors c, double h) => Container(
        height: h,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: AppRadius.brLg,
        ),
      );
}

