// ============================================================
//  seller_standard_orders_screen.dart — Design System v2
//
//  List + Detail screens for Standard Orders, reskinned onto
//  the Seller Design System.  All business logic, providers,
//  pagination, PDF action, status update and create-order flow
//  are preserved 100%.
// ============================================================

import 'package:atompro/core/seller_plan_upgrade_exception.dart';
import 'package:atompro/core/services/snackbar_services.dart';
import 'package:atompro/features/seller/core/design/design.dart';
import 'package:atompro/features/seller/core/widgets/widgets.dart';
import 'package:atompro/features/seller/customers/model/seller_customers_model.dart';
import 'package:atompro/features/seller/customers/repository/seller_customers_repository.dart';
import 'package:atompro/features/seller/standard_orders/model/seller_standard_orders_model.dart';
import 'package:atompro/features/seller/standard_orders/repository/seller_standard_orders_repository.dart';
import 'package:atompro/features/seller/standard_orders/viewmodel/seller_standard_orders_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

// ═══════════════════════════════════════════════════════════
//  LIST SCREEN
// ═══════════════════════════════════════════════════════════

class SellerStandardOrdersScreen extends ConsumerStatefulWidget {
  const SellerStandardOrdersScreen({super.key});

  @override
  ConsumerState<SellerStandardOrdersScreen> createState() =>
      _SellerStandardOrdersScreenState();
}

