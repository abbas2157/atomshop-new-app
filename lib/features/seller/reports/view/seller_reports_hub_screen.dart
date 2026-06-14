import 'package:atompro/features/seller/core/design/design.dart';
import 'package:atompro/features/seller/core/widgets/widgets.dart';
import 'package:atompro/features/seller/dashboard/viewmodel/seller_dashboard_viewmodel.dart';
import 'package:atompro/features/seller/instalments/view/seller_instalments_screen.dart';
import 'package:atompro/features/seller/reports/view/reports/seller_aging_report_screen.dart';
import 'package:atompro/features/seller/reports/view/reports/seller_collection_report_screen.dart';
import 'package:atompro/features/seller/reports/view/reports/seller_customer_ledger_screen.dart';
import 'package:atompro/features/seller/reports/view/reports/seller_defaulters_screen.dart';
import 'package:atompro/features/seller/reports/view/reports/seller_lead_funnel_screen.dart';
import 'package:atompro/features/seller/reports/view/reports/seller_offers_report_screen.dart';
import 'package:atompro/features/seller/reports/view/reports/seller_order_summary_screen.dart';
import 'package:atompro/features/seller/reports/view/reports/seller_outstanding_screen.dart';
import 'package:atompro/features/seller/reports/view/reports/seller_payment_history_screen.dart';
import 'package:atompro/features/seller/reports/view/reports/seller_recovery_sheet_screen.dart';
import 'package:atompro/features/seller/reports/view/reports/seller_sales_revenue_screen.dart';
import 'package:atompro/features/seller/reports/view/reports/seller_upcoming_dues_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Category model ───────────────────────────────────────────────────────────
enum _ReportCategory { recovery, collection, sales, leads, customer }

extension _ReportCategoryLabel on _ReportCategory {
  String get label {
    switch (this) {
      case _ReportCategory.recovery:   return 'Recovery';
      case _ReportCategory.collection: return 'Collection';
      case _ReportCategory.sales:      return 'Sales';
      case _ReportCategory.leads:      return 'Leads';
      case _ReportCategory.customer:   return 'Customer';
    }
  }

  IconData get icon {
    switch (this) {
      case _ReportCategory.recovery:   return Icons.shield_outlined;
      case _ReportCategory.collection: return Icons.payments_outlined;
      case _ReportCategory.sales:      return Icons.trending_up_rounded;
      case _ReportCategory.leads:      return Icons.filter_alt_outlined;
      case _ReportCategory.customer:   return Icons.groups_outlined;
    }
  }
}

// ─── Report tile definition ───────────────────────────────────────────────────
class _ReportDef {
  final _ReportCategory category;
  final IconData icon;
  final String title;
  final String desc;
  final Widget Function(BuildContext) builder;

  const _ReportDef({
    required this.category,
    required this.icon,
    required this.title,
    required this.desc,
    required this.builder,
  });
}

// ─── All report definitions ───────────────────────────────────────────────────
final _reports = <_ReportDef>[
  _ReportDef(
    category: _ReportCategory.recovery,
    icon: Icons.shield_outlined,
    title: 'Recovery Sheet',
    desc: 'Instalment plans with paid/remaining/overdue breakdown',
    builder: (_) => const SellerRecoverySheetScreen(),
  ),
  _ReportDef(
    category: _ReportCategory.recovery,
    icon: Icons.account_balance_outlined,
    title: 'Customer Ledger',
    desc: 'Debit/credit statement with running balance',
    builder: (_) => const SellerCustomerLedgerScreen(),
  ),
  _ReportDef(
    category: _ReportCategory.recovery,
    icon: Icons.schedule_outlined,
    title: 'Aging Report',
    desc: 'Overdue instalments bucketed 0–30, 31–60, 61–90, 90+ days',
    builder: (_) => const SellerAgingReportScreen(),
  ),
  _ReportDef(
    category: _ReportCategory.recovery,
    icon: Icons.event_available_outlined,
    title: 'Upcoming Dues',
    desc: 'Instalments due in the next 7, 15, or 30 days',
    builder: (_) => const SellerUpcomingDuesScreen(),
  ),
  _ReportDef(
    category: _ReportCategory.recovery,
    icon: Icons.warning_amber_rounded,
    title: 'Defaulter List',
    desc: 'Customers who missed 2 or more consecutive instalments',
    builder: (_) => const SellerDefaultersScreen(),
  ),
  _ReportDef(
    category: _ReportCategory.collection,
    icon: Icons.payments_outlined,
    title: 'Collection Report',
    desc: 'Payments received grouped by day or month',
    builder: (_) => const SellerCollectionReportScreen(),
  ),
  _ReportDef(
    category: _ReportCategory.sales,
    icon: Icons.trending_up_rounded,
    title: 'Sales & Revenue',
    desc: 'Monthly sales with commission and net revenue',
    builder: (_) => const SellerSalesRevenueScreen(),
  ),
  _ReportDef(
    category: _ReportCategory.sales,
    icon: Icons.receipt_long_outlined,
    title: 'Order Summary',
    desc: 'All orders in a date range by status',
    builder: (_) => const SellerOrderSummaryScreen(),
  ),
  _ReportDef(
    category: _ReportCategory.leads,
    icon: Icons.filter_alt_outlined,
    title: 'Lead Funnel',
    desc: 'Lead conversion stages for a date range',
    builder: (_) => const SellerLeadFunnelScreen(),
  ),
  _ReportDef(
    category: _ReportCategory.leads,
    icon: Icons.local_offer_outlined,
    title: 'Offers Report',
    desc: 'Leads with city, area, status, and reason',
    builder: (_) => const SellerOffersReportScreen(),
  ),
  _ReportDef(
    category: _ReportCategory.customer,
    icon: Icons.account_balance_wallet_outlined,
    title: 'Customer Outstanding',
    desc: 'One-line balance summary per customer',
    builder: (_) => const SellerOutstandingScreen(),
  ),
  _ReportDef(
    category: _ReportCategory.customer,
    icon: Icons.history_rounded,
    title: 'Payment History',
    desc: 'Complete payment log for one customer',
    builder: (_) => const SellerPaymentHistoryScreen(),
  ),
];

