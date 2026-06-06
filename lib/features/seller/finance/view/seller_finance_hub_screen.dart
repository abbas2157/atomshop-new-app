import 'package:atompro/features/seller/core/design/design.dart';
import 'package:atompro/features/seller/core/widgets/widgets.dart';
import 'package:atompro/features/seller/dashboard/model/seller_dashboard_model.dart';
import 'package:atompro/features/seller/dashboard/viewmodel/seller_dashboard_viewmodel.dart';
import 'package:atompro/features/seller/fee_charge/view/seller_fee_charge_screen.dart';
import 'package:atompro/features/seller/instalments/view/seller_instalments_screen.dart';
import 'package:atompro/features/seller/investments/view/seller_investments_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Finance — the money hub. Consolidates the previously scattered Dues,
/// Fee charges and Investments under one workflow-oriented section, led by the
/// numbers that matter: outstanding, recovered, and pending recovery.
class SellerFinanceHubScreen extends ConsumerWidget {
  const SellerFinanceHubScreen({super.key});

  static const _query = SellerDashboardQuery();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.sellerColors;
    final bundle = ref.watch(sellerDashboardProvider(_query));

    return Scaffold(
      backgroundColor: c.canvas,
      body: Column(
        children: [
          SellerGradientHeader(
            leading: const _HeaderGlyph(icon: Icons.account_balance_rounded),
            title: 'Finance',
            subtitle: 'Dues, fees & investments',
            actions: [
              SellerHeaderIconButton(
                icon: Icons.refresh_rounded,
                tooltip: 'Refresh',
                onTap: () => ref.invalidate(sellerDashboardProvider(_query)),
              ),
            ],
          ),
          Expanded(
            child: bundle.when(
              loading: () => const SellerListSkeleton(),
              error: (e, _) => SellerErrorState(
                message: e.toString().replaceFirst('Exception: ', ''),
                onRetry: () => ref.invalidate(sellerDashboardProvider(_query)),
              ),
              data: (data) => RefreshIndicator(
                color: c.accent,
                backgroundColor: c.surface,
                onRefresh: () async {
                  ref.invalidate(sellerDashboardProvider(_query));
                  await ref.read(sellerDashboardProvider(_query).future);
                },
                child: _Body(d: data.dashboard),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final SellerDashboardModel d;
  const _Body({required this.d});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;

    return ListView(
      padding: AppInsets.pageWithNav,
      children: [
        SellerGrid(
          children: [
            SellerKpiCard(
              label: 'Outstanding',
              value: d.outstandingBalance,
              icon: Icons.account_balance_wallet_rounded,
              tone: c.warningTone,
            ),
            SellerKpiCard(
              label: 'Recovered',
              value: d.totalCustomRecoveryAll,
              icon: Icons.savings_rounded,
              tone: c.successTone,
              caption: '${d.totalCustomRecoveryPercentageAll} all-time',
            ),
          ],
        ),
        const Gap.v(AppSpace.lg),
        const SellerSectionHeader(overline: 'Manage', title: 'Money'),
        const Gap.v(AppSpace.sm),
        _NavCard(
          icon: Icons.receipt_long_rounded,
          tone: c.warningTone,
          title: 'Dues & instalments',
          subtitle:
              '${d.pendingRecoveryCount} pending · ${d.pendingRecoverySum} to collect',
          onTap: () => context.pushSeller(const SellerInstalmentsScreen()),
        ),
        const Gap.v(AppSpace.sm),
        _NavCard(
          icon: Icons.request_quote_rounded,
          tone: c.infoTone,
          title: 'Fee charges',
          subtitle: 'Platform fees & payments',
          onTap: () => context.pushSeller(const SellerFeeChargeScreen()),
        ),
        const Gap.v(AppSpace.sm),
        _NavCard(
          icon: Icons.trending_up_rounded,
          tone: c.violetTone,
          title: 'Investments',
          subtitle: 'Capital, returns & status',
          onTap: () => context.pushSeller(const SellerInvestmentsScreen()),
        ),
      ],
    );
  }
}

class _NavCard extends StatelessWidget {
  final IconData icon;
  final SellerTone tone;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavCard({
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

    return SellerCard(
      onTap: onTap,
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
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySm,
                ),
              ],
            ),
          ),
          const Gap.h(AppSpace.xs),
          Icon(Icons.chevron_right_rounded, size: 20, color: c.textTertiary),
        ],
      ),
    );
  }
}

class _HeaderGlyph extends StatelessWidget {
  final IconData icon;
  const _HeaderGlyph({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: AppRadius.brMd,
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}
