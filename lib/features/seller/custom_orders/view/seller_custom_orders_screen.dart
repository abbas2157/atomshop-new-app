// ═══════════════════════════════════════════════════════════════════════════
//  seller_custom_orders_screen.dart  —  Premium Redesign v2
//  All Riverpod / business logic untouched.
//  Pure UI / UX transformation.
// ═══════════════════════════════════════════════════════════════════════════

import 'package:atompro/core/services/snackbar_services.dart';
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
//  DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────
abstract final class _D {
  // Brand
  static const brand = Color(0xFF3B5BDB);
  static const brandDeep = Color(0xFF1A2980);
  static const brandSoft = Color(0xFFEBEFFE);

  // Semantics
  static const success = Color(0xFF10B981);
  static const successBg = Color(0xFFD1FAE5);
  static const warning = Color(0xFFF59E0B);
  static const warningBg = Color(0xFFFEF3C7);
  static const danger = Color(0xFFEF4444);
  static const dangerBg = Color(0xFFFEE2E2);
  static const info = Color(0xFF06B6D4);
  static const infoBg = Color(0xFFCFFAFE);
  static const violet = Color(0xFF8B5CF6);

  // Neutrals
  static const bg = Color(0xFFF4F6FC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF8FAFE);
  static const border = Color(0xFFE4E8F5);
  static const divider = Color(0xFFF0F2F9);
  static const txt1 = Color(0xFF0A0F1E);
  static const txt2 = Color(0xFF6B7280);
  static const txt3 = Color(0xFF9CA3AF);

  // Radius
  static const r8 = BorderRadius.all(Radius.circular(8));
  static const r12 = BorderRadius.all(Radius.circular(12));
  static const r14 = BorderRadius.all(Radius.circular(14));
  static const r16 = BorderRadius.all(Radius.circular(16));
  static const r32 = BorderRadius.all(Radius.circular(32));
}

