// ═══════════════════════════════════════════════════════════════════════════
//  seller_custom_orders_screen.dart  —  Seller Design System
//
//  Rebuilt on the unified Seller Design System (tokens, colour extension,
//  shared component library). All Riverpod / business logic is unchanged:
//  filters, pagination, status selection, the create-order flow, customer
//  picker and every async call behave exactly as before. Pure presentation.
// ═══════════════════════════════════════════════════════════════════════════

import 'package:atompro/core/services/snackbar_services.dart';
import 'package:atompro/features/seller/core/design/design.dart';
import 'package:atompro/features/seller/core/widgets/widgets.dart';
import 'package:atompro/features/seller/customers/model/seller_customers_model.dart';
import 'package:atompro/features/seller/customers/repository/seller_customers_repository.dart';
import 'package:atompro/features/seller/custom_orders/model/seller_custom_orders_model.dart';
import 'package:atompro/features/seller/custom_orders/repository/seller_custom_orders_repository.dart';
import 'package:atompro/features/seller/custom_orders/view/seller_custom_order_details_screen.dart';
import 'package:atompro/features/seller/custom_orders/viewmodel/seller_custom_orders_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  ROOT SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class SellerCustomOrdersScreen extends ConsumerStatefulWidget {
  const SellerCustomOrdersScreen({super.key});

  @override
  ConsumerState<SellerCustomOrdersScreen> createState() =>
      _SellerCustomOrdersScreenState();
}