// ─── Screen ───────────────────────────────────────────────────────────────────
class SellerReportsHubScreen extends ConsumerStatefulWidget {
  const SellerReportsHubScreen({super.key});

  @override
  ConsumerState<SellerReportsHubScreen> createState() =>
      _SellerReportsHubScreenState();
}

class _SellerReportsHubScreenState
    extends ConsumerState<SellerReportsHubScreen> {
  _ReportCategory _selected = _ReportCategory.recovery;

  List<_ReportDef> get _visible =>
      _reports.where((r) => r.category == _selected).toList();

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final bundle = ref.watch(
      sellerDashboardProvider(const SellerDashboardQuery()),
    );
    final navSubtitle = bundle.whenOrNull(
      data: (data) {
        final d = data.dashboard;
        return '${d.pendingRecoveryCount} pending · ${d.pendingRecoverySum} to collect';
      },
    ) ?? 'View all pending instalments';

    return Scaffold(
      backgroundColor: c.canvas,
      body: Column(
        children: [
          SellerGradientHeader(
            leading: const _HeaderGlyph(icon: Icons.bar_chart_rounded),
            title: 'Reports',
            subtitle: 'Finance & analytics',
            actions: const [SellerNotificationBell(), SellerHeaderProfileButton()],
          ),
          // ── Sticky category chips ──────────────────────────────────────
          Container(
            color: c.surface,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.md,
              vertical: AppSpace.sm,
            ),
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _ReportCategory.values.length,
                separatorBuilder: (_, _) => const Gap.h(AppSpace.xs),
                itemBuilder: (_, i) {
                  final cat = _ReportCategory.values[i];
                  final active = cat == _selected;
                  return _CategoryChip(
                    label: cat.label,
                    icon: cat.icon,
                    active: active,
                    onTap: () => setState(() => _selected = cat),
                  );
                },
              ),
            ),
          ),
          Divider(height: 1, color: c.border),
          // ── Scrollable body ────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: AppInsets.pageWithNav,
              children: [
                LayoutBuilder(
                  builder: (_, constraints) {
                    final w = (constraints.maxWidth - AppSpace.sm) / 2;
                    return Wrap(
                      spacing: AppSpace.sm,
                      runSpacing: AppSpace.sm,
                      children: _visible
                          .map((r) => SizedBox(
                                width: w,
                                child: _ReportTile(
                                  def: r,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: r.builder),
                                  ),
                                ),
                              ))
                          .toList(),
                    );
                  },
                ),
                const Gap.v(AppSpace.md),
                Divider(color: c.border),
                const Gap.v(AppSpace.md),
                const SellerSectionHeader(
                    overline: 'Finance', title: 'Instalments & Dues'),
                const Gap.v(AppSpace.sm),
                _FinanceNavCard(
                  icon: Icons.receipt_long_rounded,
                  tone: c.warningTone,
                  title: 'Dues & instalments',
                  subtitle: navSubtitle,
                  onTap: () =>
                      context.pushSeller(const SellerInstalmentsScreen()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Finance nav card ─────────────────────────────────────────────────────────
class _FinanceNavCard extends StatelessWidget {
  final IconData icon;
  final SellerTone tone;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FinanceNavCard({
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

// ─── Category chip ────────────────────────────────────────────────────────────
class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.base,
        curve: AppMotion.standard,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.sm + 2,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: active ? c.accent : c.canvas,
          borderRadius: AppRadius.brPill,
          border: Border.all(color: active ? c.accent : c.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14,
                color: active ? c.onAccent : c.textSecondary),
            const Gap.h(AppSpace.xs),
            Text(
              label,
              style: text.labelSm.copyWith(
                color: active ? c.onAccent : c.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Report tile ──────────────────────────────────────────────────────────────
class _ReportTile extends StatelessWidget {
  final _ReportDef def;
  final VoidCallback onTap;

  const _ReportTile({required this.def, required this.onTap});

  SellerTone _tone(_ReportCategory cat, SellerColors c) {
    switch (cat) {
      case _ReportCategory.recovery:   return c.warningTone;
      case _ReportCategory.collection: return c.successTone;
      case _ReportCategory.sales:      return c.accentTone;
      case _ReportCategory.leads:      return c.infoTone;
      case _ReportCategory.customer:   return c.violetTone;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final tone = _tone(def.category, c);

    return SellerCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SellerIconBadge(icon: def.icon, tone: tone, size: 44, iconSize: 22),
          const Gap.v(AppSpace.sm),
          Text(
            def.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.titleSm.copyWith(fontWeight: FontWeight.w700),
          ),
          const Gap.v(AppSpace.xs),
          Text(
            def.desc,
            style: text.caption.copyWith(color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─── Header glyph ─────────────────────────────────────────────────────────────
class _HeaderGlyph extends StatelessWidget {
  final IconData icon;
  const _HeaderGlyph({required this.icon});

  @override
  Widget build(BuildContext context) => Container(
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
