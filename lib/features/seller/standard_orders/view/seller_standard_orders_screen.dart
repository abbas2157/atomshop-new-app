import 'package:atompro/core/services/snackbar_services.dart';
import 'package:atompro/features/seller/customers/model/seller_customers_model.dart';
import 'package:atompro/features/seller/customers/repository/seller_customers_repository.dart';
import 'package:atompro/features/seller/standard_orders/model/seller_standard_orders_model.dart';
import 'package:atompro/features/seller/standard_orders/repository/seller_standard_orders_repository.dart';
import 'package:atompro/features/seller/standard_orders/viewmodel/seller_standard_orders_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

abstract final class _S {
  static const bg = Color(0xFFF4F6FC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF8FAFE);
  static const brand = Color(0xFF3B5BDB);
  static const brandDark = Color(0xFF1A2980);
  static const text = Color(0xFF101828);
  static const muted = Color(0xFF667085);
  static const border = Color(0xFFE4E8F5);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const info = Color(0xFF06B6D4);
}

class SellerStandardOrdersScreen extends ConsumerStatefulWidget {
  const SellerStandardOrdersScreen({super.key});

  @override
  ConsumerState<SellerStandardOrdersScreen> createState() =>
      _SellerStandardOrdersScreenState();
}

class _SellerStandardOrdersScreenState
    extends ConsumerState<SellerStandardOrdersScreen> {
  int _page = 1;

  Future<void> _showCreateSheet() async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreateOrderSheet(),
    );
    if (changed == true) ref.invalidate(sellerStandardOrdersProvider(_page));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sellerStandardOrdersProvider(_page));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _S.bg,
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'seller_add_standard_order',
          onPressed: _showCreateSheet,
          backgroundColor: _S.brand,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_shopping_cart_outlined),
          label: const Text('Create'),
        ),
        body: SafeArea(
          child: RefreshIndicator(
            color: _S.brand,
            onRefresh: () async {
              ref.invalidate(sellerStandardOrdersProvider(_page));
              await ref.read(sellerStandardOrdersProvider(_page).future);
            },
            child: ListView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 118),
              children: [
                state.when(
                  loading: () => const _LoadingView(),
                  error: (error, _) => _ErrorCard(
                    message: _cleanError(error),
                    onRetry: () =>
                        ref.invalidate(sellerStandardOrdersProvider(_page)),
                  ),
                  data: (data) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(data: data),
                      const SizedBox(height: 12),
                      _RangeStrip(
                        total: data.pagination.total,
                        from: data.pagination.from,
                        to: data.pagination.to,
                      ),
                      const SizedBox(height: 12),
                      if (data.orders.isEmpty)
                        const _EmptyState()
                      else
                        ...data.orders.map(
                          (order) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _OrderCard(
                              order: order,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      SellerStandardOrderDetailsScreen(
                                        orderUuid: order.uuid,
                                        initialOrder: order,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
    final state = ref.watch(sellerStandardOrderDetailsProvider(orderUuid));
    return Scaffold(
      backgroundColor: _S.bg,
      appBar: AppBar(
        backgroundColor: _S.bg,
        surfaceTintColor: _S.bg,
        title: const Text('Standard Order Details'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () =>
                ref.invalidate(sellerStandardOrderDetailsProvider(orderUuid)),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: state.when(
        loading: () => _DetailLoading(initialOrder: initialOrder),
        error: (error, _) => _ErrorView(
          message: _cleanError(error),
          onRetry: () =>
              ref.invalidate(sellerStandardOrderDetailsProvider(orderUuid)),
        ),
        data: (details) => RefreshIndicator(
          color: _S.brand,
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
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
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
              const SizedBox(height: 12),
              _InfoSection(
                title: 'Customer',
                icon: Icons.person_outline_rounded,
                rows: [
                  _InfoRow('Name', details.user.name),
                  _InfoRow('Phone', details.user.phone),
                  _InfoRow('Email', details.user.email),
                  _InfoRow('Status', details.user.status),
                  _InfoRow('Joined', details.user.joinedThrough),
                ],
              ),
              const SizedBox(height: 12),
              _InfoSection(
                title: 'Verification',
                icon: Icons.verified_user_outlined,
                rows: [
                  _InfoRow('Identifier', details.user.customer.identifier),
                  _InfoRow(
                    'KYC',
                    details.user.customer.verified
                        ? 'Verified'
                        : 'Not verified',
                  ),
                  _InfoRow('CNIC', details.user.customer.cnicNo),
                  _InfoRow('Father name', details.user.customer.fatherName),
                  _InfoRow('Residence', details.user.customer.residencePhone),
                  _InfoRow('Address', details.user.customer.address),
                  _InfoRow('Office', details.user.customer.officeAddress),
                  _InfoRow('Office phone', details.user.customer.officePhone),
                ],
              ),
              if (details.statusHistory.isNotEmpty) ...[
                const SizedBox(height: 12),
                _StatusHistory(items: details.statusHistory),
              ],
              if (details.instalments.isNotEmpty) ...[
                const SizedBox(height: 12),
                _Instalments(items: details.instalments),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final SellerStandardOrdersResponse data;

  const _Header({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_S.brandDark, _S.brand],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _S.brand.withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Standard Orders',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${data.pagination.total} records - ${data.pendingCount} pending on this page',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
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
    final colors = _statusColors(order.status);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: _S.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _S.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: colors.bg,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(Icons.receipt_long_outlined, color: colors.fg),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.id}',
                        style: const TextStyle(
                          color: _S.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${order.portal} - ${order.formattedCreatedAt}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _S.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusPill(label: order.status, fg: colors.fg, bg: colors.bg),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MiniMetric(
                    label: 'Cart',
                    value: order.cartId.toString(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniMetric(
                    label: 'User',
                    value: order.userId.toString(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniMetric(label: 'Portal', value: order.portal),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

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
    final colors = _statusColors(order.status);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_S.brandDark, _S.brand],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Order #${order.id}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _StatusPill(label: order.status, fg: colors.fg, bg: colors.bg),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            order.uuid,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onStatus,
                  icon: const Icon(Icons.edit_note_rounded, size: 17),
                  label: const Text('Status'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.34),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 17),
                  label: const Text('PDF'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.34),
                    ),
                  ),
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
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.68),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_InfoRow> rows;

  const _InfoSection({
    required this.title,
    required this.icon,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _S.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _S.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: _S.brand, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _S.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...rows.map((row) => _InfoTile(row: row)),
        ],
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);
}

class _InfoTile extends StatelessWidget {
  final _InfoRow row;

  const _InfoTile({required this.row});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              row.label,
              style: const TextStyle(
                color: _S.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              row.value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: _S.text,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusHistory extends StatelessWidget {
  final List<SellerStandardOrderStatusHistory> items;

  const _StatusHistory({required this.items});

  @override
  Widget build(BuildContext context) {
    return _InfoSection(
      title: 'Status History',
      icon: Icons.timeline_rounded,
      rows: items
          .map(
            (item) => _InfoRow(
              item.status,
              '${item.comment} (${item.formattedCreatedAt})',
            ),
          )
          .toList(growable: false),
    );
  }
}

class _Instalments extends StatelessWidget {
  final List<SellerStandardOrderInstalment> items;

  const _Instalments({required this.items});

  @override
  Widget build(BuildContext context) {
    return _InfoSection(
      title: 'Instalments',
      icon: Icons.payments_outlined,
      rows: items
          .map(
            (item) =>
                _InfoRow(item.month, '${item.formattedPrice} - ${item.status}'),
          )
          .toList(growable: false),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;

  const _MiniMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: _S.surfaceAlt,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _S.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _S.muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _S.text,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color fg;
  final Color bg;

  const _StatusPill({required this.label, required this.fg, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _RangeStrip extends StatelessWidget {
  final int total;
  final int? from;
  final int? to;

  const _RangeStrip({
    required this.total,
    required this.from,
    required this.to,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _S.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _S.border),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Order Records',
              style: TextStyle(
                color: _S.text,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            total == 0 ? '0 records' : '${from ?? 0}-${to ?? 0} of $total',
            style: const TextStyle(
              color: _S.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
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
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
            label: const Text('Previous'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '${pagination.currentPage}/${pagination.lastPage}',
            style: const TextStyle(
              color: _S.muted,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
            label: const Text('Next'),
          ),
        ),
      ],
    );
  }
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
            const SizedBox(height: 8),
            _SheetButton(
              label: 'Create Order',
              loading: _saving,
              onTap: _submit,
            ),
          ],
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _S.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected == null
                ? _S.border
                : _S.brand.withValues(alpha: .4),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _S.brand.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: loading
                  ? const Padding(
                      padding: EdgeInsets.all(11),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.person_search_outlined, color: _S.brand),
            ),
            const SizedBox(width: 12),
            Expanded(child: _customerSelectBody(selected, hasError)),
            if (hasError)
              IconButton(
                tooltip: 'Retry',
                onPressed: enabled ? onRetry : null,
                icon: const Icon(Icons.refresh_rounded),
              )
            else
              const Icon(Icons.keyboard_arrow_down_rounded, color: _S.muted),
          ],
        ),
      ),
    );
  }

  Widget _customerSelectBody(SellerCustomer? selected, bool hasError) {
    if (loading) {
      return const Text(
        'Loading customers...',
        style: TextStyle(color: _S.text, fontWeight: FontWeight.w900),
      );
    }
    if (hasError) {
      return Text(
        error!,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: _S.danger,
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
            style: TextStyle(color: _S.text, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          Text(
            count == 0 ? 'No customers found' : '$count customers available',
            style: const TextStyle(
              color: _S.muted,
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
          style: const TextStyle(color: _S.text, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 3),
        Text(
          '${selected.phone} - City ${selected.profile.cityId}, Area ${selected.profile.areaId}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _S.muted,
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
          color: _S.surface,
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
                    color: _S.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Customer',
                style: TextStyle(
                  color: _S.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: _sheetDecoration('Search name, phone, email'),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: customers.isEmpty
                    ? const Center(
                        child: Text(
                          'No matching customers.',
                          style: TextStyle(
                            color: _S.muted,
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? _S.brand.withValues(alpha: .08) : _S.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? _S.brand : _S.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected
                    ? _S.brand.withValues(alpha: .14)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _S.border),
              ),
              child: Icon(
                selected
                    ? Icons.check_circle_outline_rounded
                    : Icons.person_outline_rounded,
                color: selected ? _S.brand : _S.muted,
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
                      color: _S.text,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    customer.phone,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _S.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'ID ${customer.id} - City ${customer.profile.cityId} - Area ${customer.profile.areaId}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _S.muted,
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
    'Instalments',
    'Delivered',
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
    return _SheetShell(
      title: 'Update Status',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: _sheetDecoration('Status'),
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
            const SizedBox(height: 12),
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
            _SheetButton(
              label: 'Save Status',
              loading: _saving,
              onTap: _submit,
            ),
          ],
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
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        decoration: const BoxDecoration(
          color: _S.surface,
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
                      color: _S.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: _S.text,
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
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        validator: validator,
        decoration: _sheetDecoration(label),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: _requiredNumber,
        decoration: _sheetDecoration(label),
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;

  const _SheetButton({
    required this.label,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: FilledButton.icon(
        onPressed: loading ? null : onTap,
        icon: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save_outlined, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: _S.brand,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (_) => Container(
          height: 136,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _S.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _S.border),
          ),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
    );
  }
}

class _DetailLoading extends StatelessWidget {
  final SellerStandardOrder? initialOrder;

  const _DetailLoading({this.initialOrder});

  @override
  Widget build(BuildContext context) {
    if (initialOrder == null) {
      return const Center(child: CircularProgressIndicator(color: _S.brand));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      children: [
        _OrderCard(order: initialOrder!, onTap: () {}),
        const SizedBox(height: 18),
        const Center(child: CircularProgressIndicator(color: _S.brand)),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _S.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _S.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: _S.danger),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _S.text, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _ErrorCard(message: message, onRetry: onRetry),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _S.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _S.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.receipt_long_outlined, color: _S.muted, size: 32),
          SizedBox(height: 10),
          Text(
            'No standard orders found.',
            style: TextStyle(color: _S.text, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

InputDecoration _sheetDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: _S.surfaceAlt,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _S.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _S.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _S.brand, width: 1.4),
    ),
  );
}

Future<void> _showStatusSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String orderUuid,
  required String currentStatus,
}) async {
  final changed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _StatusUpdateSheet(orderUuid: orderUuid, currentStatus: currentStatus),
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

({Color fg, Color bg}) _statusColors(String status) {
  final lower = status.toLowerCase();
  if (lower.contains('deliver') || lower.contains('complete')) {
    return (fg: _S.success, bg: _S.success.withValues(alpha: 0.12));
  }
  if (lower.contains('cancel') || lower.contains('reject')) {
    return (fg: _S.danger, bg: _S.danger.withValues(alpha: 0.12));
  }
  if (lower.contains('verif')) {
    return (fg: _S.info, bg: _S.info.withValues(alpha: 0.14));
  }
  return (fg: _S.warning, bg: _S.warning.withValues(alpha: 0.12));
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