class _SellerStandardOrdersScreenState
    extends ConsumerState<SellerStandardOrdersScreen> {
  int _page = 1;

  Future<void> _showCreateSheet() =>
      showSellerCreateStandardOrderSheet(context, ref);

  void _refresh() => ref.invalidate(sellerStandardOrdersProvider(_page));

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final state = ref.watch(sellerStandardOrdersProvider(_page));

    return Scaffold(
      backgroundColor: c.canvas,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'seller_add_standard_order',
        onPressed: _showCreateSheet,
        backgroundColor: c.accent,
        foregroundColor: c.onAccent,
        icon: const Icon(Icons.add_shopping_cart_outlined),
        label: const Text('Create'),
      ),
      body: RefreshIndicator(
        color: c.accent,
        backgroundColor: c.surface,
        onRefresh: () async {
          _refresh();
          await ref.read(sellerStandardOrdersProvider(_page).future);
        },
        child: state.when(
          loading: () => SellerListSkeleton(count: 5, itemHeight: 116),
          error: (error, _) => error is SellerPlanUpgradeException
              ? SellerPlanGateState(exception: error)
              : SellerErrorState(
                  message: _cleanError(error),
                  onRetry: _refresh,
                ),
          data: (data) => data.gate != null
              ? SellerPlanGateState(exception: data.gate!)
              : ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: AppInsets.pageWithNav,
            children: [
              // ── Summary strip ────────────────────────────────────
              _SummaryStrip(data: data),
              const Gap.v(AppSpace.sm),
              // ── Empty or order list ──────────────────────────────
              if (data.orders.isEmpty)
                SellerEmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No standard orders found',
                  message: 'Tap Create to place your first standard order.',
                )
              else
                for (final order in data.orders) ...[
                  _OrderCard(
                    order: order,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SellerStandardOrderDetailsScreen(
                          orderUuid: order.uuid,
                          initialOrder: order,
                        ),
                      ),
                    ),
                  ),
                  const Gap.v(AppSpace.sm),
                ],
              // ── Pagination ───────────────────────────────────────
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
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  DETAIL SCREEN
// ═══════════════════════════════════════════════════════════

class SellerStandardOrderDetailsScreen extends ConsumerWidget {
  final String orderUuid;
  final SellerStandardOrder? initialOrder;

  const SellerStandardOrderDetailsScreen({
    super.key,
    required this.orderUuid,
    this.initialOrder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Wrap in SellerThemeScope — this screen is pushed as its own route.
    return SellerThemeScope(
      child: Builder(
        builder: (context) {
          final c = context.sellerColors;
          final state = ref.watch(sellerStandardOrderDetailsProvider(orderUuid));

          return Scaffold(
            backgroundColor: c.canvas,
            appBar: AppBar(
              backgroundColor: c.canvas,
              surfaceTintColor: Colors.transparent,
              title: Text('Standard Order', style: context.sellerText.titleMd),
              actions: [
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: () =>
                      ref.invalidate(sellerStandardOrderDetailsProvider(orderUuid)),
                  icon: Icon(Icons.refresh_rounded, color: c.textSecondary),
                ),
              ],
            ),
            body: state.when(
              loading: () => _DetailLoading(
                initialOrder: initialOrder,
                c: c,
              ),
              error: (error, _) => error is SellerPlanUpgradeException
                  ? SellerPlanGateState(exception: error)
                  : SellerErrorState(
                      message: _cleanError(error),
                      onRetry: () =>
                          ref.invalidate(sellerStandardOrderDetailsProvider(orderUuid)),
                    ),
              data: (details) => RefreshIndicator(
                color: c.accent,
                backgroundColor: c.surface,
                onRefresh: () async {
                  ref.invalidate(sellerStandardOrderDetailsProvider(orderUuid));
                  await ref.read(
                    sellerStandardOrderDetailsProvider(orderUuid).future,
                  );
                },
                child: ListView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: AppInsets.pageWithNav,
                  children: [
                    _DetailHero(
                      order: details.order,
                      onStatus: () => _showStatusSheet(
                        context: context,
                        ref: ref,
                        orderUuid: orderUuid,
                        currentStatus: details.order.status,
                      ),
                      onPdf: () => _openPdf(context, ref, orderUuid),
                    ),
                    const Gap.v(AppSpace.md),
                    // ── Customer section ─────────────────────────────
                    SellerCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _CardSectionHeader(
                            icon: Icons.person_outline_rounded,
                            title: 'Customer',
                            tone: context.sellerColors.infoTone,
                          ),
                          Divider(color: c.divider, height: 1),
                          Padding(
                            padding: const EdgeInsets.all(AppSpace.md),
                            child: Column(
                              children: [
                                SellerDataRow(label: 'Name', value: details.user.name),
                                SellerDataRow(label: 'Phone', value: details.user.phone),
                                SellerDataRow(label: 'Email', value: details.user.email),
                                SellerDataRow(label: 'Status', value: details.user.status),
                                SellerDataRow(
                                  label: 'Joined',
                                  value: details.user.joinedThrough,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap.v(AppSpace.md),
                    // ── Verification section ─────────────────────────
                    SellerCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _CardSectionHeader(
                            icon: Icons.verified_user_outlined,
                            title: 'Verification',
                            tone: context.sellerColors.successTone,
                          ),
                          Divider(color: c.divider, height: 1),
                          Padding(
                            padding: const EdgeInsets.all(AppSpace.md),
                            child: Column(
                              children: [
                                SellerDataRow(
                                  label: 'Identifier',
                                  value: details.user.customer.identifier,
                                ),
                                SellerDataRow(
                                  label: 'KYC',
                                  value: details.user.customer.verified
                                      ? 'Verified'
                                      : 'Not verified',
                                  emphasize: details.user.customer.verified,
                                ),
                                SellerDataRow(
                                  label: 'CNIC',
                                  value: details.user.customer.cnicNo,
                                ),
                                SellerDataRow(
                                  label: 'Father name',
                                  value: details.user.customer.fatherName,
                                ),
                                SellerDataRow(
                                  label: 'Residence',
                                  value: details.user.customer.residencePhone,
                                ),
                                SellerDataRow(
                                  label: 'Address',
                                  value: details.user.customer.address,
                                ),
                                SellerDataRow(
                                  label: 'Office',
                                  value: details.user.customer.officeAddress,
                                ),
                                SellerDataRow(
                                  label: 'Office phone',
                                  value: details.user.customer.officePhone,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ── Status history ───────────────────────────────
                    if (details.statusHistory.isNotEmpty) ...[
                      const Gap.v(AppSpace.md),
                      SellerCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _CardSectionHeader(
                              icon: Icons.timeline_rounded,
                              title: 'Status History',
                              tone: context.sellerColors.violetTone,
                            ),
                            Divider(color: c.divider, height: 1),
                            Padding(
                              padding: const EdgeInsets.all(AppSpace.md),
                              child: Column(
                                children: details.statusHistory
                                    .map(
                                      (item) => SellerDataRow(
                                        label: item.status,
                                        value:
                                            '${item.comment} (${item.formattedCreatedAt})',
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    // ── Instalments ──────────────────────────────────
                    if (details.instalments.isNotEmpty) ...[
                      const Gap.v(AppSpace.md),
                      SellerCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _CardSectionHeader(
                              icon: Icons.payments_outlined,
                              title: 'Instalments',
                              tone: context.sellerColors.warningTone,
                            ),
                            Divider(color: c.divider, height: 1),
                            Padding(
                              padding: const EdgeInsets.all(AppSpace.md),
                              child: Column(
                                children: details.instalments
                                    .map(
                                      (item) => SellerDataRow(
                                        label: item.month,
                                        value:
                                            '${item.formattedPrice} — ${item.status}',
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  LIST WIDGETS
// ═══════════════════════════════════════════════════════════

/// One-line summary card: total record count + pending count.
class _SummaryStrip extends StatelessWidget {
  final SellerStandardOrdersResponse data;
  const _SummaryStrip({required this.data});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final pag = data.pagination;
    final rangeLabel = pag.total == 0
        ? '0 records'
        : '${pag.from ?? 0}–${pag.to ?? 0} of ${pag.total}';

    return SellerCard(
      child: Row(
        children: [
          SellerIconBadge(
            icon: Icons.receipt_long_outlined,
            tone: c.accentTone,
            size: 42,
            iconSize: 20,
          ),
          const Gap.h(AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Standard Orders', style: text.titleSm),
                const Gap.v(AppSpace.xxs),
                Text(rangeLabel, style: text.caption),
              ],
            ),
          ),
          if (data.pendingCount > 0)
            SellerStatusPill(
              label: '${data.pendingCount} pending',
              tone: c.warningTone,
            ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final SellerStandardOrder order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final tone = SellerStatus.toneFor(order.status, c);

    return SellerCard(
      onTap: onTap,
      accentEdge: tone.fg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────
          Row(
            children: [
              SellerIconBadge(
                icon: Icons.receipt_long_outlined,
                tone: tone,
                size: 42,
                iconSize: 20,
              ),
              const Gap.h(AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.id}',
                      style: text.titleSm,
                    ),
                    const Gap.v(AppSpace.xxs),
                    Text(
                      '${order.portal} · ${order.formattedCreatedAt}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.caption,
                    ),
                  ],
                ),
              ),
              SellerStatusPill(label: order.status),
            ],
          ),
          const Gap.v(AppSpace.sm),
          Divider(color: c.divider, height: 1),
          const Gap.v(AppSpace.sm),
          // ── Mini metrics row ─────────────────────────────
          Row(
            children: [
              Expanded(
                child: _MiniStat(label: 'Cart', value: '${order.cartId}'),
              ),
              _VertDivider(),
              Expanded(
                child: _MiniStat(label: 'User', value: '${order.userId}'),
              ),
              _VertDivider(),
              Expanded(
                child: _MiniStat(label: 'Portal', value: order.portal),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final text = context.sellerText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: text.caption),
        const Gap.v(AppSpace.xxs),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.labelSm.copyWith(
            color: context.sellerColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
      color: context.sellerColors.divider,
    );
  }
}

class _PaginationBar extends StatelessWidget {
  final SellerStandardOrdersPagination pagination;
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

    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.xs),
      child: Row(
        children: [
          Expanded(
            child: SellerButton.secondary(
              label: 'Previous',
              icon: Icons.chevron_left_rounded,
              onPressed: onPrevious,
            ),
          ),
          const Gap.h(AppSpace.sm),
          Text(
            '${pagination.currentPage}/${pagination.lastPage}',
            style: text.labelSm.copyWith(color: c.textSecondary),
          ),
          const Gap.h(AppSpace.sm),
          Expanded(
            child: SellerButton.secondary(
              label: 'Next',
              trailingIcon: Icons.chevron_right_rounded,
              onPressed: onNext,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  DETAIL WIDGETS
// ═══════════════════════════════════════════════════════════

class _DetailHero extends StatelessWidget {
  final SellerStandardOrder order;
  final VoidCallback onStatus;
  final VoidCallback onPdf;

  const _DetailHero({
    required this.order,
    required this.onStatus,
    required this.onPdf,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;

    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        gradient: c.headerGradient,
        borderRadius: AppRadius.brXl,
        boxShadow: [
          BoxShadow(
            color: c.gradientEnd.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title + status ──────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  'Order #${order.id}',
                  style: text.titleLg.copyWith(color: Colors.white),
                ),
              ),
              SellerStatusPill(label: order.status),
            ],
          ),
          const Gap.v(AppSpace.xxs),
          Text(
            order.uuid,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
          const Gap.v(AppSpace.md),
          // ── Metric row ──────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: 'Deal',
                  value: order.formattedTotalDealPrice,
                ),
              ),
              Expanded(
                child: _HeroMetric(
                  label: 'Advance',
                  value: order.formattedAdvancePrice,
                ),
              ),
              Expanded(
                child: _HeroMetric(
                  label: 'Tenure',
                  value: '${order.instalmentTenure} mo.',
                ),
              ),
            ],
          ),
          const Gap.v(AppSpace.md),
          // ── Actions ─────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: SellerButton.secondary(
                  label: 'Status',
                  icon: Icons.edit_note_rounded,
                  onPressed: onStatus,
                ),
              ),
              const Gap.h(AppSpace.sm),
              Expanded(
                child: SellerButton.secondary(
                  label: 'PDF',
                  icon: Icons.picture_as_pdf_outlined,
                  onPressed: onPdf,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HeroMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.sellerText.caption.copyWith(
            color: Colors.white.withValues(alpha: 0.68),
          ),
        ),
        const Gap.v(AppSpace.xxs),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: context.sellerText.titleSm.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

/// Header row inside a detail SellerCard section (icon + title).
class _CardSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final SellerTone tone;

  const _CardSectionHeader({
    required this.icon,
    required this.title,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final text = context.sellerText;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        AppSpace.sm,
        AppSpace.md,
        AppSpace.sm,
      ),
      child: Row(
        children: [
          SellerIconBadge(icon: icon, tone: tone, size: 34, iconSize: 17),
          const Gap.h(AppSpace.sm),
          Expanded(child: Text(title, style: text.titleSm)),
        ],
      ),
    );
  }
}

class _DetailLoading extends StatelessWidget {
  final SellerStandardOrder? initialOrder;
  final SellerColors c;

  const _DetailLoading({this.initialOrder, required this.c});

  @override
  Widget build(BuildContext context) {
    if (initialOrder == null) {
      return SellerListSkeleton(count: 4, itemHeight: 100);
    }
    return ListView(
      padding: AppInsets.pageWithNav,
      children: [
        _OrderCard(order: initialOrder!, onTap: () {}),
        const Gap.v(AppSpace.lg),
        SellerListSkeleton(count: 3, itemHeight: 120),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  CREATE ORDER SHEET
// ═══════════════════════════════════════════════════════════

/// Opens the create-standard-order form. Reusable from the global + action.
Future<void> showSellerCreateStandardOrderSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final dark = context.sellerIsDark;
  final changed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Theme(
      data: dark ? SellerTheme.dark : SellerTheme.light,
      child: const _CreateOrderSheet(),
    ),
  );
  if (changed == true) ref.invalidate(sellerStandardOrdersProvider);
}

class _CreateOrderSheet extends ConsumerStatefulWidget {
  const _CreateOrderSheet();

  @override
  ConsumerState<_CreateOrderSheet> createState() => _CreateOrderSheetState();
}

class _CreateOrderSheetState extends ConsumerState<_CreateOrderSheet> {
  final _formKey = GlobalKey<FormState>();
  final _productId = TextEditingController();
  final _advance = TextEditingController();
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
    _advance.dispose();
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
        _customerError = _cleanError(e);
        _loadingCustomers = false;
      });
    }
  }

  Future<void> _pickCustomer() async {
    if (_loadingCustomers || _saving || _customers.isEmpty) return;
    final dark = context.sellerIsDark;
    final customer = await showModalBottomSheet<SellerCustomer>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Theme(
        data: dark ? SellerTheme.dark : SellerTheme.light,
        child: Builder(
          builder: (ctx) => _CustomerPickerSheet(
            customers: _customers,
            selected: _selectedCustomer,
          ),
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
    setState(() => _saving = true);
    try {
      await ref
          .read(sellerStandardOrdersRepositoryProvider)
          .storeOrder(
            customerId: customer.id.toString(),
            productId: _productId.text.trim(),
            areaId: customer.profile.areaId.toString(),
            cityId: customer.profile.cityId.toString(),
            minAdvancePrice: _advance.text.trim(),
            tenureMonths: _tenure.text.trim(),
          );
      if (!mounted) return;
      SnackbarService().showSuccessSnackBar('Standard order created.');
      Navigator.pop(context, true);
    } catch (e) {
      SnackbarService().showErrorSnackBar(_cleanError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: 'Create Standard Order',
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
            _SheetNumberField(
              controller: _productId,
              label: 'Product ID',
              enabled: !_saving,
            ),
            _SheetNumberField(
              controller: _advance,
              label: 'Minimum Advance Price',
              enabled: !_saving,
            ),
            _SheetNumberField(
              controller: _tenure,
              label: 'Tenure Months',
              enabled: !_saving,
            ),
            const Gap.v(AppSpace.xs),
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

// ═══════════════════════════════════════════════════════════
//  CUSTOMER SELECT CARD
// ═══════════════════════════════════════════════════════════

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
    final text = context.sellerText;
    final selected = customer;
    final hasError = error != null;

    return SellerCard(
      onTap: (enabled && !loading && !hasError) ? onTap : null,
      borderColor: selected != null
          ? c.accent.withValues(alpha: 0.4)
          : null,
      child: Row(
        children: [
          SellerIconBadge(
            icon: loading
                ? Icons.person_search_outlined
                : Icons.person_search_outlined,
            tone: hasError ? c.dangerTone : c.accentTone,
            size: 42,
            iconSize: 20,
          ),
          const Gap.h(AppSpace.sm),
          Expanded(child: _customerBody(text, c, selected, hasError)),
          if (hasError)
            IconButton(
              tooltip: 'Retry',
              onPressed: enabled ? onRetry : null,
              icon: Icon(Icons.refresh_rounded, color: c.textTertiary),
            )
          else if (loading)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: c.accent,
              ),
            )
          else
            Icon(Icons.keyboard_arrow_down_rounded, color: c.textTertiary),
        ],
      ),
    );
  }

  Widget _customerBody(
    SellerTextTheme text,
    SellerColors c,
    SellerCustomer? selected,
    bool hasError,
  ) {
    if (loading) {
      return Text('Loading customers…', style: text.body);
    }
    if (hasError) {
      return Text(
        error!,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: text.bodySm.copyWith(color: c.danger),
      );
    }
    if (selected == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Customer', style: text.titleSm),
          const Gap.v(AppSpace.xxs),
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
          style: text.titleSm,
        ),
        const Gap.v(AppSpace.xxs),
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

// ═══════════════════════════════════════════════════════════
//  CUSTOMER PICKER SHEET
// ═══════════════════════════════════════════════════════════

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
              // Drag handle
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
              Text('Select Customer', style: text.titleMd),
              const Gap.v(AppSpace.sm),
              SellerSearchField(
                hint: 'Search name, phone, email…',
                controller: _search,
                onChanged: (_) => setState(() {}),
              ),
              const Gap.v(AppSpace.sm),
              Expanded(
                child: customers.isEmpty
                    ? Center(
                        child: Text(
                          'No matching customers.',
                          style: text.bodySm,
                        ),
                      )
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: customers.length,
                        separatorBuilder: (_, _) => const Gap.v(AppSpace.xs),
                        itemBuilder: (_, index) {
                          final customer = customers[index];
                          return _CustomerPickerTile(
                            customer: customer,
                            selected: customer.id == widget.selected?.id,
                            onTap: () => Navigator.pop(context, customer),
                          );
                        },
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
      onTap: onTap,
      color: selected ? c.accentSurface : null,
      borderColor: selected ? c.accent.withValues(alpha: 0.4) : null,
      child: Row(
        children: [
          SellerIconBadge(
            icon: selected
                ? Icons.check_circle_outline_rounded
                : Icons.person_outline_rounded,
            tone: selected ? c.accentTone : c.neutralTone,
            size: 42,
            iconSize: 20,
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
                  style: text.titleSm,
                ),
                const Gap.v(AppSpace.xxs),
                Text(
                  customer.phone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySm,
                ),
                const Gap.v(AppSpace.xxs),
                Text(
                  'ID ${customer.id} · City ${customer.profile.cityId} · Area ${customer.profile.areaId}',
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

// ═══════════════════════════════════════════════════════════
//  STATUS UPDATE SHEET
// ═══════════════════════════════════════════════════════════

class _StatusUpdateSheet extends ConsumerStatefulWidget {
  final String orderUuid;
  final String currentStatus;

  const _StatusUpdateSheet({
    required this.orderUuid,
    required this.currentStatus,
  });

  @override
  ConsumerState<_StatusUpdateSheet> createState() => _StatusUpdateSheetState();
}

class _StatusUpdateSheetState extends ConsumerState<_StatusUpdateSheet> {
  final _formKey = GlobalKey<FormState>();
  final _receivedBy = TextEditingController();
  late String _status = _statusOptions.contains(widget.currentStatus)
      ? widget.currentStatus
      : _statusOptions.first;
  bool _saving = false;

  static const _statusOptions = [
    'Pending',
    'Varification',
    'Processing',
    'Delivered',
    'Instalments',
    'Completed',
    'Cancelled',
  ];

  @override
  void dispose() {
    _receivedBy.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(sellerStandardOrdersRepositoryProvider)
          .updateStatus(
            orderUuid: widget.orderUuid,
            status: _status,
            receivedBy: _receivedBy.text.trim(),
          );
      if (!mounted) return;
      Navigator.pop(context, true);
      SnackbarService().showSuccessSnackBar('Order status updated.');
    } catch (e) {
      SnackbarService().showErrorSnackBar(_cleanError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;

    return _SheetShell(
      title: 'Update Status',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: _sheetDecoration(context, 'Status'),
              dropdownColor: c.surface,
              items: _statusOptions
                  .map(
                    (status) =>
                        DropdownMenuItem(value: status, child: Text(status)),
                  )
                  .toList(),
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _status = value ?? _status),
            ),
            const Gap.v(AppSpace.sm),
            _SheetTextField(
              controller: _receivedBy,
              label: 'Received By',
              enabled: !_saving,
              validator: (value) {
                if (_status == 'Delivered' &&
                    (value == null || value.trim().isEmpty)) {
                  return 'Receiver name is required.';
                }
                return null;
              },
            ),
            const Gap.v(AppSpace.xs),
            SellerButton(
              label: 'Save Status',
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

// ═══════════════════════════════════════════════════════════
//  SHEET SHELL + FORM FIELDS
// ═══════════════════════════════════════════════════════════

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
                // Drag handle
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

class _SheetTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool enabled;
  final String? Function(String?)? validator;

  const _SheetTextField({
    required this.controller,
    required this.label,
    required this.enabled,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        validator: validator,
        decoration: _sheetDecoration(context, label),
      ),
    );
  }
}

class _SheetNumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool enabled;

  const _SheetNumberField({
    required this.controller,
    required this.label,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: _requiredNumber,
        decoration: _sheetDecoration(context, label),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  HELPERS
// ═══════════════════════════════════════════════════════════

InputDecoration _sheetDecoration(BuildContext context, String label) {
  final c = context.sellerColors;
  return InputDecoration(
    labelText: label,
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
      borderSide: BorderSide(color: c.accent, width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: AppRadius.brMd,
      borderSide: BorderSide(color: c.danger),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: AppRadius.brMd,
      borderSide: BorderSide(color: c.danger, width: 1.4),
    ),
  );
}

Future<void> _showStatusSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String orderUuid,
  required String currentStatus,
}) async {
  final dark = context.sellerIsDark;
  final changed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Theme(
      data: dark ? SellerTheme.dark : SellerTheme.light,
      child: Builder(
        builder: (ctx) => _StatusUpdateSheet(
          orderUuid: orderUuid,
          currentStatus: currentStatus,
        ),
      ),
    ),
  );
  if (changed == true) {
    ref.invalidate(sellerStandardOrderDetailsProvider(orderUuid));
  }
}

Future<void> _openPdf(
  BuildContext context,
  WidgetRef ref,
  String orderUuid,
) async {
  try {
    final url = await ref
        .read(sellerStandardOrdersRepositoryProvider)
        .getPdfUrl(orderUuid);
    final uri = Uri.parse(url);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) throw Exception('Could not open PDF.');
  } catch (e) {
    SnackbarService().showErrorSnackBar(_cleanError(e));
  }
}

String? _requiredNumber(String? value) {
  final number = int.tryParse(value?.trim() ?? '');
  if (number == null || number <= 0) return 'Required';
  return null;
}

String _cleanError(Object error) {
  final text = error.toString().replaceFirst('Exception: ', '').trim();
  return text.isEmpty ? 'Something went wrong. Please try again.' : text;
}