class _SellerCustomOrdersScreenState
    extends ConsumerState<SellerCustomOrdersScreen> {
  // ── Controllers ──────────────────────────────────────────
  final _keywordCtrl = TextEditingController();
  final _minPriceCtrl = TextEditingController();
  final _maxPriceCtrl = TextEditingController();

  // ── State ────────────────────────────────────────────────
  SellerCustomOrdersQuery _query = const SellerCustomOrdersQuery();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _filterExpanded = false;

  @override
  void dispose() {
    _keywordCtrl.dispose();
    _minPriceCtrl.dispose();
    _maxPriceCtrl.dispose();
    super.dispose();
  }

  // ── Logic (unchanged) ────────────────────────────────────
  void _applyFilters() => setState(() {
    _query = _query.copyWith(
      page: 1,
      keyword: _keywordCtrl.text,
      minPrice: _minPriceCtrl.text,
      maxPrice: _maxPriceCtrl.text,
      startDate: _formatDate(_startDate),
      endDate: _formatDate(_endDate),
      clearKeyword: _keywordCtrl.text.trim().isEmpty,
      clearMinPrice: _minPriceCtrl.text.trim().isEmpty,
      clearMaxPrice: _maxPriceCtrl.text.trim().isEmpty,
      clearStartDate: _startDate == null,
      clearEndDate: _endDate == null,
    );
  });

  void _resetFilters() {
    _keywordCtrl.clear();
    _minPriceCtrl.clear();
    _maxPriceCtrl.clear();
    setState(() {
      _startDate = null;
      _endDate = null;
      _query = const SellerCustomOrdersQuery();
    });
  }

  void _selectStatus(String? status) => setState(() {
    _query = _query.copyWith(
      page: 1,
      status: status,
      clearStatus: status == null,
    );
  });

  void _goToPage(int page) =>
      setState(() => _query = _query.copyWith(page: page));

  void _invalidateOrders() {
    ref.invalidate(sellerCustomOrdersProvider(_query));
    ref.invalidate(sellerCustomOrdersPendingCountProvider);
    ref.invalidate(sellerCustomOrdersStatusCountsProvider);
  }

  Future<void> _showCreateSheet() =>
      showSellerCreateCustomOrderSheet(context, ref);

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final dark = context.sellerIsDark;
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (ctx, child) => Theme(
        data: dark ? SellerTheme.dark : SellerTheme.light,
        child: child!,
      ),
    );
    if (range == null) return;
    setState(() {
      _startDate = range.start;
      _endDate = range.end;
    });
    _applyFilters();
  }

  bool get _hasFilters =>
      _query.status != null ||
      _query.keyword != null ||
      _query.minPrice != null ||
      _query.maxPrice != null ||
      _query.startDate != null ||
      _query.endDate != null;

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final ordersState = ref.watch(sellerCustomOrdersProvider(_query));
    final pendingCountState = ref.watch(sellerCustomOrdersPendingCountProvider);
    final statusCountsState = ref.watch(sellerCustomOrdersStatusCountsProvider);
    final pendingCount = pendingCountState.whenOrNull(data: (value) => value);
    final statusCounts = statusCountsState.whenOrNull(data: (value) => value);

    return Scaffold(
      backgroundColor: c.canvas,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'seller_add_custom_order',
        onPressed: _showCreateSheet,
        backgroundColor: c.accent,
        foregroundColor: c.onAccent,
        elevation: 0,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Create',
          style: context.sellerText.button,
        ),
      ),
      body: Column(
        children: [
          // ── Hero header (totals) ─────────────────────────
          ordersState.when(
            loading: () => _Header(
              hasFilters: _hasFilters,
              onReset: _resetFilters,
              totalOrders: null,
              pendingCount: pendingCount,
              completedCount: null,
            ),
            error: (_, _) => _Header(
              hasFilters: _hasFilters,
              onReset: _resetFilters,
              totalOrders: null,
              pendingCount: pendingCount,
              completedCount: null,
            ),
            data: (data) {
              final Map<String, int> counts = statusCounts?.isNotEmpty == true
                  ? statusCounts!
                  : Map<String, int>.from(data.statuses);
              final pending =
                  pendingCount ??
                  counts.entries
                      .where((e) => e.key.toLowerCase().contains('pending'))
                      .fold<int>(0, (s, e) => s + e.value);
              final completed = counts.entries
                  .where(
                    (e) =>
                        e.key.toLowerCase().contains('complete') ||
                        e.key.toLowerCase().contains('deliver'),
                  )
                  .fold<int>(0, (s, e) => s + e.value);
              return _Header(
                hasFilters: _hasFilters,
                onReset: _resetFilters,
                totalOrders: data.pagination.total,
                pendingCount: pending,
                completedCount: completed,
              );
            },
          ),

          // ── Body ─────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              color: c.accent,
              backgroundColor: c.surface,
              onRefresh: () async {
                _invalidateOrders();
                await ref.read(sellerCustomOrdersProvider(_query).future);
              },
              child: ListView(
                padding: AppInsets.pageWithNav,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                children: [
                  // ── Filter panel ───────────────────────
                  _FilterPanel(
                    keywordCtrl: _keywordCtrl,
                    minPriceCtrl: _minPriceCtrl,
                    maxPriceCtrl: _maxPriceCtrl,
                    startDate: _startDate,
                    endDate: _endDate,
                    expanded: _filterExpanded,
                    hasActiveFilters: _hasFilters,
                    onToggle: () =>
                        setState(() => _filterExpanded = !_filterExpanded),
                    onApply: _applyFilters,
                    onReset: _resetFilters,
                    onDateTap: _pickDateRange,
                    onClearDates: () {
                      setState(() {
                        _startDate = null;
                        _endDate = null;
                      });
                      _applyFilters();
                    },
                  ),
                  const Gap.v(AppSpace.md),

                  // ── Content ────────────────────────────
                  ordersState.when(
                    loading: () => const SellerListSkeleton(),
                    error: (e, _) => SellerErrorState(
                      message: e.toString().replaceFirst('Exception: ', ''),
                      onRetry: () =>
                          ref.invalidate(sellerCustomOrdersProvider(_query)),
                    ),
                    data: (data) => _OrdersContent(
                      data: data,
                      statusCounts: statusCounts,
                      selectedStatus: _query.status,
                      onStatusSelect: _selectStatus,
                      onPage: _goToPage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onReset;
  final int? totalOrders;
  final int? pendingCount;
  final int? completedCount;

  const _Header({
    required this.hasFilters,
    required this.onReset,
    required this.totalOrders,
    required this.pendingCount,
    required this.completedCount,
  });

  @override
  Widget build(BuildContext context) {
    return SellerGradientHeader(
      leading: const SellerHeaderIconBadge(icon: Icons.receipt_long_rounded),
      title: 'Custom Orders',
      subtitle: 'Instalment & deal orders',
      actions: [
        if (hasFilters)
          SellerHeaderIconButton(
            icon: Icons.filter_alt_off_outlined,
            onTap: onReset,
            tooltip: 'Reset filters',
          ),
      ],
      bottom: Row(
        children: [
          Expanded(
            child: _HeaderStat(
              icon: Icons.layers_rounded,
              label: 'Total',
              value: totalOrders?.toString() ?? '—',
            ),
          ),
          const _HeaderDivider(),
          Expanded(
            child: _HeaderStat(
              icon: Icons.pending_actions_rounded,
              label: 'Pending',
              value: pendingCount?.toString() ?? '—',
            ),
          ),
          const _HeaderDivider(),
          Expanded(
            child: _HeaderStat(
              icon: Icons.check_circle_outline_rounded,
              label: 'Completed',
              value: completedCount?.toString() ?? '—',
            ),
          ),
        ],
      ),
    );
  }
}

/// A frosted square icon container for the gradient header (matches the
/// circular [SellerHeaderIconButton] family but non-interactive).
class SellerHeaderIconBadge extends StatelessWidget {
  final IconData icon;
  const SellerHeaderIconBadge({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: AppRadius.brMd,
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _HeaderStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 16),
      const Gap.v(AppSpace.xxs),
      Text(
        value,
        style: const TextStyle(
          fontFamily: 'Roboto',
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          height: 1.1,
        ),
      ),
      Text(
        label,
        style: TextStyle(
          fontFamily: 'Roboto',
          color: Colors.white.withValues(alpha: 0.64),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

class _HeaderDivider extends StatelessWidget {
  const _HeaderDivider();
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 40,
    color: Colors.white.withValues(alpha: 0.15),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  COLLAPSIBLE FILTER PANEL
// ─────────────────────────────────────────────────────────────────────────────
class _FilterPanel extends StatelessWidget {
  final TextEditingController keywordCtrl;
  final TextEditingController minPriceCtrl;
  final TextEditingController maxPriceCtrl;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool expanded;
  final bool hasActiveFilters;
  final VoidCallback onToggle;
  final VoidCallback onApply;
  final VoidCallback onReset;
  final VoidCallback onDateTap;
  final VoidCallback onClearDates;

  const _FilterPanel({
    required this.keywordCtrl,
    required this.minPriceCtrl,
    required this.maxPriceCtrl,
    required this.startDate,
    required this.endDate,
    required this.expanded,
    required this.hasActiveFilters,
    required this.onToggle,
    required this.onApply,
    required this.onReset,
    required this.onDateTap,
    required this.onClearDates,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;

    return SellerCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // ── Toggle header ───────────────────────────────
          InkWell(
            onTap: onToggle,
            borderRadius: AppRadius.brLg,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.md,
                vertical: AppSpace.sm + 2,
              ),
              child: Row(
                children: [
                  SellerIconBadge(
                    icon: Icons.tune_rounded,
                    tone: c.accentTone,
                    size: 34,
                    iconSize: 18,
                    radius: AppRadius.sm,
                  ),
                  const Gap.h(AppSpace.sm),
                  Text('Search & Filters', style: text.titleSm),
                  const Gap.h(AppSpace.xs),
                  if (hasActiveFilters)
                    SellerStatusPill(
                      label: 'Active',
                      tone: c.accentTone,
                      showDot: false,
                      dense: true,
                    ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: AppMotion.fast,
                    child: Icon(
                      Icons.expand_more_rounded,
                      color: c.textTertiary,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Expandable body ─────────────────────────────
          AnimatedCrossFade(
            duration: AppMotion.base,
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: _FilterBody(
              keywordCtrl: keywordCtrl,
              minPriceCtrl: minPriceCtrl,
              maxPriceCtrl: maxPriceCtrl,
              startDate: startDate,
              endDate: endDate,
              onApply: onApply,
              onReset: onReset,
              onDateTap: onDateTap,
              onClearDates: onClearDates,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBody extends StatelessWidget {
  final TextEditingController keywordCtrl;
  final TextEditingController minPriceCtrl;
  final TextEditingController maxPriceCtrl;
  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback onApply;
  final VoidCallback onReset;
  final VoidCallback onDateTap;
  final VoidCallback onClearDates;

  const _FilterBody({
    required this.keywordCtrl,
    required this.minPriceCtrl,
    required this.maxPriceCtrl,
    required this.startDate,
    required this.endDate,
    required this.onApply,
    required this.onReset,
    required this.onDateTap,
    required this.onClearDates,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final hasDates = startDate != null && endDate != null;
    final dateLabel = !hasDates
        ? 'Select date range'
        : '${_formatDate(startDate)} → ${_formatDate(endDate)}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        0,
        AppSpace.md,
        AppSpace.md,
      ),
      child: Column(
        children: [
          Divider(height: 1, color: c.divider),
          const Gap.v(AppSpace.sm),

          // Keyword
          _ThemedField(
            controller: keywordCtrl,
            label: 'Keyword — product, PR number…',
            icon: Icons.search_rounded,
            onSubmit: (_) => onApply(),
          ),
          const Gap.v(AppSpace.sm),

          // Price range
          Row(
            children: [
              Expanded(
                child: _ThemedField(
                  controller: minPriceCtrl,
                  label: 'Min price',
                  icon: Icons.arrow_downward_rounded,
                  numeric: true,
                ),
              ),
              const Gap.h(AppSpace.sm),
              Expanded(
                child: _ThemedField(
                  controller: maxPriceCtrl,
                  label: 'Max price',
                  icon: Icons.arrow_upward_rounded,
                  numeric: true,
                ),
              ),
            ],
          ),
          const Gap.v(AppSpace.sm),

          // Date range
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onDateTap,
                  borderRadius: AppRadius.brMd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.sm,
                      vertical: AppSpace.sm + 2,
                    ),
                    decoration: BoxDecoration(
                      color: c.surfaceAlt,
                      borderRadius: AppRadius.brMd,
                      border: Border.all(color: c.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.date_range_rounded,
                          size: 18,
                          color: c.accent,
                        ),
                        const Gap.h(AppSpace.xs),
                        Expanded(
                          child: Text(
                            dateLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: hasDates
                                ? text.bodySm.copyWith(color: c.textPrimary)
                                : text.bodySm,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (startDate != null || endDate != null) ...[
                const Gap.h(AppSpace.xs),
                _SquareIconButton(
                  icon: Icons.close_rounded,
                  tone: c.dangerTone,
                  onTap: onClearDates,
                ),
              ],
            ],
          ),
          const Gap.v(AppSpace.md),

          // Action buttons
          Row(
            children: [
              SellerButton.secondary(
                label: 'Reset',
                onPressed: onReset,
                icon: Icons.refresh_rounded,
                size: SellerButtonSize.small,
                expand: false,
              ),
              const Gap.h(AppSpace.sm),
              Expanded(
                child: SellerButton(
                  label: 'Apply Filters',
                  onPressed: onApply,
                  icon: Icons.check_rounded,
                  size: SellerButtonSize.small,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A square, tone-tinted icon button used for inline clear/reset affordances.
class _SquareIconButton extends StatelessWidget {
  final IconData icon;
  final SellerTone tone;
  final VoidCallback onTap;

  const _SquareIconButton({
    required this.icon,
    required this.tone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brMd,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: tone.bg,
          borderRadius: AppRadius.brMd,
          border: Border.all(color: tone.border),
        ),
        child: Icon(icon, color: tone.fg, size: 18),
      ),
    );
  }
}

/// A themed text field used inside filter & create surfaces.
class _ThemedField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool numeric;
  final ValueChanged<String>? onSubmit;

  const _ThemedField({
    required this.controller,
    required this.label,
    required this.icon,
    this.numeric = false,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    return TextField(
      controller: controller,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      inputFormatters: numeric
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      textInputAction: onSubmit != null
          ? TextInputAction.search
          : TextInputAction.next,
      onSubmitted: onSubmit,
      style: text.body,
      cursorColor: c.accent,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: text.bodySm,
        floatingLabelStyle: text.labelSm.copyWith(color: c.accent),
        prefixIcon: Icon(icon, size: 18, color: c.textTertiary),
        filled: true,
        fillColor: c.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpace.sm,
          vertical: AppSpace.sm,
        ),
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ORDERS CONTENT (status chips + list + pagination)
// ─────────────────────────────────────────────────────────────────────────────
class _OrdersContent extends StatelessWidget {
  final SellerCustomOrdersResponse data;
  final Map<String, int>? statusCounts;
  final String? selectedStatus;
  final ValueChanged<String?> onStatusSelect;
  final ValueChanged<int> onPage;

  const _OrdersContent({
    required this.data,
    required this.statusCounts,
    required this.selectedStatus,
    required this.onStatusSelect,
    required this.onPage,
  });

  @override
  Widget build(BuildContext context) {
    final orders = data.orders;
    final statuses = statusCounts?.isNotEmpty == true
        ? statusCounts!
        : data.statuses;
    final pagination = data.pagination;

    // Build chip data: "All" + each status, tracking the selected index.
    final statusKeys = statuses.keys.toList();
    final chips = <SellerChipData>[
      SellerChipData('All', count: pagination.total),
      for (final entry in statuses.entries)
        SellerChipData(entry.key, count: entry.value),
    ];
    final selectedIndex = selectedStatus == null
        ? 0
        : (statusKeys.indexOf(selectedStatus!) + 1).clamp(0, chips.length - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Status filter chips ─────────────────────────
        SellerFilterChips(
          chips: chips,
          selectedIndex: selectedIndex,
          padding: EdgeInsets.zero,
          onSelected: (i) =>
              onStatusSelect(i == 0 ? null : statusKeys[i - 1]),
        ),
        const Gap.v(AppSpace.md),

        // ── Pagination summary ──────────────────────────
        _PaginationBar(pagination: pagination),
        const Gap.v(AppSpace.sm),

        // ── Order cards ─────────────────────────────────
        if (orders.isEmpty)
          const SellerEmptyState(
            icon: Icons.search_off_rounded,
            title: 'No orders match your filters',
            message: 'Try adjusting the filters or clearing the date range.',
          )
        else
          ...orders.map(
            (order) => Padding(
              key: ValueKey(order.id),
              padding: const EdgeInsets.only(bottom: AppSpace.sm),
              child: _OrderCard(order: order),
            ),
          ),

        const Gap.v(AppSpace.xs),

        // ── Pagination controls ─────────────────────────
        _PaginationControls(pagination: pagination, onPage: onPage),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PAGINATION BAR
// ─────────────────────────────────────────────────────────────────────────────
class _PaginationBar extends StatelessWidget {
  final SellerCustomOrdersPagination pagination;
  const _PaginationBar({required this.pagination});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final from = pagination.from;
    final to = pagination.to;
    final total = pagination.total;

    final rangeText = from == null || to == null
        ? 'No records found'
        : '$from – $to of $total orders';

    return Row(
      children: [
        Expanded(child: Text(rangeText, style: text.bodySm)),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.xs + 2,
            vertical: AppSpace.xxs,
          ),
          decoration: BoxDecoration(
            color: c.accentSurface,
            borderRadius: AppRadius.brPill,
          ),
          child: Text(
            'Page ${pagination.currentPage} / ${pagination.lastPage}',
            style: text.caption.copyWith(
              color: c.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ORDER CARD
// ─────────────────────────────────────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  final SellerCustomOrder order;
  const _OrderCard({required this.order});

  void _open(BuildContext context) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SellerCustomOrderDetailsScreen(
          orderUuid: order.uuid,
          initialOrder: order,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final tone = SellerStatus.toneFor(order.status, c);

    return SellerCard(
      padding: EdgeInsets.zero,
      accentEdge: tone.fg,
      onTap: () => _open(context),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title row ──────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SellerIconBadge(
                  icon: Icons.inventory_2_outlined,
                  tone: tone,
                  size: 38,
                  iconSize: 18,
                ),
                const Gap.h(AppSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.product.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSm,
                      ),
                      const Gap.v(2),
                      Text(
                        '${order.product.prNumber} · ${order.portal}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.caption,
                      ),
                    ],
                  ),
                ),
                const Gap.h(AppSpace.xs),
                SellerStatusPill(label: order.status),
              ],
            ),

            const Gap.v(AppSpace.sm),
            Divider(height: 1, color: c.divider),
            const Gap.v(AppSpace.sm),

            // ── Stats row ──────────────────────
            Row(
              children: [
                Expanded(
                  child: _StatCell(
                    icon: Icons.price_check_rounded,
                    label: 'Deal Price',
                    value: order.formattedTotalDealPrice,
                    tone: c.accentTone,
                  ),
                ),
                Expanded(
                  child: _StatCell(
                    icon: Icons.payments_outlined,
                    label: 'Advance',
                    value: order.formattedAdvancePrice,
                    tone: c.successTone,
                  ),
                ),
                Expanded(
                  child: _StatCell(
                    icon: Icons.calendar_month_outlined,
                    label: 'Tenure',
                    value: '${order.tenure} mo.',
                    tone: c.violetTone,
                  ),
                ),
              ],
            ),

            const Gap.v(AppSpace.sm),

            // ── Customer detail ─────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.sm,
                vertical: AppSpace.xs + 2,
              ),
              decoration: BoxDecoration(
                color: c.surfaceAlt,
                borderRadius: AppRadius.brSm,
              ),
              child: Row(
                children: [
                  SellerIconBadge(
                    icon: Icons.person_outline_rounded,
                    tone: c.accentTone,
                    size: 32,
                    iconSize: 16,
                    radius: AppRadius.sm,
                  ),
                  const Gap.h(AppSpace.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodyLg.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Gap.v(2),
                        Text(order.user.phone, style: text.caption),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Gap.v(AppSpace.xs),

            // ── Meta row ───────────────────────
            Row(
              children: [
                Icon(Icons.schedule_rounded, size: 13, color: c.textTertiary),
                const Gap.h(AppSpace.xxs),
                Text(order.formattedCreatedAt, style: text.caption),
                const Gap.h(AppSpace.xs),
                Icon(Icons.language_outlined, size: 13, color: c.textTertiary),
                const Gap.h(AppSpace.xxs),
                Text(order.portal, style: text.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final SellerTone tone;

  const _StatCell({
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final text = context.sellerText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: tone.fg),
            const Gap.h(AppSpace.xxs),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.caption,
              ),
            ),
          ],
        ),
        const Gap.v(AppSpace.xxs),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: text.bodyLg.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PAGINATION CONTROLS
// ─────────────────────────────────────────────────────────────────────────────
class _PaginationControls extends StatelessWidget {
  final SellerCustomOrdersPagination pagination;
  final ValueChanged<int> onPage;

  const _PaginationControls({required this.pagination, required this.onPage});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SellerButton.secondary(
            label: 'Previous',
            icon: Icons.chevron_left_rounded,
            onPressed: pagination.hasPrevious
                ? () => onPage(pagination.currentPage - 1)
                : null,
          ),
        ),
        const Gap.h(AppSpace.sm),
        Expanded(
          child: SellerButton(
            label: 'Next',
            trailingIcon: Icons.chevron_right_rounded,
            onPressed: pagination.hasNext
                ? () => onPage(pagination.currentPage + 1)
                : null,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  CREATE CUSTOM ORDER SHEET
// ═══════════════════════════════════════════════════════════════════════════
/// Opens the create-custom-order form. Reusable from the global + action so
/// "New custom order" creates in one tap instead of just navigating.
Future<void> showSellerCreateCustomOrderSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final dark = context.sellerIsDark;
  final created = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Theme(
      data: dark ? SellerTheme.dark : SellerTheme.light,
      child: const _CreateCustomOrderSheet(),
    ),
  );
  if (created == true) {
    ref.invalidate(sellerCustomOrdersProvider);
    ref.invalidate(sellerCustomOrdersPendingCountProvider);
    ref.invalidate(sellerCustomOrdersStatusCountsProvider);
  }
}

class _CreateCustomOrderSheet extends ConsumerStatefulWidget {
  const _CreateCustomOrderSheet();

  @override
  ConsumerState<_CreateCustomOrderSheet> createState() =>
      _CreateCustomOrderSheetState();
}

class _CreateCustomOrderSheetState
    extends ConsumerState<_CreateCustomOrderSheet> {
  final _formKey = GlobalKey<FormState>();
  final _productId = TextEditingController();
  final _totalDealPrice = TextEditingController();
  final _advancePrice = TextEditingController();
  final _perMonthPercentage = TextEditingController(text: '4');
  final _tenure = TextEditingController();

  SellerCustomer? _selectedCustomer;
  List<SellerCustomer> _customers = const [];
  bool _loadingCustomers = true;
  bool _saving = false;
  String? _customerError;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _productId.dispose();
    _totalDealPrice.dispose();
    _advancePrice.dispose();
    _perMonthPercentage.dispose();
    _tenure.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _loadingCustomers = true;
      _customerError = null;
    });
    try {
      final repository = ref.read(sellerCustomersRepositoryProvider);
      final loaded = <SellerCustomer>[];
      var page = 1;
      var lastPage = 1;

      do {
        final response = await repository.getCustomers(
          SellerCustomersQuery(page: page),
        );
        loaded.addAll(response.customers);
        lastPage = response.pagination.lastPage;
        page++;
      } while (page <= lastPage && page <= 10);

      if (!mounted) return;
      setState(() {
        _customers = loaded;
        _loadingCustomers = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _customerError = _cleanCreateError(e);
        _loadingCustomers = false;
      });
    }
  }

  Future<void> _pickCustomer() async {
    if (_saving || _loadingCustomers || _customers.isEmpty) return;
    final dark = context.sellerIsDark;
    final customer = await showModalBottomSheet<SellerCustomer>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Theme(
        data: dark ? SellerTheme.dark : SellerTheme.light,
        child: _CustomerPickerSheet(
          customers: _customers,
          selected: _selectedCustomer,
        ),
      ),
    );
    if (customer == null || !mounted) return;
    setState(() => _selectedCustomer = customer);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final customer = _selectedCustomer;
    if (customer == null) {
      SnackbarService().showErrorSnackBar('Please select a customer.');
      return;
    }
    if (customer.profile.cityId <= 0 || customer.profile.areaId <= 0) {
      SnackbarService().showErrorSnackBar(
        'Selected customer is missing city or area data.',
      );
      return;
    }

    final total = int.tryParse(_totalDealPrice.text.trim()) ?? 0;
    final advance = int.tryParse(_advancePrice.text.trim()) ?? 0;
    if (advance >= total) {
      SnackbarService().showErrorSnackBar(
        'Advance price must be less than total deal price.',
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(sellerCustomOrdersRepositoryProvider)
          .storeCustomOrder(
            userId: customer.id.toString(),
            productId: _productId.text.trim(),
            totalDealPrice: _totalDealPrice.text.trim(),
            advancePrice: _advancePrice.text.trim(),
            perMonthPercentage: _perMonthPercentage.text.trim(),
            tenure: _tenure.text.trim(),
            areaId: customer.profile.areaId.toString(),
            cityId: customer.profile.cityId.toString(),
          );
      if (!mounted) return;
      SnackbarService().showSuccessSnackBar('Custom order created.');
      Navigator.pop(context, true);
    } catch (e) {
      SnackbarService().showErrorSnackBar(_cleanCreateError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: 'Create Custom Order',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CustomerSelectCard(
              customer: _selectedCustomer,
              loading: _loadingCustomers,
              error: _customerError,
              count: _customers.length,
              enabled: !_saving,
              onTap: _pickCustomer,
              onRetry: _loadCustomers,
            ),
            const Gap.v(AppSpace.sm),
            _CreateNumberField(
              controller: _productId,
              label: 'Product ID',
              icon: Icons.inventory_2_outlined,
              enabled: !_saving,
            ),
            const Gap.v(AppSpace.sm),
            _CreateNumberField(
              controller: _totalDealPrice,
              label: 'Total Deal Price',
              icon: Icons.payments_outlined,
              enabled: !_saving,
            ),
            const Gap.v(AppSpace.sm),
            _CreateNumberField(
              controller: _advancePrice,
              label: 'Advance Price',
              icon: Icons.savings_outlined,
              enabled: !_saving,
            ),
            const Gap.v(AppSpace.sm),
            Row(
              children: [
                Expanded(
                  child: _CreateNumberField(
                    controller: _perMonthPercentage,
                    label: 'Monthly %',
                    icon: Icons.percent_rounded,
                    enabled: !_saving,
                  ),
                ),
                const Gap.h(AppSpace.sm),
                Expanded(
                  child: _CreateNumberField(
                    controller: _tenure,
                    label: 'Tenure',
                    icon: Icons.calendar_month_outlined,
                    enabled: !_saving,
                  ),
                ),
              ],
            ),
            const Gap.v(AppSpace.md),
            SellerButton(
              label: 'Create Order',
              icon: Icons.save_outlined,
              loading: _saving,
              onPressed: _saving ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateNumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool enabled;

  const _CreateNumberField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: _requiredCreateNumber,
      style: text.body,
      cursorColor: c.accent,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: text.bodySm,
        floatingLabelStyle: text.labelSm.copyWith(color: c.accent),
        prefixIcon: Icon(icon, size: 18, color: c.textTertiary),
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
      ),
    );
  }
}

class _CustomerSelectCard extends StatelessWidget {
  final SellerCustomer? customer;
  final bool loading;
  final String? error;
  final int count;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onRetry;

  const _CustomerSelectCard({
    required this.customer,
    required this.loading,
    required this.error,
    required this.count,
    required this.enabled,
    required this.onTap,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final selected = customer;
    final hasError = error != null;

    return SellerCard(
      color: c.surfaceAlt,
      borderColor: selected == null
          ? c.border
          : c.accent.withValues(alpha: 0.4),
      elevated: false,
      padding: const EdgeInsets.all(AppSpace.sm + 2),
      onTap: enabled && !loading && !hasError ? onTap : null,
      child: Row(
        children: [
          SellerIconBadge(
            icon: Icons.person_search_outlined,
            tone: c.accentTone,
          ),
          const Gap.h(AppSpace.sm),
          Expanded(child: _body(context, selected, hasError)),
          if (hasError)
            IconButton(
              tooltip: 'Retry',
              onPressed: enabled ? onRetry : null,
              icon: Icon(Icons.refresh_rounded, color: c.textSecondary),
            )
          else
            Icon(Icons.keyboard_arrow_down_rounded, color: c.textSecondary),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, SellerCustomer? selected, bool hasError) {
    final c = context.sellerColors;
    final text = context.sellerText;
    if (loading) {
      return Text(
        'Loading customers...',
        style: text.bodyLg.copyWith(fontWeight: FontWeight.w700),
      );
    }
    if (hasError) {
      return Text(
        error!,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: text.labelSm.copyWith(color: c.danger),
      );
    }
    if (selected == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Customer',
            style: text.bodyLg.copyWith(fontWeight: FontWeight.w700),
          ),
          const Gap.v(2),
          Text(
            count == 0 ? 'No customers found' : '$count customers available',
            style: text.caption,
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          selected.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.bodyLg.copyWith(fontWeight: FontWeight.w700),
        ),
        const Gap.v(2),
        Text(
          '${selected.phone} · City ${selected.profile.cityId}, Area ${selected.profile.areaId}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.caption,
        ),
      ],
    );
  }
}

class _CustomerPickerSheet extends StatefulWidget {
  final List<SellerCustomer> customers;
  final SellerCustomer? selected;

  const _CustomerPickerSheet({required this.customers, this.selected});

  @override
  State<_CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<_CustomerPickerSheet> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<SellerCustomer> get _filtered {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return widget.customers;
    return widget.customers
        .where((customer) {
          return customer.name.toLowerCase().contains(query) ||
              customer.phone.toLowerCase().contains(query) ||
              customer.email.toLowerCase().contains(query) ||
              customer.profile.identifier.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final customers = _filtered;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * .82,
        padding: const EdgeInsets.fromLTRB(
          AppSpace.lg,
          AppSpace.sm,
          AppSpace.lg,
          AppSpace.lg,
        ),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: AppRadius.sheet,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SheetHandle(),
              const Gap.v(AppSpace.md),
              Text('Select Customer', style: text.titleMd),
              const Gap.v(AppSpace.sm),
              SellerSearchField(
                controller: _search,
                hint: 'Search name, phone, email',
                onChanged: (_) => setState(() {}),
              ),
              const Gap.v(AppSpace.sm),
              Expanded(
                child: customers.isEmpty
                    ? Center(
                        child: Text('No matching customers.', style: text.bodySm),
                      )
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (_, index) {
                          final customer = customers[index];
                          return _CustomerPickerTile(
                            customer: customer,
                            selected: customer.id == widget.selected?.id,
                            onTap: () => Navigator.pop(context, customer),
                          );
                        },
                        separatorBuilder: (_, _) => const Gap.v(AppSpace.xs),
                        itemCount: customers.length,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerPickerTile extends StatelessWidget {
  final SellerCustomer customer;
  final bool selected;
  final VoidCallback onTap;

  const _CustomerPickerTile({
    required this.customer,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    return SellerCard(
      color: selected ? c.accentSurface : c.surfaceAlt,
      borderColor: selected ? c.accent : c.border,
      elevated: false,
      padding: const EdgeInsets.all(AppSpace.sm),
      onTap: onTap,
      child: Row(
        children: [
          SellerIconBadge(
            icon: selected
                ? Icons.check_circle_outline_rounded
                : Icons.person_outline_rounded,
            tone: selected ? c.accentTone : c.neutralTone,
          ),
          const Gap.h(AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyLg.copyWith(fontWeight: FontWeight.w700),
                ),
                const Gap.v(2),
                Text(
                  customer.phone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySm,
                ),
                const Gap.v(2),
                Text(
                  'User ${customer.id} · City ${customer.profile.cityId} · Area ${customer.profile.areaId}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SHARED SHEET SCAFFOLDING
// ─────────────────────────────────────────────────────────────────────────────
class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: c.borderStrong,
          borderRadius: AppRadius.brPill,
        ),
      ),
    );
  }
}

class _SheetShell extends StatelessWidget {
  final String title;
  final Widget child;

  const _SheetShell({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.lg,
          AppSpace.sm,
          AppSpace.lg,
          AppSpace.lg,
        ),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: AppRadius.sheet,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SheetHandle(),
                const Gap.v(AppSpace.md),
                Text(title, style: text.titleMd),
                const Gap.v(AppSpace.md),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  UTILITIES (unchanged from original)
// ─────────────────────────────────────────────────────────────────────────────
String? _formatDate(DateTime? date) {
  if (date == null) return null;
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '${date.year}-$m-$d';
}

String? _requiredCreateNumber(String? value) {
  final number = int.tryParse(value?.trim() ?? '');
  if (number == null || number <= 0) return 'Required';
  return null;
}

String _cleanCreateError(Object error) {
  final text = error.toString().replaceFirst('Exception: ', '').trim();
  return text.isEmpty ? 'Something went wrong. Please try again.' : text;
}
