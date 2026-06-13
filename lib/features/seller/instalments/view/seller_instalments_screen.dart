// ============================================================
//  seller_instalments_screen.dart  —  Instalments & Dues
//
//  List screen for the new KPI-driven instalments contract:
//  global KPI strip, search/status/month/year filters, and
//  paginated order cards with server-computed progress/status.
//  Tapping a card opens the full Order Ledger screen where
//  payments are recorded and invoices are generated.
// ============================================================

import 'package:atompro/core/seller_plan_upgrade_exception.dart';
import 'package:atompro/core/services/snackbar_services.dart';
import 'package:atompro/features/seller/core/design/design.dart';
import 'package:atompro/features/seller/core/services/seller_file_service.dart';
import 'package:atompro/features/seller/core/widgets/widgets.dart';
import 'package:atompro/features/seller/instalments/model/seller_instalments_model.dart';
import 'package:atompro/features/seller/instalments/repository/seller_instalments_repository.dart';
import 'package:atompro/features/seller/instalments/view/seller_instalment_order_screen.dart';
import 'package:atompro/features/seller/instalments/viewmodel/seller_instalments_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Status filter enum ───────────────────────────────────────────────────
enum _FilterStatus { all, active, overdue, completed }

extension _FilterStatusX on _FilterStatus {
  String get label => switch (this) {
    _FilterStatus.all => 'All',
    _FilterStatus.active => 'Active',
    _FilterStatus.overdue => 'Overdue',
    _FilterStatus.completed => 'Completed',
  };

  String get apiValue => switch (this) {
    _FilterStatus.all => 'all',
    _FilterStatus.active => 'active',
    _FilterStatus.overdue => 'overdue',
    _FilterStatus.completed => 'completed',
  };
}

/// The spec's status badge palette is fixed (Active=Blue / Overdue=Red /
/// Completed=Green) — distinct from the generic [SellerStatus.toneFor] which
/// maps both "active" and "complete" to the same success tone.
SellerTone orderStatusTone(String status, SellerColors c) =>
    switch (status.toLowerCase()) {
      'overdue' => c.dangerTone,
      'completed' => c.successTone,
      _ => c.infoTone, // Active (and anything else) → blue
    };

// ═══════════════════════════════════════════════════════════
//  SCREEN
// ═══════════════════════════════════════════════════════════
class SellerInstalmentsScreen extends ConsumerStatefulWidget {
  const SellerInstalmentsScreen({super.key});

  @override
  ConsumerState<SellerInstalmentsScreen> createState() =>
      _SellerInstalmentsScreenState();
}

