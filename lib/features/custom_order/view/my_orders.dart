import 'package:atompro/core/style/color_palette.dart';
import 'package:atompro/features/custom_order/model/my_order_model.dart';
import 'package:atompro/features/custom_order/viewmodel/my_orders_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyOrdersPage extends ConsumerStatefulWidget {
  const MyOrdersPage({super.key});

  @override
  ConsumerState<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends ConsumerState<MyOrdersPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  String _filter = 'All';

  late final AnimationController _entryCtrl;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entryCtrl.forward();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text));
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<OrderModel> _filtered(List<OrderModel> all) {
    return all.where((o) {
      final matchQ =
          _query.isEmpty ||
          o.orderNumber.toLowerCase().contains(_query.toLowerCase()) ||
          o.product.title.toLowerCase().contains(_query.toLowerCase());
      final matchF =
          _filter == 'All' || o.status.toLowerCase() == _filter.toLowerCase();
      return matchQ && matchF;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(myOrdersViewModelProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F5FB),
        body: asyncState.when(
          loading: () => _buildLoadingState(),
          error: (e, _) => _buildErrorState(e.toString()),
          data: (response) {
            final orders = _filtered(response.orders);
            return FadeTransition(
              opacity: _fadeIn,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildHeader(response.orders.length),
                  ),
                  if (orders.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmpty(),
                    )
                  else ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          '${orders.length} order${orders.length == 1 ? '' : 's'} found',
                          style: const TextStyle(
                            fontSize: 12,
                            color: ColorPalette.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _OrderCard(
                              order: orders[i],
                              onTap: () => _openDetail(
                                orders[i],
                                response.customer,
                                response.user,
                              ),
                            ),
                          ),
                          childCount: orders.length,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(0),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PulsingOrderIcon(),
                  const SizedBox(height: 24),
                  const Text(
                    'Fetching your orders…',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: ColorPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This will only take a moment.',
                    style: TextStyle(
                      fontSize: 13,
                      color: ColorPalette.textSecondary,
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

  // ── Error ──────────────────────────────────────────────────────────────────
  Widget _buildErrorState(String message) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(0),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: ColorPalette.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        Icons.wifi_off_rounded,
                        size: 34,
                        color: ColorPalette.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Failed to load orders',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: ColorPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 13,
                        color: ColorPalette.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () => ref
                          .read(myOrdersViewModelProvider.notifier)
                          .fetchOrders(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: ColorPalette.secondaryGradient,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'Try Again',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(int totalCount) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 17,
                      color: ColorPalette.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                const Text(
                  'My Orders',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: ColorPalette.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: ColorPalette.secondaryGradient,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$totalCount Total',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Search bar
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF213F9A).withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(
                  fontSize: 14,
                  color: ColorPalette.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search by order or product…',
                  hintStyle: TextStyle(
                    fontSize: 13.5,
                    color: ColorPalette.textSecondary.withOpacity(0.7),
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: ColorPalette.secondary,
                    size: 20,
                  ),
                  suffixIcon: _query.isNotEmpty
                      ? GestureDetector(
                          onTap: () => _searchCtrl.clear(),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: ColorPalette.textSecondary,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Approved', 'Pending'].map((f) {
                  final active = _filter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _filter = f);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: active ? ColorPalette.secondary : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: active
                                ? ColorPalette.secondary
                                : ColorPalette.border,
                          ),
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                    color: ColorPalette.secondary.withOpacity(
                                      0.25,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : [],
                        ),
                        child: Text(
                          f,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: active
                                ? Colors.white
                                : ColorPalette.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFECF0FF),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              size: 34,
              color: ColorPalette.secondary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No orders found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: ColorPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try a different search or filter.',
            style: TextStyle(fontSize: 13, color: ColorPalette.textSecondary),
          ),
        ],
      ),
    );
  }

  void _openDetail(OrderModel order, CustomerInfo customer, UserInfo userInfo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OrderDetailSheet(
        order: order,
        customer: customer,
        userInfo: userInfo,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  ORDER CARD  (unchanged structure, real data)
// ══════════════════════════════════════════════════════════════════════════════
class _OrderCard extends StatefulWidget {
  final OrderModel order;
  final VoidCallback onTap;
  const _OrderCard({required this.order, required this.onTap});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final paidCount = o.paidInstallments;
    final totalCount = o.installments.length;
    final progress = totalCount > 0 ? paidCount / totalCount : 0.0;
    final statusColor = o.isApproved
        ? ColorPalette.success
        : ColorPalette.warning;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF213F9A).withOpacity(0.07),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFECF0FF),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        size: 22,
                        color: ColorPalette.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            o.product.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: ColorPalette.textPrimary,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            o.orderNumber,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: ColorPalette.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        o.status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _statChip(
                      Icons.payments_outlined,
                      o.totalDealAmount,
                      'Total',
                    ),
                    const SizedBox(width: 8),
                    _statChip(
                      Icons.calendar_month_outlined,
                      o.installmentTenure,
                      'Tenure',
                    ),
                    const SizedBox(width: 8),
                    _statChip(Icons.percent_rounded, o.monthlyPercent, 'Rate'),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Installments',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: ColorPalette.textSecondary,
                          ),
                        ),
                        Text(
                          '$paidCount / $totalCount paid',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: ColorPalette.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: ColorPalette.secondary.withOpacity(
                          0.1,
                        ),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          ColorPalette.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFF),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  border: Border(
                    top: BorderSide(color: ColorPalette.border, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.storefront_outlined,
                      size: 14,
                      color: ColorPalette.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        o.seller?.businessName == null
                            ? "Seller: N/A (${o.status})"
                            : "Seller: ${o.seller?.businessName}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: ColorPalette.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 13,
                      color: ColorPalette.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      o.orderDate,
                      style: const TextStyle(
                        fontSize: 12,
                        color: ColorPalette.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: Color(0xFFBCC5D6),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F5FB),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 13, color: ColorPalette.secondary),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: ColorPalette.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: ColorPalette.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  ORDER DETAIL BOTTOM SHEET  (real data, unchanged structure)
// ══════════════════════════════════════════════════════════════════════════════
class _OrderDetailSheet extends StatefulWidget {
  final OrderModel order;
  final CustomerInfo customer;
  final UserInfo userInfo;
  const _OrderDetailSheet({
    required this.order,
    required this.customer,
    required this.userInfo,
  });

  @override
  State<_OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends State<_OrderDetailSheet> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFFF2F5FB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFDDE3F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        o.orderNumber,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: ColorPalette.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        o.orderDate,
                        style: const TextStyle(
                          fontSize: 12,
                          color: ColorPalette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (o.isApproved
                                ? ColorPalette.success
                                : ColorPalette.warning)
                            .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          (o.isApproved
                                  ? ColorPalette.success
                                  : ColorPalette.warning)
                              .withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    o.status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: o.isApproved
                          ? ColorPalette.success
                          : ColorPalette.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ColorPalette.border),
              ),
              child: Row(
                children: ['Overview', 'Customer', 'Seller', 'Installments']
                    .asMap()
                    .entries
                    .map((e) {
                      final active = _tab == e.key;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _tab = e.key),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: active
                                  ? ColorPalette.secondary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Center(
                              child: Text(
                                e.value,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: active
                                      ? Colors.white
                                      : ColorPalette.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    })
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _tab == 0
                  ? _buildOverview(o)
                  : _tab == 1
                  ? _buildCustomer(widget.customer, widget.userInfo)
                  : _tab == 2
                  ? _buildSeller(o)
                  : _buildInstallments(o.installments),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverview(OrderModel o) {
    return SingleChildScrollView(
      key: const ValueKey(0),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sheetCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PRODUCT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: ColorPalette.secondary,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  o.product.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: ColorPalette.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  o.productPrice,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: ColorPalette.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _sheetCard(
            child: Column(
              children: [
                _detailRow('Total Deal Amount', o.totalDealAmount),
                _divider(),
                _detailRow('Advance Amount', o.advanceAmount),
                _divider(),
                _detailRow('Sourcing Agent Fee', o.sourcingFee),
                _divider(),
                _detailRow('Tenure', o.installmentTenure),
                _divider(),
                _detailRow('Monthly Rate', o.monthlyPercent),
                _divider(),
                _detailRow('Portal', o.portal),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomer(CustomerInfo c, UserInfo user) {
    return SingleChildScrollView(
      key: const ValueKey(1),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // ── Identity hero card ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: ColorPalette.secondaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: ColorPalette.secondary.withOpacity(0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                // Avatar with initials
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      user.name
                          .trim()
                          .split(' ')
                          .map((w) => w.isNotEmpty ? w[0] : '')
                          .take(2)
                          .join()
                          .toUpperCase(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user.email,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (user.phone != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          user.phone!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Verified badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        c.isVerified
                            ? Icons.verified_rounded
                            : Icons.cancel_outlined,
                        size: 13,
                        color: c.isVerified
                            ? const Color(0xFF50FAB0)
                            : Colors.redAccent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        c.isVerified ? 'Verified' : 'Unverified',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Account details ────────────────────────────────────────────
          _sheetCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ACCOUNT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: ColorPalette.secondary,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                _detailRow('Full Name', user.name),
                _divider(),
                _detailRow('Email', user.email),
                _divider(),
                _detailRow('Phone', user.phone ?? 'Not provided'),
                _divider(),
                _detailRow('Member Since', user.joinDate),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Address & identity details ─────────────────────────────────
          _sheetCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PROFILE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: ColorPalette.secondary,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                _detailRow('Identifier', c.identifier),
                _divider(),
                _detailRow('City', c.city),
                _divider(),
                _detailRow('Area', c.area),
                _divider(),
                _detailRow('Address', c.address),
                if (c.cnicNo != null) ...[
                  _divider(),
                  _detailRow('CNIC', c.cnicNo!),
                ],
                if (c.fatherName != null) ...[
                  _divider(),
                  _detailRow('Father Name', c.fatherName!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeller(OrderModel o) {
    // Null seller OR cancelled order — show appropriate message
    if (o.seller == null || o.isCancelled) {
      final isCancelled = o.isCancelled;
      return SingleChildScrollView(
        key: const ValueKey(2),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        physics: const BouncingScrollPhysics(),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 32),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color:
                      (isCancelled ? ColorPalette.error : ColorPalette.warning)
                          .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(
                  isCancelled
                      ? Icons.cancel_outlined
                      : Icons.hourglass_top_rounded,
                  size: 34,
                  color: isCancelled
                      ? ColorPalette.error
                      : ColorPalette.warning,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isCancelled ? 'Order Cancelled' : 'Pending Approval',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: ColorPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  isCancelled
                      ? 'This order has been cancelled. No Seller was assigned.'
                      : 'Seller details will be visible once your order is reviewed and approved by our team.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: ColorPalette.textSecondary,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (!isCancelled) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: ColorPalette.warning.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ColorPalette.warning.withOpacity(0.25),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 15,
                        color: ColorPalette.warning,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Estimated review time: 24–48 hours',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ColorPalette.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Supplier is available — show full details
    final s = o.seller!;
    final initials = s.name
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .take(2)
        .join()
        .toUpperCase();

    return SingleChildScrollView(
      key: const ValueKey(2),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: ColorPalette.secondaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: ColorPalette.secondary.withOpacity(0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      initials.isNotEmpty ? initials : '?',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name.isNotEmpty ? s.name : 'Unknown Supplier',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.businessName.isNotEmpty ? s.businessName : 'N/A',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _sheetCard(
            child: Column(
              children: [
                _detailRow(
                  'Business',
                  s.businessName.isNotEmpty ? s.businessName : '-',
                ),
                _divider(),
                _detailRow('Phone', s.phone.isNotEmpty ? s.phone : '-'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallments(List<InstallmentItem> items) {
    return ListView.separated(
      key: const ValueKey(2),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final item = items[i];
        final statusColor = item.isPaid
            ? ColorPalette.success
            : ColorPalette.error;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF213F9A).withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.month,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: ColorPalette.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        item.isPaid ? 'Paid' : 'Unpaid',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: ColorPalette.border),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Column(
                  children: [
                    _miniRow('Installment', item.installmentAmount),
                    const SizedBox(height: 5),
                    _miniRow(
                      'Paid',
                      item.paidAmount,
                      valueColor: item.isPaid
                          ? ColorPalette.success
                          : ColorPalette.textPrimary,
                    ),
                    const SizedBox(height: 5),
                    _miniRow(
                      'Outstanding',
                      item.outstandingAmount,
                      valueColor: item.outstandingAmount == 'PKR 0'
                          ? ColorPalette.success
                          : ColorPalette.error,
                    ),
                    if (item.paidDate != null) ...[
                      const SizedBox(height: 5),
                      _miniRow('Paid On', item.paidDate!),
                    ],
                    if (item.paymentMethod != null) ...[
                      const SizedBox(height: 5),
                      _miniRow(
                        'Method',
                        item.paymentMethod!.toUpperCase(),
                        valueIcon: item.paymentMethod == 'online'
                            ? Icons.wifi_rounded
                            : Icons.payments_outlined,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sheetCard({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF213F9A).withOpacity(0.05),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: child,
  );

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: ColorPalette.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: ColorPalette.textPrimary,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    ),
  );

  Widget _miniRow(
    String label,
    String value, {
    Color? valueColor,
    IconData? valueIcon,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: ColorPalette.textSecondary,
          ),
        ),
        const Spacer(),
        if (valueIcon != null) ...[
          Icon(
            valueIcon,
            size: 13,
            color: valueColor ?? ColorPalette.textPrimary,
          ),
          const SizedBox(width: 4),
        ],
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: valueColor ?? ColorPalette.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _divider() => Divider(height: 1, color: ColorPalette.border);
}

class _PulsingOrderIcon extends StatefulWidget {
  @override
  State<_PulsingOrderIcon> createState() => _PulsingOrderIconState();
}

class _PulsingOrderIconState extends State<_PulsingOrderIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulsing ring
          Transform.scale(
            scale: _pulse.value,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ColorPalette.secondary.withOpacity(0.08),
              ),
            ),
          ),
          // Inner circle
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ColorPalette.secondary.withOpacity(0.14),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              size: 30,
              color: ColorPalette.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
