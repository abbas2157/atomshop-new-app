// ═══════════════════════════════════════════════════════════════════════════
//  seller_custom_orders_screen.dart  —  Seller Design System
//
//  Rebuilt on the unified Seller Design System (tokens, colour extension,
//  shared component library). All Riverpod / business logic is unchanged:
//  filters, pagination, status selection, the create-order flow, customer
//  picker and every async call behave exactly as before. Pure presentation.
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:io';

import 'package:atompro/core/seller_plan_upgrade_exception.dart';
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
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

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
                    error: (e, _) => e is SellerPlanUpgradeException
                        ? SellerPlanGateState(exception: e)
                        : SellerErrorState(
                            message: e.toString().replaceFirst('Exception: ', ''),
                            onRetry: () =>
                                ref.invalidate(sellerCustomOrdersProvider(_query)),
                          ),
                    data: (data) => data.gate != null
                        ? SellerPlanGateState(exception: data.gate!)
                        : _OrdersContent(
                            data: data,
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
  final String? selectedStatus;
  final ValueChanged<String?> onStatusSelect;
  final ValueChanged<int> onPage;

  const _OrdersContent({
    required this.data,
    required this.selectedStatus,
    required this.onStatusSelect,
    required this.onPage,
  });

  @override
  Widget build(BuildContext context) {
    final orders = data.orders;
    final statuses = data.statuses;
    final pagination = data.pagination;

    // Build chip data: "All" + each status in the canonical workflow order.
    const statusOrder = [
      'Pending',
      'Varification',
      'Processing',
      'Delivered',
      'Instalments',
      'Completed',
      'Cancelled',
    ];
    final sortedEntries = statuses.entries.toList()
      ..sort((a, b) {
        final ai = statusOrder.indexOf(a.key);
        final bi = statusOrder.indexOf(b.key);
        return (ai == -1 ? 999 : ai).compareTo(bi == -1 ? 999 : bi);
      });
    final statusKeys = sortedEntries.map((e) => e.key).toList();
    final chips = <SellerChipData>[
      SellerChipData('All', count: pagination.total),
      for (final entry in sortedEntries)
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

        SellerPaginationBar(
          currentPage: pagination.currentPage,
          lastPage: pagination.lastPage,
          onPage: onPage,
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
                      if (order.cityTitle.isNotEmpty || order.areaTitle.isNotEmpty) ...[
                        const Gap.v(2),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 11, color: c.textTertiary),
                            const Gap.h(2),
                            Flexible(
                              child: Text(
                                [
                                  if (order.cityTitle.isNotEmpty) order.cityTitle,
                                  if (order.areaTitle.isNotEmpty) order.areaTitle,
                                ].join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.caption.copyWith(
                                    color: c.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ],
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
                  if (order.user.phone.isNotEmpty) ...[
                    const Gap.h(AppSpace.xs),
                    _OrderContactBtn(
                      icon: Icon(Icons.call_outlined, size: 15, color: c.accent),
                      color: c.accent,
                      onTap: () => _launchCall(order.user.phone),
                    ),
                    const Gap.h(6),
                    _OrderContactBtn(
                      icon: SvgPicture.string(
                        _kWhatsAppSvg,
                        width: 15,
                        height: 15,
                        colorFilter: const ColorFilter.mode(Color(0xFF25D366), BlendMode.srcIn),
                      ),
                      color: const Color(0xFF25D366),
                      onTap: () => _launchWhatsApp(order.user.phone),
                    ),
                  ],
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
//  CONTACT HELPERS
// ─────────────────────────────────────────────────────────────────────────────

const _kWhatsAppSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 448 512">'
    '<path d="M380.9 97.1C339 55.1 283.2 32 223.9 32c-122.4 0-222 99.6-222 222 '
    '0 39.1 10.2 77.3 29.6 111L0 480l117.7-30.9c32.4 17.7 68.9 27 106.1 27h.1'
    'c122.3 0 224.1-99.6 224.1-222 0-59.3-25.2-115-67.1-157zm-157 341.6c-33.2 '
    '0-65.7-8.9-94-25.7l-6.7-4-69.8 18.3L72 359.2l-4.4-7c-18.5-29.4-28.2-63.3'
    '-28.2-98.2 0-101.7 82.8-184.5 184.6-184.5 49.3 0 95.6 19.2 130.4 54.1 '
    '34.8 34.9 56.2 81.2 56.1 130.5 0 101.8-84.9 184.6-186.6 184.6zm101.2-138'
    '.2c-5.5-2.8-32.8-16.2-37.9-18-5.1-1.9-8.8-2.8-12.5 2.8-3.7 5.6-14.3 18'
    '-17.6 21.8-3.2 3.7-6.5 4.2-12 1.4-32.6-16.3-54-29.1-75.5-66-5.7-9.8 '
    '5.7-9.1 16.3-30.3 1.8-3.7.9-6.9-.5-9.7-1.4-2.8-12.5-30.1-17.1-41.2-4.5'
    '-10.8-9.1-9.3-12.5-9.5-3.2-.2-6.9-.2-10.6-.2-3.7 0-9.7 1.4-14.8 6.9-5.1'
    ' 5.6-19.4 19-19.4 46.3 0 27.3 19.9 53.7 22.6 57.4 2.8 3.7 39.1 59.7 94.8'
    ' 83.8 35.2 15.2 49 16.5 66.6 13.9 10.7-1.6 32.8-13.4 37.4-26.4 4.6-13 '
    '4.6-24.1 3.2-26.4-1.3-2.5-5-3.9-10.5-6.6z"/></svg>';

Future<void> _launchCall(String phone) async {
  final uri = Uri(scheme: 'tel', path: phone);
  if (await canLaunchUrl(uri)) launchUrl(uri);
}

Future<void> _launchWhatsApp(String phone) async {
  final normalized = phone.startsWith('0') ? '92${phone.substring(1)}' : phone;
  final uri = Uri.parse('https://wa.me/$normalized');
  if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
}

class _OrderContactBtn extends StatelessWidget {
  final Widget icon;
  final Color color;
  final VoidCallback onTap;

  const _OrderContactBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Center(child: icon),
      ),
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
  WidgetRef ref, {
  SellerCustomer? initialCustomer,
}) async {
  final dark = context.sellerIsDark;
  final created = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Theme(
      data: dark ? SellerTheme.dark : SellerTheme.light,
      child: _CreateCustomOrderSheet(initialCustomer: initialCustomer),
    ),
  );
  if (created == true) {
    ref.invalidate(sellerCustomOrdersProvider);
    ref.invalidate(sellerCustomOrdersPendingCountProvider);
    ref.invalidate(sellerCustomOrdersStatusCountsProvider);
  }
}

class _CreateCustomOrderSheet extends ConsumerStatefulWidget {
  final SellerCustomer? initialCustomer;

  const _CreateCustomOrderSheet({this.initialCustomer});

  @override
  ConsumerState<_CreateCustomOrderSheet> createState() =>
      _CreateCustomOrderSheetState();
}

/// Sentinel value used by the category/brand dropdowns to mean "Other…".
const String _kOtherLookupValue = 'other';

/// A single editable specification row (title + value) in the create form.
class _SpecRow {
  final TextEditingController title;
  final TextEditingController value;
  _SpecRow() : title = TextEditingController(), value = TextEditingController();

  void dispose() {
    title.dispose();
    value.dispose();
  }
}

class _CreateCustomOrderSheetState
    extends ConsumerState<_CreateCustomOrderSheet> {
  final _formKey = GlobalKey<FormState>();
  final _productTitle = TextEditingController();
  final _productPrice = TextEditingController();
  final _advancePrice = TextEditingController();
  final _perMonthPercentage = TextEditingController(text: '4');
  final _tenure = TextEditingController();
  final _newCategory = TextEditingController();
  final _newBrand = TextEditingController();

  SellerCustomer? _selectedCustomer;
  List<SellerCustomer> _customers = const [];
  bool _loadingCustomers = true;
  bool _saving = false;
  String? _customerError;

  // Category / brand dropdown selection. Holds a numeric id string, the literal
  // [_kOtherLookupValue], or null (not chosen).
  String? _categoryValue;
  String? _brandValue;

  final List<_SpecRow> _specs = [];
  File? _picture;

  @override
  void initState() {
    super.initState();
    _selectedCustomer = widget.initialCustomer;
    _loadCustomers();
    // Recompute the total-deal preview as the user types.
    _productPrice.addListener(_onPlanChanged);
    _advancePrice.addListener(_onPlanChanged);
    _perMonthPercentage.addListener(_onPlanChanged);
    _tenure.addListener(_onPlanChanged);
  }

  @override
  void dispose() {
    _productTitle.dispose();
    _productPrice.dispose();
    _advancePrice.dispose();
    _perMonthPercentage.dispose();
    _tenure.dispose();
    _newCategory.dispose();
    _newBrand.dispose();
    for (final spec in _specs) {
      spec.dispose();
    }
    super.dispose();
  }

  void _onPlanChanged() => setState(() {});

  // ── Total deal price preview ─────────────────────────────
  double get _productPriceNum =>
      double.tryParse(_productPrice.text.trim()) ?? 0;
  double get _advancePriceNum =>
      double.tryParse(_advancePrice.text.trim()) ?? 0;
  double get _perMonthPctNum =>
      double.tryParse(_perMonthPercentage.text.trim()) ?? 0;
  int get _tenureNum => int.tryParse(_tenure.text.trim()) ?? 0;

  /// `financed = price - advance; markup = (pct/100) * tenure * financed;`
  /// `total = price + markup` (sourcing fee is 0 at creation).
  double get _totalDealPreview {
    final financed = _productPriceNum - _advancePriceNum;
    final markup = (_perMonthPctNum / 100) * _tenureNum * financed;
    return _productPriceNum + markup;
  }

  void _addSpec() => setState(() => _specs.add(_SpecRow()));

  void _removeSpec(int index) => setState(() {
    _specs.removeAt(index).dispose();
  });

  Future<void> _pickPicture() async {
    if (_saving) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 78,
      maxWidth: 1400,
    );
    if (picked == null || !mounted) return;
    setState(() => _picture = File(picked.path));
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _loadingCustomers = true;
      _customerError = null;
    });
    try {
      final customers = await ref
          .read(sellerCustomersRepositoryProvider)
          .getCustomersForOrder();
      if (!mounted) return;
      setState(() {
        _customers = customers;
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
    final customer = _selectedCustomer;
    if (customer == null) {
      SnackbarService().showErrorSnackBar('Please select a customer.');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      SnackbarService().showErrorSnackBar(
        'Please fill all required fields before submitting.',
      );
      return;
    }

    // Resolve category / brand: send the id string, or "other" + a title.
    final categoryId = _categoryValue;
    final categoryTitle = categoryId == _kOtherLookupValue
        ? _newCategory.text.trim()
        : null;
    if (categoryId == _kOtherLookupValue && (categoryTitle?.isEmpty ?? true)) {
      SnackbarService().showErrorSnackBar('Please enter the new category name.');
      return;
    }
    final brandId = _brandValue;
    final brandTitle = brandId == _kOtherLookupValue
        ? _newBrand.text.trim()
        : null;
    if (brandId == _kOtherLookupValue && (brandTitle?.isEmpty ?? true)) {
      SnackbarService().showErrorSnackBar('Please enter the new brand name.');
      return;
    }

    // Build aligned spec pairs, skipping rows where both fields are empty.
    final detailTitles = <String>[];
    final detailValues = <String>[];
    for (final spec in _specs) {
      final t = spec.title.text.trim();
      final v = spec.value.text.trim();
      if (t.isEmpty && v.isEmpty) continue;
      detailTitles.add(t);
      detailValues.add(v);
    }

    final price = _productPrice.text.trim();
    final advance = _advancePrice.text.trim();
    final total = _totalDealPreview;

    setState(() => _saving = true);
    try {
      await ref
          .read(sellerCustomOrdersRepositoryProvider)
          .storeCustomOrder(
            customerId: customer.id.toString(),
            categoryId: categoryId,
            categoryTitle: categoryTitle,
            brandId: brandId,
            brandTitle: brandTitle,
            productTitle: _productTitle.text.trim().isEmpty
                ? null
                : _productTitle.text.trim(),
            productPrice: price.isEmpty ? null : price,
            advancePrice: advance.isEmpty ? null : advance,
            detailTitles: detailTitles,
            detailValues: detailValues,
            tenureMonths: _tenure.text.trim().isEmpty
                ? null
                : _tenure.text.trim(),
            perMonthPercentage: _perMonthPercentage.text.trim().isEmpty
                ? null
                : _perMonthPercentage.text.trim(),
            totalDealPrice: total > 0 ? total.round().toString() : null,
            picture: _picture,
          );
      if (!mounted) return;
      ref.invalidate(sellerCustomOrdersProvider);
      ref.invalidate(sellerCustomOrdersPendingCountProvider);
      ref.invalidate(sellerCustomOrdersStatusCountsProvider);
      SnackbarService().showSuccessSnackBar('Custom order created successfully.');
      Navigator.pop(context, true);
    } catch (e, st) {
      debugPrint('[CreateCustomOrder] ERROR: $e');
      debugPrint('[CreateCustomOrder] STACK: $st');
      SnackbarService().showErrorSnackBar(_cleanCreateError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final categories = ref.watch(sellerCustomOrderCategoriesProvider);
    final brands = ref.watch(sellerCustomOrderBrandsProvider);

    return _SheetShell(
      title: 'Create Custom Order',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Customer (required) ────────────────────────
            _CustomerSelectCard(
              customer: _selectedCustomer,
              loading: _loadingCustomers,
              error: _customerError,
              count: _customers.length,
              enabled: !_saving,
              locked: widget.initialCustomer != null,
              onTap: _pickCustomer,
              onRetry: _loadCustomers,
            ),
            const Gap.v(AppSpace.md),

            // ── Category ───────────────────────────────────
            _CreateLookupDropdown(
              label: 'Category',
              icon: Icons.category_outlined,
              value: _categoryValue,
              enabled: !_saving,
              lookups: categories,
              onChanged: (v) => setState(() => _categoryValue = v),
            ),
            if (_categoryValue == _kOtherLookupValue) ...[
              const Gap.v(AppSpace.sm),
              _CreateTextField(
                controller: _newCategory,
                label: 'New category',
                icon: Icons.add_circle_outline_rounded,
                enabled: !_saving,
              ),
            ],
            const Gap.v(AppSpace.sm),

            // ── Brand ──────────────────────────────────────
            _CreateLookupDropdown(
              label: 'Brand',
              icon: Icons.sell_outlined,
              value: _brandValue,
              enabled: !_saving,
              lookups: brands,
              onChanged: (v) => setState(() => _brandValue = v),
            ),
            if (_brandValue == _kOtherLookupValue) ...[
              const Gap.v(AppSpace.sm),
              _CreateTextField(
                controller: _newBrand,
                label: 'New brand',
                icon: Icons.add_circle_outline_rounded,
                enabled: !_saving,
              ),
            ],
            const Gap.v(AppSpace.sm),

            // ── Product ────────────────────────────────────
            _CreateTextField(
              controller: _productTitle,
              label: 'Product title',
              icon: Icons.inventory_2_outlined,
              enabled: !_saving,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Product title is required'
                  : null,
            ),
            const Gap.v(AppSpace.sm),
            _CreateNumberField(
              controller: _productPrice,
              label: 'Product price',
              icon: Icons.payments_outlined,
              enabled: !_saving,
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return 'Product price is required';
                if (double.tryParse(value) == null) return 'Enter a valid price';
                return null;
              },
            ),
            const Gap.v(AppSpace.sm),
            _CreateNumberField(
              controller: _advancePrice,
              label: 'Advance price',
              icon: Icons.savings_outlined,
              enabled: !_saving,
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return null;
                if (double.tryParse(value) == null) {
                  return 'Enter a valid amount';
                }
                return null;
              },
            ),
            const Gap.v(AppSpace.md),

            // ── Specifications ─────────────────────────────
            Row(
              children: [
                Text('Specifications', style: text.titleSm),
                const Spacer(),
                SellerButton.secondary(
                  label: 'Add',
                  icon: Icons.add_rounded,
                  size: SellerButtonSize.small,
                  expand: false,
                  onPressed: _saving ? null : _addSpec,
                ),
              ],
            ),
            if (_specs.isEmpty) ...[
              const Gap.v(AppSpace.xs),
              Text('No specifications added.', style: text.caption),
            ],
            for (var i = 0; i < _specs.length; i++) ...[
              const Gap.v(AppSpace.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _CreateTextField(
                      controller: _specs[i].title,
                      label: 'Title',
                      icon: Icons.label_outline_rounded,
                      enabled: !_saving,
                    ),
                  ),
                  const Gap.h(AppSpace.sm),
                  Expanded(
                    child: _CreateTextField(
                      controller: _specs[i].value,
                      label: 'Value',
                      icon: Icons.short_text_rounded,
                      enabled: !_saving,
                    ),
                  ),
                  const Gap.h(AppSpace.xs),
                  _SquareIconButton(
                    icon: Icons.close_rounded,
                    tone: c.dangerTone,
                    onTap: _saving ? () {} : () => _removeSpec(i),
                  ),
                ],
              ),
            ],
            const Gap.v(AppSpace.md),

            // ── Product picture ────────────────────────────
            _PicturePickerCard(
              picture: _picture,
              enabled: !_saving,
              onTap: _pickPicture,
              onClear: _saving ? null : () => setState(() => _picture = null),
            ),
            const Gap.v(AppSpace.md),

            // ── Installment plan ───────────────────────────
            Text('Installment plan', style: text.titleSm),
            const Gap.v(AppSpace.sm),
            Row(
              children: [
                Expanded(
                  child: _CreateNumberField(
                    controller: _tenure,
                    label: 'Tenure (months)',
                    icon: Icons.calendar_month_outlined,
                    enabled: !_saving,
                  ),
                ),
                const Gap.h(AppSpace.sm),
                Expanded(
                  child: _CreateNumberField(
                    controller: _perMonthPercentage,
                    label: 'Monthly %',
                    icon: Icons.percent_rounded,
                    decimal: true,
                    enabled: !_saving,
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return null;
                      final pct = double.tryParse(value);
                      if (pct == null) return 'Invalid';
                      if (pct < 0 || pct > 6) return '0 – 6';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const Gap.v(AppSpace.sm),
            _TotalDealPreview(amount: _totalDealPreview),
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

/// Read-only preview of the computed total deal price.
class _TotalDealPreview extends StatelessWidget {
  final double amount;
  const _TotalDealPreview({required this.amount});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm + 2,
      ),
      decoration: BoxDecoration(
        color: c.accentSurface,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: c.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.price_check_rounded, size: 18, color: c.accent),
          const Gap.h(AppSpace.sm),
          Expanded(
            child: Text('Total Deal Price', style: text.bodySm),
          ),
          Text(
            _formatRs(amount.round()),
            style: text.bodyLg.copyWith(
              color: c.accent,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Optional product-picture picker tile (gallery).
class _PicturePickerCard extends StatelessWidget {
  final File? picture;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _PicturePickerCard({
    required this.picture,
    required this.enabled,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final pic = picture;
    return SellerCard(
      color: c.surfaceAlt,
      borderColor: c.border,
      elevated: false,
      padding: const EdgeInsets.all(AppSpace.sm + 2),
      onTap: enabled ? onTap : null,
      child: Row(
        children: [
          if (pic == null)
            SellerIconBadge(
              icon: Icons.image_outlined,
              tone: c.accentTone,
            )
          else
            ClipRRect(
              borderRadius: AppRadius.brSm,
              child: Image.file(
                pic,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
              ),
            ),
          const Gap.h(AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pic == null ? 'Add product picture' : 'Product picture',
                  style: text.bodyLg.copyWith(fontWeight: FontWeight.w700),
                ),
                const Gap.v(2),
                Text(
                  pic == null ? 'Optional · from gallery' : 'Tap to replace',
                  style: text.caption,
                ),
              ],
            ),
          ),
          if (pic != null && onClear != null)
            IconButton(
              tooltip: 'Remove',
              onPressed: onClear,
              icon: Icon(Icons.close_rounded, color: c.textSecondary),
            )
          else
            Icon(Icons.upload_rounded, color: c.textSecondary),
        ],
      ),
    );
  }
}

/// Themed category/brand dropdown with an appended "Other…" option. Renders a
/// slim placeholder while [lookups] is loading.
class _CreateLookupDropdown extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? value;
  final bool enabled;
  final AsyncValue<List<SellerCustomOrderLookup>> lookups;
  final ValueChanged<String?> onChanged;

  const _CreateLookupDropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.enabled,
    required this.lookups,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;

    final items = <DropdownMenuItem<String>>[
      ...lookups
          .whenOrNull(
            data: (list) => list.map(
              (l) => DropdownMenuItem<String>(
                value: l.id.toString(),
                child: Text(l.title, overflow: TextOverflow.ellipsis),
              ),
            ),
          )
          ?.toList() ??
          const [],
      const DropdownMenuItem<String>(
        value: _kOtherLookupValue,
        child: Text('Other…'),
      ),
    ];

    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      style: text.body,
      dropdownColor: c.surface,
      hint: Text(
        lookups.isLoading ? 'Loading $label…' : 'Select $label (optional)',
        style: text.bodySm,
      ),
      items: items,
      onChanged: enabled ? onChanged : null,
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

/// Themed text field for the create form (optional validator).
class _CreateTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool enabled;
  final FormFieldValidator<String>? validator;

  const _CreateTextField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.enabled,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    return TextFormField(
      controller: controller,
      enabled: enabled,
      textInputAction: TextInputAction.next,
      validator: validator,
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

class _CreateNumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool enabled;
  final bool decimal;
  final FormFieldValidator<String>? validator;

  const _CreateNumberField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.enabled,
    this.decimal = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: decimal
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
          : [FilteringTextInputFormatter.digitsOnly],
      validator: validator,
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
  final bool locked;
  final VoidCallback onTap;
  final VoidCallback onRetry;

  const _CustomerSelectCard({
    required this.customer,
    required this.loading,
    required this.error,
    required this.count,
    required this.enabled,
    this.locked = false,
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
      onTap: enabled && !loading && !hasError && !locked ? onTap : null,
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
          else if (!locked)
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

  String _customerLocation(SellerCustomer c) {
    final city = c.profile.cityTitle.isNotEmpty
        ? c.profile.cityTitle
        : 'City ${c.profile.cityId}';
    final area = c.profile.areaTitle.isNotEmpty
        ? c.profile.areaTitle
        : 'Area ${c.profile.areaId}';
    return '$city · $area';
  }

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
                  _customerLocation(customer),
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
                const Gap.v(AppSpace.sm),
                Row(
                  children: [
                    Expanded(child: Text(title, style: text.titleMd)),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded, color: c.textSecondary),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Close',
                    ),
                  ],
                ),
                const Gap.v(AppSpace.sm),
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

/// Formats an integer amount as `Rs 1,234,567` with thousands separators.
String _formatRs(int amount) {
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return 'Rs ${amount < 0 ? '-' : ''}$buffer';
}

String _cleanCreateError(Object error) {
  final text = error.toString().replaceFirst('Exception: ', '').trim();
  return text.isEmpty ? 'Something went wrong. Please try again.' : text;
}