class _SellerInstalmentsScreenState
    extends ConsumerState<SellerInstalmentsScreen> {
  _FilterStatus _status = _FilterStatus.all;
  int _page = 1;
  String _search = '';
  int? _month;
  int? _year;
  bool _filtersExpanded = false;
  final _searchCtrl = TextEditingController();

  SellerInstalmentsQuery get _query => SellerInstalmentsQuery(
    q: _search,
    filterStatus: _status.apiValue,
    month: _month,
    year: _year,
    page: _page,
  );

  bool get _hasMonthYearFilter => _month != null || _year != null;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _setStatus(_FilterStatus status) {
    if (_status == status) return;
    setState(() {
      _status = status;
      _page = 1;
    });
  }

  void _applyMonthYear({int? month, int? year}) {
    setState(() {
      _month = month;
      _year = year;
      _page = 1;
    });
  }

  void _clearMonthYear() {
    setState(() {
      _month = null;
      _year = null;
      _page = 1;
    });
  }

  Future<void> _openTopupPdf() async {
    try {
      final path = await ref
          .read(sellerInstalmentsRepositoryProvider)
          .downloadTopupPdf();
      await SellerFileService.openLocalFile(path);
    } catch (e) {
      SnackbarService().showErrorSnackBar(_cleanError(e));
    }
  }

  void _openOrder(SellerInstalmentOrderSummary order) {
    context.pushSeller(SellerInstalmentOrderScreen(orderId: order.id));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final state = ref.watch(sellerInstalmentsListProvider(_query));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: c.canvas,
        body: Column(
          children: [
            // ── Header ────────────────────────────────────────────────
            SellerGradientHeader(
              leading: SellerIconBadge(
                icon: Icons.payments_rounded,
                tone: SellerTone(
                  fg: Colors.white,
                  bg: Colors.white.withValues(alpha: 0.18),
                  border: Colors.white.withValues(alpha: 0.2),
                ),
                size: 44,
                iconSize: 22,
                radius: AppRadius.md,
              ),
              title: 'Instalments & Dues',
              subtitle: 'Track recovery and collect payments',
              actions: [
                SellerHeaderIconButton(
                  icon: Icons.picture_as_pdf_outlined,
                  onTap: _openTopupPdf,
                  tooltip: 'Recovery sheet PDF',
                ),
              ],
            ),
            // ── Status tabs ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.md,
                AppSpace.md,
                AppSpace.md,
                AppSpace.xs,
              ),
              child: SellerSegmentedTabs(
                labels: _FilterStatus.values.map((s) => s.label).toList(),
                selectedIndex: _status.index,
                onChanged: (i) => _setStatus(_FilterStatus.values[i]),
              ),
            ),
            // ── Search + month/year filter toggle ────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.md,
                AppSpace.xs,
                AppSpace.md,
                AppSpace.xs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SellerSearchField(
                      controller: _searchCtrl,
                      hint: 'Search by customer, phone, order #…',
                      onChanged: (v) => setState(() {
                        _search = v;
                        _page = 1;
                      }),
                      onClear: () => setState(() {
                        _search = '';
                        _page = 1;
                      }),
                    ),
                  ),
                  const Gap.h(AppSpace.xs),
                  _FilterToggleButton(
                    active: _hasMonthYearFilter,
                    expanded: _filtersExpanded,
                    onTap: () =>
                        setState(() => _filtersExpanded = !_filtersExpanded),
                  ),
                ],
              ),
            ),
            // ── Month / year filter panel ─────────────────────────────
            AnimatedCrossFade(
              duration: AppMotion.base,
              crossFadeState: _filtersExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.md,
                  0,
                  AppSpace.md,
                  AppSpace.xs,
                ),
                child: _MonthYearFilterPanel(
                  month: _month,
                  year: _year,
                  onApply: _applyMonthYear,
                  onClear: _clearMonthYear,
                ),
              ),
            ),
            // ── Body ──────────────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: c.accent,
                backgroundColor: c.surface,
                onRefresh: () async {
                  ref.invalidate(sellerInstalmentsListProvider(_query));
                  await ref.read(sellerInstalmentsListProvider(_query).future);
                },
                child: state.when(
                  loading: () =>
                      const SellerListSkeleton(count: 5, itemHeight: 220),
                  error: (error, _) => error is SellerPlanUpgradeException
                      ? SellerPlanGateState(exception: error)
                      : SellerErrorState(
                          message: _cleanError(error),
                          onRetry: () =>
                              ref.invalidate(sellerInstalmentsListProvider(_query)),
                        ),
                  data: (data) {
                    return ListView(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: AppInsets.pageWithNav,
                      children: [
                        // KPI strip — always global (server never filters it)
                        SellerGrid(
                          children: [
                            SellerKpiCard(
                              label: 'Total Orders',
                              value: '${data.kpi.totalOrders}',
                              icon: Icons.receipt_long_rounded,
                              tone: c.accentTone,
                            ),
                            SellerKpiCard(
                              label: 'Total Pending',
                              value: data.kpi.formattedTotalPending,
                              icon: Icons.account_balance_wallet_outlined,
                              tone: c.warningTone,
                            ),
                            SellerKpiCard(
                              label: 'Collected (Month)',
                              value: data.kpi.formattedCollectedThisMonth,
                              icon: Icons.trending_up_rounded,
                              tone: c.successTone,
                            ),
                            SellerKpiCard(
                              label: 'Overdue',
                              value: '${data.kpi.overdueCount}',
                              icon: Icons.warning_amber_rounded,
                              tone: c.dangerTone,
                            ),
                          ],
                        ),
                        const Gap.v(AppSpace.sm),
                        _RangeRow(
                          total: data.pagination.total,
                          from: data.pagination.from,
                          to: data.pagination.to,
                        ),
                        const Gap.v(AppSpace.sm),
                        if (data.orders.isEmpty)
                          const SellerEmptyState(
                            icon: Icons.payments_outlined,
                            title: 'No orders found',
                            message:
                                'There are no instalment orders matching the current filters.',
                          )
                        else
                          for (final order in data.orders) ...[
                            _OrderCard(
                              order: order,
                              onTap: () => _openOrder(order),
                            ),
                            const Gap.v(AppSpace.sm),
                          ],
                        _PaginationBar(
                          pagination: data.pagination,
                          onPrevious: data.pagination.hasPrevious
                              ? () => setState(() => _page--)
                              : null,
                          onNext: data.pagination.hasNext
                              ? () => setState(() => _page++)
                              : null,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  RANGE ROW
// ═══════════════════════════════════════════════════════════
class _RangeRow extends StatelessWidget {
  final int total;
  final int? from;
  final int? to;

  const _RangeRow({required this.total, required this.from, required this.to});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final rangeText =
        total == 0 ? '0 records' : '${from ?? 0}–${to ?? 0} of $total';

    return SellerCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm,
      ),
      child: Row(
        children: [
          Icon(
            Icons.format_list_bulleted_rounded,
            size: 16,
            color: c.textTertiary,
          ),
          const Gap.h(AppSpace.xs),
          Expanded(child: Text('Orders', style: text.bodyLg)),
          Text(rangeText, style: text.caption),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  ORDER CARD (list item)
// ═══════════════════════════════════════════════════════════
class _OrderCard extends StatelessWidget {
  final SellerInstalmentOrderSummary order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final tone = orderStatusTone(order.cStatus, c);
    final nextDue = order.cNextDue;

    return SellerCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpace.md),
      accentEdge: tone.fg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────────────
          Row(
            children: [
              SellerIconBadge(
                icon: Icons.receipt_long_rounded,
                tone: tone,
                size: 44,
                iconSize: 22,
              ),
              const Gap.h(AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.formattedOrderNo, style: text.titleSm),
                    const Gap.v(AppSpace.xxs),
                    Text(
                      order.product.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySm,
                    ),
                  ],
                ),
              ),
              const Gap.h(AppSpace.xs),
              SellerStatusPill(label: order.cStatus, tone: tone),
            ],
          ),
          const Gap.v(AppSpace.sm),
          Divider(color: c.divider, height: 1),
          const Gap.v(AppSpace.sm),
          // ── Customer / next due ─────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  icon: Icons.person_outline_rounded,
                  label: 'Customer',
                  value: '${order.user.name} • ${order.user.phone}',
                ),
              ),
              const Gap.h(AppSpace.xs),
              Expanded(
                child: _InfoTile(
                  icon: Icons.calendar_today_outlined,
                  label: 'Next Due',
                  value: nextDue?.formattedDate ?? 'Cleared',
                ),
              ),
            ],
          ),
          const Gap.v(AppSpace.xs),
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  icon: Icons.shopping_bag_outlined,
                  label: 'Total / Paid',
                  value: '${order.formattedTotalDealPrice} / ${order.formattedPaid}',
                ),
              ),
              const Gap.h(AppSpace.xs),
              Expanded(
                child: _InfoTile(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Remaining',
                  value: order.formattedRemaining,
                ),
              ),
            ],
          ),
          const Gap.v(AppSpace.sm),
          // ── Progress ─────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: SellerProgressBar(
                  value: order.progressFraction,
                  color: tone.fg,
                ),
              ),
              const Gap.h(AppSpace.xs),
              Text('${order.cProgressPct}%', style: text.labelSm),
            ],
          ),
          const Gap.v(AppSpace.sm),
          SellerButton(
            label: 'View Ledger',
            icon: Icons.visibility_outlined,
            size: SellerButtonSize.small,
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  INFO TILE (shared mini detail chip)
// ═══════════════════════════════════════════════════════════
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;

    return Container(
      padding: const EdgeInsets.all(AppSpace.xs),
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: AppRadius.brSm,
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: c.accent),
          const Gap.h(AppSpace.xxs + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: text.caption),
                const Gap.v(1),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelSm.copyWith(color: c.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  FILTER TOGGLE BUTTON — month/year panel switch
// ═══════════════════════════════════════════════════════════
class _FilterToggleButton extends StatelessWidget {
  final bool active;
  final bool expanded;
  final VoidCallback onTap;

  const _FilterToggleButton({
    required this.active,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final tone = active ? c.accentTone : c.neutralTone;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brMd,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: tone.bg,
          borderRadius: AppRadius.brMd,
          border: Border.all(color: tone.border),
        ),
        child: Icon(
          expanded ? Icons.expand_less_rounded : Icons.tune_rounded,
          color: tone.fg,
          size: 20,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  MONTH / YEAR FILTER PANEL
// ═══════════════════════════════════════════════════════════
class _MonthYearFilterPanel extends StatefulWidget {
  final int? month;
  final int? year;
  final void Function({int? month, int? year}) onApply;
  final VoidCallback onClear;

  const _MonthYearFilterPanel({
    required this.month,
    required this.year,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_MonthYearFilterPanel> createState() => _MonthYearFilterPanelState();
}

class _MonthYearFilterPanelState extends State<_MonthYearFilterPanel> {
  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  late int? _month = widget.month;
  late int? _year = widget.year;

  @override
  void didUpdateWidget(covariant _MonthYearFilterPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _month = widget.month;
    _year = widget.year;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final currentYear = DateTime.now().year;
    final years = List<int>.generate(5, (i) => currentYear - i);

    return SellerCard(
      padding: const EdgeInsets.all(AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filter by order date', style: text.titleSm),
          const Gap.v(AppSpace.sm),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  initialValue: _month,
                  isExpanded: true,
                  decoration: _filterFieldDecoration(c, 'Month'),
                  style: text.bodySm.copyWith(color: c.textPrimary),
                  dropdownColor: c.surface,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Any')),
                    for (var i = 0; i < _months.length; i++)
                      DropdownMenuItem(value: i + 1, child: Text(_months[i])),
                  ],
                  onChanged: (v) => setState(() => _month = v),
                ),
              ),
              const Gap.h(AppSpace.sm),
              Expanded(
                child: DropdownButtonFormField<int?>(
                  initialValue: _year,
                  isExpanded: true,
                  decoration: _filterFieldDecoration(c, 'Year'),
                  style: text.bodySm.copyWith(color: c.textPrimary),
                  dropdownColor: c.surface,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Any')),
                    for (final y in years)
                      DropdownMenuItem(value: y, child: Text('$y')),
                  ],
                  onChanged: (v) => setState(() => _year = v),
                ),
              ),
            ],
          ),
          const Gap.v(AppSpace.sm),
          Row(
            children: [
              SellerButton.secondary(
                label: 'Clear',
                icon: Icons.refresh_rounded,
                size: SellerButtonSize.small,
                expand: false,
                onPressed: () {
                  setState(() {
                    _month = null;
                    _year = null;
                  });
                  widget.onClear();
                },
              ),
              const Spacer(),
              SellerButton(
                label: 'Apply',
                icon: Icons.check_rounded,
                size: SellerButtonSize.small,
                expand: false,
                onPressed: () => widget.onApply(month: _month, year: _year),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

InputDecoration _filterFieldDecoration(SellerColors c, String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: c.textSecondary),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpace.sm,
      vertical: AppSpace.xs,
    ),
    filled: true,
    fillColor: c.surfaceAlt,
    border: OutlineInputBorder(
      borderRadius: AppRadius.brMd,
      borderSide: BorderSide(color: c.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: AppRadius.brMd,
      borderSide: BorderSide(color: c.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: AppRadius.brMd,
      borderSide: BorderSide(color: c.accent, width: 1.6),
    ),
  );
}

// ═══════════════════════════════════════════════════════════
//  PAGINATION BAR
// ═══════════════════════════════════════════════════════════
class _PaginationBar extends StatelessWidget {
  final SellerInstalmentsPagination pagination;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const _PaginationBar({
    required this.pagination,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    if (pagination.lastPage <= 1) return const SizedBox.shrink();

    final text = context.sellerText;
    final c = context.sellerColors;

    return Row(
      children: [
        Expanded(
          child: SellerButton.secondary(
            label: 'Previous',
            icon: Icons.chevron_left_rounded,
            size: SellerButtonSize.small,
            onPressed: onPrevious,
          ),
        ),
        const Gap.h(AppSpace.sm),
        Text(
          '${pagination.currentPage}/${pagination.lastPage}',
          style: text.labelSm.copyWith(color: c.textTertiary),
        ),
        const Gap.h(AppSpace.sm),
        Expanded(
          child: SellerButton.secondary(
            label: 'Next',
            trailingIcon: Icons.chevron_right_rounded,
            size: SellerButtonSize.small,
            onPressed: onNext,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  SHARED HELPERS
// ═══════════════════════════════════════════════════════════
String _cleanError(Object error) {
  final msg = error.toString().replaceFirst('Exception: ', '').trim();
  return msg.isEmpty ? 'Something went wrong. Please try again.' : msg;
}