// ─────────────────────────────────────────────────────────────────────────────
//  STATUS COLOUR HELPER
// ─────────────────────────────────────────────────────────────────────────────
({Color fg, Color bg}) _statusColors(String status) {
  final s = status.toLowerCase();
  if (s.contains('complete') || s.contains('deliver')) {
    return (fg: _D.success, bg: _D.successBg);
  }
  if (s.contains('pending')) return (fg: _D.warning, bg: _D.warningBg);
  if (s.contains('cancel')) return (fg: _D.danger, bg: _D.dangerBg);
  if (s.contains('verif')) return (fg: _D.info, bg: _D.infoBg);
  return (fg: _D.brand, bg: _D.brandSoft);
}

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
    extends ConsumerState<SellerCustomOrdersScreen>
    with SingleTickerProviderStateMixin {
  // ── Controllers ──────────────────────────────────────────
  final _keywordCtrl = TextEditingController();
  final _minPriceCtrl = TextEditingController();
  final _maxPriceCtrl = TextEditingController();

  // ── State ────────────────────────────────────────────────
  SellerCustomOrdersQuery _query = const SellerCustomOrdersQuery();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _filterExpanded = false;

  // ── Entry animation ──────────────────────────────────────
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _keywordCtrl.dispose();
    _minPriceCtrl.dispose();
    _maxPriceCtrl.dispose();
    _fadeCtrl.dispose();
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

  Future<void> _showCreateSheet() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreateCustomOrderSheet(),
    );
    if (created == true) _invalidateOrders();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(
            ctx,
          ).colorScheme.copyWith(primary: _D.brand, onPrimary: Colors.white),
        ),
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
    final ordersState = ref.watch(sellerCustomOrdersProvider(_query));
    final pendingCountState = ref.watch(sellerCustomOrdersPendingCountProvider);
    final statusCountsState = ref.watch(sellerCustomOrdersStatusCountsProvider);
    final pendingCount = pendingCountState.whenOrNull(data: (value) => value);
    final statusCounts = statusCountsState.whenOrNull(data: (value) => value);

    return Scaffold(
      backgroundColor: _D.bg,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'seller_add_custom_order',
        onPressed: _showCreateSheet,
        backgroundColor: _D.brand,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create'),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: RefreshIndicator(
            color: _D.brand,
            backgroundColor: _D.surface,
            strokeWidth: 2.5,
            onRefresh: () async {
              _invalidateOrders();
              await ref.read(sellerCustomOrdersProvider(_query).future);
            },
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                // ── Hero header ──────────────────────────
                SliverToBoxAdapter(
                  child: ordersState.when(
                    loading: () => _HeaderShell(
                      hasFilters: _hasFilters,
                      onReset: _resetFilters,
                      totalOrders: null,
                      pendingCount: pendingCount,
                      completedCount: null,
                    ),
                    error: (_, _) => _HeaderShell(
                      hasFilters: _hasFilters,
                      onReset: _resetFilters,
                      totalOrders: null,
                      pendingCount: pendingCount,
                      completedCount: null,
                    ),
                    data: (data) {
                      final Map<String, int> counts =
                          statusCounts?.isNotEmpty == true
                          ? statusCounts!
                          : Map<String, int>.from(data.statuses);
                      final pending =
                          pendingCount ??
                          counts.entries
                              .where(
                                (e) => e.key.toLowerCase().contains('pending'),
                              )
                              .fold<int>(0, (s, e) => s + e.value);
                      final completed = counts.entries
                          .where(
                            (e) =>
                                e.key.toLowerCase().contains('complete') ||
                                e.key.toLowerCase().contains('deliver'),
                          )
                          .fold<int>(0, (s, e) => s + e.value);
                      return _HeaderShell(
                        hasFilters: _hasFilters,
                        onReset: _resetFilters,
                        totalOrders: data.pagination.total,
                        pendingCount: pending,
                        completedCount: completed,
                      );
                    },
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── Filter panel ─────────────────
                      _CollapsibleFilterPanel(
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
                      const SizedBox(height: 16),

                      // ── Content ───────────────────────
                      ordersState.when(
                        loading: () => const _OrdersShimmer(),
                        error: (e, _) => _ErrorCard(
                          message: e.toString().replaceFirst('Exception: ', ''),
                          onRetry: () => ref.invalidate(
                            sellerCustomOrdersProvider(_query),
                          ),
                        ),
                        data: (data) => _OrdersContent(
                          data: data,
                          statusCounts: statusCounts,
                          selectedStatus: _query.status,
                          onStatusSelect: _selectStatus,
                          onPage: _goToPage,
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HEADER SHELL
// ─────────────────────────────────────────────────────────────────────────────
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
    final customer = await showModalBottomSheet<SellerCustomer>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CustomerPickerSheet(
        customers: _customers,
        selected: _selectedCustomer,
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
    return _CreateSheetShell(
      title: 'Create Custom Order',
      child: Form(
        key: _formKey,
        child: Column(
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
            const SizedBox(height: 12),
            _CreateNumberField(
              controller: _productId,
              label: 'Product ID',
              icon: Icons.inventory_2_outlined,
              enabled: !_saving,
            ),
            _CreateNumberField(
              controller: _totalDealPrice,
              label: 'Total Deal Price',
              icon: Icons.payments_outlined,
              enabled: !_saving,
            ),
            _CreateNumberField(
              controller: _advancePrice,
              label: 'Advance Price',
              icon: Icons.savings_outlined,
              enabled: !_saving,
            ),
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
                const SizedBox(width: 10),
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
            const SizedBox(height: 6),
            SizedBox(
              height: 50,
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined, size: 18),
                label: const Text('Create Order'),
                style: FilledButton.styleFrom(
                  backgroundColor: _D.brand,
                  shape: const RoundedRectangleBorder(borderRadius: _D.r12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateSheetShell extends StatelessWidget {
  final String title;
  final Widget child;

  const _CreateSheetShell({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        decoration: const BoxDecoration(
          color: _D.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _D.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: _D.txt1,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                child,
              ],
            ),
          ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: _requiredCreateNumber,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 18),
          filled: true,
          fillColor: _D.surfaceAlt,
          border: const OutlineInputBorder(
            borderRadius: _D.r12,
            borderSide: BorderSide(color: _D.border),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: _D.r12,
            borderSide: BorderSide(color: _D.border),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: _D.r12,
            borderSide: BorderSide(color: _D.brand, width: 1.5),
          ),
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
    final selected = customer;
    final hasError = error != null;

    return InkWell(
      onTap: enabled && !loading && !hasError ? onTap : null,
      borderRadius: _D.r14,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _D.surfaceAlt,
          borderRadius: _D.r14,
          border: Border.all(
            color: selected == null
                ? _D.border
                : _D.brand.withValues(alpha: .4),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _D.brand.withValues(alpha: .1),
                borderRadius: _D.r12,
              ),
              child: loading
                  ? const Padding(
                      padding: EdgeInsets.all(11),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.person_search_outlined, color: _D.brand),
            ),
            const SizedBox(width: 12),
            Expanded(child: _body(selected, hasError)),
            if (hasError)
              IconButton(
                tooltip: 'Retry',
                onPressed: enabled ? onRetry : null,
                icon: const Icon(Icons.refresh_rounded),
              )
            else
              const Icon(Icons.keyboard_arrow_down_rounded, color: _D.txt2),
          ],
        ),
      ),
    );
  }

  Widget _body(SellerCustomer? selected, bool hasError) {
    if (loading) {
      return const Text(
        'Loading customers...',
        style: TextStyle(color: _D.txt1, fontWeight: FontWeight.w900),
      );
    }
    if (hasError) {
      return Text(
        error!,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: _D.danger,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      );
    }
    if (selected == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Customer',
            style: TextStyle(color: _D.txt1, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          Text(
            count == 0 ? 'No customers found' : '$count customers available',
            style: const TextStyle(
              color: _D.txt2,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
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
          style: const TextStyle(color: _D.txt1, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 3),
        Text(
          '${selected.phone} - City ${selected.profile.cityId}, Area ${selected.profile.areaId}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _D.txt2,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
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
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final customers = _filtered;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * .82,
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        decoration: const BoxDecoration(
          color: _D.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _D.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Customer',
                style: TextStyle(
                  color: _D.txt1,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Search name, phone, email',
                  prefixIcon: Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: _D.surfaceAlt,
                  border: OutlineInputBorder(
                    borderRadius: _D.r12,
                    borderSide: BorderSide(color: _D.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: _D.r12,
                    borderSide: BorderSide(color: _D.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: _D.r12,
                    borderSide: BorderSide(color: _D.brand, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: customers.isEmpty
                    ? const Center(
                        child: Text(
                          'No matching customers.',
                          style: TextStyle(
                            color: _D.txt2,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
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
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
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
    return InkWell(
      onTap: onTap,
      borderRadius: _D.r14,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? _D.brand.withValues(alpha: .08) : _D.surfaceAlt,
          borderRadius: _D.r14,
          border: Border.all(color: selected ? _D.brand : _D.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected
                    ? _D.brand.withValues(alpha: .14)
                    : Colors.white,
                borderRadius: _D.r12,
                border: Border.all(color: _D.border),
              ),
              child: Icon(
                selected
                    ? Icons.check_circle_outline_rounded
                    : Icons.person_outline_rounded,
                color: selected ? _D.brand : _D.txt2,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _D.txt1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    customer.phone,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _D.txt2,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'User ${customer.id} - City ${customer.profile.cityId} - Area ${customer.profile.areaId}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _D.txt2,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderShell extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onReset;
  final int? totalOrders;
  final int? pendingCount;
  final int? completedCount;

  const _HeaderShell({
    required this.hasFilters,
    required this.onReset,
    required this.totalOrders,
    required this.pendingCount,
    required this.completedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_D.brandDeep, _D.brand],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: _D.brand.withValues(alpha: 0.32),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -24,
            top: -24,
            child: _DecorCircle(size: 140, opacity: 0.06),
          ),
          Positioned(
            right: 50,
            bottom: -20,
            child: _DecorCircle(size: 80, opacity: 0.05),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(14),
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Custom Orders',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                          SizedBox(height: 1),
                          Text(
                            'Installment & deal orders',
                            style: TextStyle(
                              color: Color(0xAAFFFFFF),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (hasFilters)
                      _GlassIconBtn(
                        icon: Icons.filter_alt_off_outlined,
                        tooltip: 'Reset filters',
                        onTap: onReset,
                      ),
                  ],
                ),

                const SizedBox(height: 20),

                // Quick stats row
                Row(
                  children: [
                    Expanded(
                      child: _HeaderStat(
                        icon: Icons.layers_rounded,
                        label: 'Total',
                        value: totalOrders?.toString() ?? '—',
                      ),
                    ),
                    _VertDivider(),
                    Expanded(
                      child: _HeaderStat(
                        icon: Icons.pending_actions_rounded,
                        label: 'Pending',
                        value: pendingCount?.toString() ?? '—',
                      ),
                    ),
                    _VertDivider(),
                    Expanded(
                      child: _HeaderStat(
                        icon: Icons.check_circle_outline_rounded,
                        label: 'Completed',
                        value: completedCount?.toString() ?? '—',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DecorCircle extends StatelessWidget {
  final double size;
  final double opacity;
  const _DecorCircle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: opacity),
    ),
  );
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
      const SizedBox(height: 4),
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.6),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 44,
    color: Colors.white.withValues(alpha: 0.15),
  );
}

class _GlassIconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _GlassIconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: const BorderRadius.all(Radius.circular(11)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  COLLAPSIBLE FILTER PANEL
// ─────────────────────────────────────────────────────────────────────────────
class _CollapsibleFilterPanel extends StatelessWidget {
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

  const _CollapsibleFilterPanel({
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
    return _SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // ── Toggle header ───────────────────────────────
          InkWell(
            onTap: onToggle,
            borderRadius: expanded
                ? const BorderRadius.vertical(top: Radius.circular(14))
                : const BorderRadius.all(Radius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: _D.brandSoft,
                      borderRadius: _D.r8,
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: _D.brand,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Search & Filters',
                    style: const TextStyle(
                      color: _D.txt1,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (hasActiveFilters)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: const BoxDecoration(
                        color: _D.brand,
                        borderRadius: _D.r32,
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: const Icon(
                      Icons.expand_more_rounded,
                      color: _D.txt2,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Expandable body ─────────────────────────────
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 260),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
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
    final dateLabel = startDate == null || endDate == null
        ? 'Select date range'
        : '${_formatDate(startDate)} → ${_formatDate(endDate)}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          const Divider(height: 1, color: _D.border),
          const SizedBox(height: 14),

          // Keyword
          _FilterField(
            controller: keywordCtrl,
            label: 'Keyword — product, PR number…',
            icon: Icons.search_rounded,
            onSubmit: (_) => onApply(),
          ),
          const SizedBox(height: 10),

          // Price range
          Row(
            children: [
              Expanded(
                child: _FilterField(
                  controller: minPriceCtrl,
                  label: 'Min price',
                  icon: Icons.arrow_downward_rounded,
                  numeric: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FilterField(
                  controller: maxPriceCtrl,
                  label: 'Max price',
                  icon: Icons.arrow_upward_rounded,
                  numeric: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Date range
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDateTap,
                  icon: const Icon(Icons.date_range_rounded, size: 16),
                  label: Text(
                    dateLabel,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _D.brand,
                    side: const BorderSide(color: _D.border),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    shape: const RoundedRectangleBorder(borderRadius: _D.r12),
                  ),
                ),
              ),
              if (startDate != null || endDate != null) ...[
                const SizedBox(width: 8),
                _IconPill(
                  icon: Icons.close_rounded,
                  color: _D.danger,
                  onTap: onClearDates,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              _ActionBtn(
                label: 'Reset',
                icon: Icons.refresh_rounded,
                onTap: onReset,
                outlined: true,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionBtn(
                  label: 'Apply Filters',
                  icon: Icons.check_rounded,
                  onTap: onApply,
                  outlined: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool numeric;
  final ValueChanged<String>? onSubmit;

  const _FilterField({
    required this.controller,
    required this.label,
    required this.icon,
    this.numeric = false,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
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
      style: const TextStyle(fontSize: 13, color: _D.txt1),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12, color: _D.txt2),
        prefixIcon: Icon(icon, size: 16, color: _D.txt3),
        filled: true,
        fillColor: _D.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: const OutlineInputBorder(
          borderRadius: _D.r12,
          borderSide: BorderSide(color: _D.border),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: _D.r12,
          borderSide: BorderSide(color: _D.border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: _D.r12,
          borderSide: BorderSide(color: _D.brand, width: 1.5),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool outlined;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.outlined,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 15),
        label: Text(label, style: const TextStyle(fontSize: 13)),
        style: OutlinedButton.styleFrom(
          foregroundColor: _D.txt2,
          side: const BorderSide(color: _D.border),
          minimumSize: const Size(0, 44),
          shape: const RoundedRectangleBorder(borderRadius: _D.r12),
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: _D.brand,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 44),
        shape: const RoundedRectangleBorder(borderRadius: _D.r12),
      ),
    );
  }
}

class _IconPill extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _IconPill({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: _D.r12,
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ORDERS CONTENT (status chips + list + pagination)
// ─────────────────────────────────────────────────────────────────────────────
class _OrdersContent extends StatelessWidget {
  final dynamic data; // SellerCustomOrdersData
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
    final orders = data.orders as List<SellerCustomOrder>;
    final statuses = statusCounts?.isNotEmpty == true
        ? statusCounts!
        : data.statuses as Map<String, int>;
    final pagination = data.pagination as SellerCustomOrdersPagination;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Status segmented filter ─────────────────────
        _StatusSegmentedRow(
          statuses: statuses,
          selectedStatus: selectedStatus,
          total: pagination.total,
          onSelected: onStatusSelect,
        ),
        const SizedBox(height: 14),

        // ── Pagination summary ──────────────────────────
        _PaginationBar(pagination: pagination),
        const SizedBox(height: 12),

        // ── Order cards ─────────────────────────────────
        if (orders.isEmpty)
          const _EmptyState()
        else
          ...orders.asMap().entries.map(
            (e) => _AnimatedOrderCard(
              key: ValueKey(e.value.id),
              order: e.value,
              index: e.key,
            ),
          ),

        const SizedBox(height: 8),

        // ── Pagination controls ─────────────────────────
        _PaginationControls(pagination: pagination, onPage: onPage),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  STATUS SEGMENTED ROW
// ─────────────────────────────────────────────────────────────────────────────
class _StatusSegmentedRow extends StatelessWidget {
  final Map<String, int> statuses;
  final String? selectedStatus;
  final int total;
  final ValueChanged<String?> onSelected;

  const _StatusSegmentedRow({
    required this.statuses,
    required this.selectedStatus,
    required this.total,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _StatusPill(
            label: 'All',
            count: total,
            selected: selectedStatus == null,
            color: _D.brand,
            onTap: () => onSelected(null),
          ),
          ...statuses.entries.map((e) {
            final colors = _statusColors(e.key);
            return _StatusPill(
              label: e.key,
              count: e.value,
              selected: selectedStatus == e.key,
              color: colors.fg,
              onTap: () => onSelected(e.key),
            );
          }),
        ],
      ),
    );
  }
}

class _StatusPill extends StatefulWidget {
  final String label;
  final int count;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _StatusPill({
    required this.label,
    required this.count,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  State<_StatusPill> createState() => _StatusPillState();
}

class _StatusPillState extends State<_StatusPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      lowerBound: 0.93,
      upperBound: 1.0,
    )..value = 1.0;
    _scale = _c;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) => _c.reverse(),
        onTapUp: (_) {
          _c.forward();
          widget.onTap();
        },
        onTapCancel: () => _c.forward(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: widget.selected ? widget.color : _D.surface,
            borderRadius: _D.r32,
            border: Border.all(
              color: widget.selected ? widget.color : _D.border,
            ),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.selected ? Colors.white : _D.txt2,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: widget.selected
                      ? Colors.white.withValues(alpha: 0.22)
                      : _D.surfaceAlt,
                  borderRadius: _D.r32,
                ),
                child: Text(
                  '${widget.count}',
                  style: TextStyle(
                    color: widget.selected ? Colors.white : _D.txt2,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
    final from = pagination.from;
    final to = pagination.to;
    final total = pagination.total;
    final cur = pagination.currentPage;
    final last = pagination.lastPage;

    final rangeText = from == null || to == null
        ? 'No records found'
        : '$from – $to of $total orders';

    return Row(
      children: [
        Expanded(
          child: Text(
            rangeText,
            style: const TextStyle(
              color: _D.txt2,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: const BoxDecoration(
            color: _D.brandSoft,
            borderRadius: _D.r32,
          ),
          child: Text(
            'Page $cur / $last',
            style: const TextStyle(
              color: _D.brand,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ANIMATED ORDER CARD WRAPPER
// ─────────────────────────────────────────────────────────────────────────────
class _AnimatedOrderCard extends StatefulWidget {
  final SellerCustomOrder order;
  final int index;

  const _AnimatedOrderCard({
    super.key,
    required this.order,
    required this.index,
  });

  @override
  State<_AnimatedOrderCard> createState() => _AnimatedOrderCardState();
}

class _AnimatedOrderCardState extends State<_AnimatedOrderCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: widget.index * 50), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _fade,
    child: SlideTransition(
      position: _slide,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SellerCustomOrderDetailsScreen(
                  orderUuid: widget.order.uuid,
                  initialOrder: widget.order,
                ),
              ),
            );
          },
          child: _OrderCard(order: widget.order),
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  ORDER CARD
// ─────────────────────────────────────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  final SellerCustomOrder order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final colors = _statusColors(order.status);

    return Container(
      decoration: BoxDecoration(
        color: _D.surface,
        borderRadius: _D.r16,
        border: Border.all(color: _D.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left accent bar
              Container(width: 4, color: colors.fg),

              // Card body
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Title row ──────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: colors.fg.withValues(alpha: 0.08),
                              borderRadius: _D.r12,
                            ),
                            child: Icon(
                              Icons.inventory_2_outlined,
                              color: colors.fg,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.product.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _D.txt1,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${order.product.prNumber} · ${order.portal}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _D.txt3,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Status badge
                          _StatusBadge(
                            status: order.status,
                            fg: colors.fg,
                            bg: colors.bg,
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),
                      const Divider(height: 1, color: _D.divider),
                      const SizedBox(height: 12),

                      // ── Stats row ──────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: _StatCell(
                              icon: Icons.price_check_rounded,
                              label: 'Deal Price',
                              value: order.formattedTotalDealPrice,
                              color: _D.brand,
                            ),
                          ),
                          Expanded(
                            child: _StatCell(
                              icon: Icons.payments_outlined,
                              label: 'Advance',
                              value: order.formattedAdvancePrice,
                              color: _D.success,
                            ),
                          ),
                          Expanded(
                            child: _StatCell(
                              icon: Icons.calendar_month_outlined,
                              label: 'Tenure',
                              value: '${order.tenure} mo.',
                              color: _D.violet,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // ── Meta row ───────────────────────
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 12,
                            color: _D.txt3,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              order.formattedCreatedAt,
                              style: const TextStyle(
                                color: _D.txt3,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            'User #${order.userId}',
                            style: const TextStyle(
                              color: _D.txt3,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // ── Expandable detail ───────────────
                      Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          childrenPadding: const EdgeInsets.only(top: 10),
                          dense: true,
                          title: const Text(
                            'Quick details',
                            style: TextStyle(
                              color: _D.brand,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          iconColor: _D.brand,
                          collapsedIconColor: _D.brand,
                          children: [_DetailsGrid(order: order)],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCell({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: _D.txt3,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      const SizedBox(height: 3),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          value,
          style: TextStyle(
            color: _D.txt1,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ],
  );
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color fg;
  final Color bg;

  const _StatusBadge({
    required this.status,
    required this.fg,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 100),
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: _D.r32,
      border: Border.all(color: fg.withValues(alpha: 0.2)),
    ),
    child: Text(
      status,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w800),
    ),
  );
}

class _DetailsGrid extends StatelessWidget {
  final SellerCustomOrder order;
  const _DetailsGrid({required this.order});

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Order ID', order.id.toString()),
      ('UUID', order.uuid),
      ('Product ID', order.productId.toString()),
      ('Product', order.product.title),
      ('PR Number', order.product.prNumber),
      ('Category ID', order.product.categoryId),
      ('Brand ID', order.product.brandId),
      ('Picture', order.product.picture),
      ('Custom Fields', order.product.customFields),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: _D.surfaceAlt,
        borderRadius: _D.r12,
      ),
      child: Column(
        children: rows.asMap().entries.map((e) {
          final isLast = e.key == rows.length - 1;
          return _KVLine(
            label: e.value.$1,
            value: e.value.$2,
            showDivider: !isLast,
          );
        }).toList(),
      ),
    );
  }
}

class _KVLine extends StatelessWidget {
  final String label;
  final String value;
  final bool showDivider;

  const _KVLine({
    required this.label,
    required this.value,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: const TextStyle(
                color: _D.txt2,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: _D.txt1,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      if (showDivider) const Divider(height: 12, color: _D.border),
    ],
  );
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
          child: _NavBtn(
            label: 'Previous',
            icon: Icons.chevron_left_rounded,
            iconRight: false,
            enabled: pagination.hasPrevious,
            onTap: () => onPage(pagination.currentPage - 1),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _NavBtn(
            label: 'Next',
            icon: Icons.chevron_right_rounded,
            iconRight: true,
            enabled: pagination.hasNext,
            onTap: () => onPage(pagination.currentPage + 1),
            primary: true,
          ),
        ),
      ],
    );
  }
}

class _NavBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool iconRight;
  final bool enabled;
  final VoidCallback onTap;
  final bool primary;

  const _NavBtn({
    required this.label,
    required this.icon,
    required this.iconRight,
    required this.enabled,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(icon, size: 18);
    final labelWidget = Text(
      label,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
    );

    final children = iconRight
        ? [labelWidget, const SizedBox(width: 4), iconWidget]
        : [iconWidget, const SizedBox(width: 4), labelWidget];

    if (primary) {
      return ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _D.brand,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _D.border,
          disabledForegroundColor: _D.txt3,
          elevation: 0,
          minimumSize: const Size(double.infinity, 46),
          shape: const RoundedRectangleBorder(borderRadius: _D.r12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: children,
        ),
      );
    }

    return OutlinedButton(
      onPressed: enabled ? onTap : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: _D.txt2,
        side: const BorderSide(color: _D.border),
        minimumSize: const Size(double.infinity, 46),
        shape: const RoundedRectangleBorder(borderRadius: _D.r12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: children,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SHIMMER SKELETON
// ─────────────────────────────────────────────────────────────────────────────
class _OrdersShimmer extends StatefulWidget {
  const _OrdersShimmer();

  @override
  State<_OrdersShimmer> createState() => _OrdersShimmerState();
}

class _OrdersShimmerState extends State<_OrdersShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _a = Tween<double>(
      begin: -2,
      end: 2,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (_, _) => Column(
        children: [
          _ShimmerChips(shimmer: _a.value),
          const SizedBox(height: 14),
          ...List.generate(
            4,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ShimmerCard(shimmer: _a.value),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerChips extends StatelessWidget {
  final double shimmer;
  const _ShimmerChips({required this.shimmer});

  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(
      4,
      (i) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: _ShimmerBox(width: 72, height: 36, radius: 32, shimmer: shimmer),
      ),
    ),
  );
}

class _ShimmerCard extends StatelessWidget {
  final double shimmer;
  const _ShimmerCard({required this.shimmer});

  @override
  Widget build(BuildContext context) =>
      _ShimmerBox(height: 140, radius: 16, shimmer: shimmer);
}

class _ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  final double shimmer;

  const _ShimmerBox({
    this.width,
    required this.height,
    required this.radius,
    required this.shimmer,
  });

  @override
  Widget build(BuildContext context) {
    const base = Color(0xFFE8EBF5);
    const hi = Color(0xFFF4F6FF);
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment(shimmer - 1, 0),
          end: Alignment(shimmer, 0),
          colors: const [base, hi, base],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: _D.surfaceAlt,
              borderRadius: _D.r16,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              color: _D.txt3,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No orders match your filters',
            style: TextStyle(
              color: _D.txt1,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try adjusting the filters or clearing the date range.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _D.txt2, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ERROR CARD
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: _D.dangerBg,
              borderRadius: _D.r16,
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              color: _D.danger,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Couldn\'t load orders',
            style: TextStyle(
              color: _D.txt1,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _D.txt2, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Try again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _D.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const RoundedRectangleBorder(borderRadius: _D.r12),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SHARED ATOMS
// ─────────────────────────────────────────────────────────────────────────────
class _SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: _D.surface,
      borderRadius: _D.r14,
      border: Border.all(color: _D.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: child,
  );
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
