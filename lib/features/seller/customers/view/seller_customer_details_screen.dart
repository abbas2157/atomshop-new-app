import 'package:atompro/features/seller/custom_orders/view/seller_custom_order_details_screen.dart';
import 'package:atompro/features/seller/customers/model/seller_customers_model.dart';
import 'package:atompro/features/seller/customers/viewmodel/seller_customers_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract final class _C {
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
}

class SellerCustomerDetailsScreen extends ConsumerWidget {
  final String customerUuid;
  final SellerCustomer? initialCustomer;

  const SellerCustomerDetailsScreen({
    super.key,
    required this.customerUuid,
    this.initialCustomer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(sellerCustomerProfileProvider(customerUuid));
    final instalmentsState = ref.watch(
      sellerCustomerInstalmentsProvider(customerUuid),
    );
    final ordersState = ref.watch(
      sellerCustomerCustomOrdersProvider(customerUuid),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _C.bg,
        appBar: AppBar(
          backgroundColor: _C.bg,
          surfaceTintColor: _C.bg,
          titleSpacing: 0,
          title: const Text(
            'Customer Details',
            style: TextStyle(
              color: _C.text,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: () {
                ref.invalidate(sellerCustomerProfileProvider(customerUuid));
                ref.invalidate(sellerCustomerInstalmentsProvider(customerUuid));
                ref.invalidate(
                  sellerCustomerCustomOrdersProvider(customerUuid),
                );
              },
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: profileState.when(
          loading: () => _LoadingView(initialCustomer: initialCustomer),
          error: (error, _) => _ErrorView(
            message: _cleanError(error),
            onRetry: () =>
                ref.invalidate(sellerCustomerProfileProvider(customerUuid)),
          ),
          data: (details) => RefreshIndicator(
            color: _C.brand,
            onRefresh: () async {
              ref.invalidate(sellerCustomerProfileProvider(customerUuid));
              ref.invalidate(sellerCustomerInstalmentsProvider(customerUuid));
              ref.invalidate(sellerCustomerCustomOrdersProvider(customerUuid));
              await Future.wait([
                ref.read(sellerCustomerProfileProvider(customerUuid).future),
                ref.read(
                  sellerCustomerInstalmentsProvider(customerUuid).future,
                ),
                ref.read(
                  sellerCustomerCustomOrdersProvider(customerUuid).future,
                ),
              ]);
            },
            child: ListView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
              children: [
                _Hero(details: details),
                const SizedBox(height: 12),
                _InfoSection(
                  title: 'Customer Profile',
                  icon: Icons.person_outline_rounded,
                  rows: [
                    _InfoRow('Identifier', details.user.profile.identifier),
                    _InfoRow('Phone', details.user.phone),
                    _InfoRow('Email', details.user.email),
                    _InfoRow('CNIC', details.user.profile.cnicNo),
                    _InfoRow('Father Name', details.user.profile.fatherName),
                    _InfoRow('Residence', details.user.profile.residencePhone),
                    _InfoRow('Address', details.user.profile.address),
                    _InfoRow('Office', details.user.profile.officeAddress),
                    _InfoRow('Portal', details.user.profile.portal),
                    _InfoRow('Joined', details.user.formattedCreatedAt),
                  ],
                ),
                const SizedBox(height: 12),
                _OrdersSection(state: ordersState),
                const SizedBox(height: 12),
                _InstalmentsSection(state: instalmentsState),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final SellerCustomerDetails details;

  const _Hero({required this.details});

  @override
  Widget build(BuildContext context) {
    final customer = details.user;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_C.brandDark, _C.brand],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _C.brand.withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white.withValues(alpha: 0.16),
                child: Text(
                  _initials(customer.name),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      customer.phone,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _HeroChip(
                label: customer.verified ? 'Verified' : 'Pending',
                icon: customer.verified
                    ? Icons.verified_outlined
                    : Icons.schedule_outlined,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Sales',
                  value: details.formattedTotalCustomSales,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Metric(
                  label: 'Recovery',
                  value: details.formattedTotalCustomRecovery,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Metric(
                  label: 'Rate',
                  value: details.formattedRecoveryPercentage,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
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
    return _Section(
      title: title,
      icon: icon,
      child: Column(children: rows.map((row) => _InfoTile(row)).toList()),
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

  const _InfoTile(this.row);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              row.label,
              style: const TextStyle(
                color: _C.muted,
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
                color: _C.text,
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

class _OrdersSection extends StatelessWidget {
  final AsyncValue<SellerCustomerCustomOrdersResponse> state;

  const _OrdersSection({required this.state});

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Custom Orders',
      icon: Icons.receipt_long_outlined,
      child: state.when(
        loading: () => const _InlineLoading(label: 'Loading orders...'),
        error: (error, _) => _InlineError(message: _cleanError(error)),
        data: (data) {
          if (data.orders.isEmpty) {
            return const _EmptyInline(label: 'No custom orders found.');
          }
          return Column(
            children: data.orders
                .map(
                  (order) => _OrderTile(
                    order: order,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SellerCustomOrderDetailsScreen(
                          orderUuid: order.uuid,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

class _InstalmentsSection extends StatelessWidget {
  final AsyncValue<SellerCustomerInstalmentsResponse> state;

  const _InstalmentsSection({required this.state});

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Instalments',
      icon: Icons.payments_outlined,
      child: state.when(
        loading: () => const _InlineLoading(label: 'Loading instalments...'),
        error: (error, _) => _InlineError(message: _cleanError(error)),
        data: (data) {
          if (data.instalments.isEmpty) {
            return const _EmptyInline(label: 'No instalments found.');
          }
          return Column(
            children: data.instalments
                .take(8)
                .map((item) => _InstalmentTile(item: item))
                .toList(),
          );
        },
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final SellerCustomerOrderSummary order;
  final VoidCallback onTap;

  const _OrderTile({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = _statusColors(order.status);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _C.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: colors.bg,
                borderRadius: BorderRadius.circular(13),
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
                      color: _C.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${order.formattedTotalDealPrice} • ${order.formattedCreatedAt}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _C.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _C.muted),
          ],
        ),
      ),
    );
  }
}

class _InstalmentTile extends StatelessWidget {
  final SellerCustomerInstalment item;

  const _InstalmentTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = _statusColors(item.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.month,
                  style: const TextStyle(
                    color: _C.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.formattedPrice} • ${item.installmentDate}',
                  style: const TextStyle(
                    color: _C.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _StatusPill(label: item.status, fg: colors.fg, bg: colors.bg),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _Section({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: _C.brand, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: _C.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
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
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _InlineLoading extends StatelessWidget {
  final String label;

  const _InlineLoading({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: _C.brand),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            color: _C.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;

  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: const TextStyle(
        color: _C.danger,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _EmptyInline extends StatelessWidget {
  final String label;

  const _EmptyInline({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: _C.muted,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  final SellerCustomer? initialCustomer;

  const _LoadingView({this.initialCustomer});

  @override
  Widget build(BuildContext context) {
    if (initialCustomer == null) {
      return const Center(child: CircularProgressIndicator(color: _C.brand));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _C.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: _C.brand.withValues(alpha: 0.1),
                child: Text(
                  _initials(initialCustomer!.name),
                  style: const TextStyle(
                    color: _C.brand,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  initialCustomer!.name,
                  style: const TextStyle(
                    color: _C.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ),
        ),
      ],
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: _C.danger, size: 34),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _C.text,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

({Color fg, Color bg}) _statusColors(String status) {
  final lower = status.toLowerCase();
  if (lower.contains('paid') && !lower.contains('unpaid')) {
    return (fg: _C.success, bg: _C.success.withValues(alpha: 0.12));
  }
  if (lower.contains('unpaid') ||
      lower.contains('pending') ||
      lower.contains('instal')) {
    return (fg: _C.warning, bg: _C.warning.withValues(alpha: 0.12));
  }
  if (lower.contains('cancel') || lower.contains('lost')) {
    return (fg: _C.danger, bg: _C.danger.withValues(alpha: 0.12));
  }
  return (fg: _C.brand, bg: _C.brand.withValues(alpha: 0.12));
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return 'C';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first.substring(0, 1)}${parts[1].substring(0, 1)}'
      .toUpperCase();
}

String _cleanError(Object error) {
  final text = error.toString().replaceFirst('Exception: ', '').trim();
  return text.isEmpty ? 'Something went wrong. Please try again.' : text;
}
