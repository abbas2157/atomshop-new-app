import 'dart:io';

import 'package:atompro/core/services/snackbar_services.dart';
import 'package:atompro/features/seller/custom_orders/view/seller_custom_order_details_screen.dart';
import 'package:atompro/features/seller/customers/model/seller_customers_model.dart';
import 'package:atompro/features/seller/customers/viewmodel/seller_customers_viewmodel.dart';
import 'package:atompro/features/seller/instalments/repository/seller_instalments_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
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
  static const info = Color(0xFF06B6D4);
}

// ── Root screen ───────────────────────────────────────────────────────────────
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
    final instalmentsState =
        ref.watch(sellerCustomerInstalmentsProvider(customerUuid));
    final ordersState =
        ref.watch(sellerCustomerCustomOrdersProvider(customerUuid));

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
                    sellerCustomerCustomOrdersProvider(customerUuid));
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
              ref.invalidate(
                  sellerCustomerCustomOrdersProvider(customerUuid));
              await Future.wait([
                ref.read(sellerCustomerProfileProvider(customerUuid).future),
                ref.read(
                    sellerCustomerInstalmentsProvider(customerUuid).future),
                ref.read(
                    sellerCustomerCustomOrdersProvider(customerUuid).future),
              ]);
            },
            child: ListView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
              children: [
                _HeroCard(details: details),
                const SizedBox(height: 12),

                // CUSTOMER INFORMATION
                _SectionCard(
                  title: 'Customer Information',
                  icon: Icons.person_outline_rounded,
                  child: Column(
                    children: [
                      _GRow('Identifier', details.user.profile.identifier,
                          'Name', details.user.name),
                      _GRow('Phone', details.user.phone,
                          'Email', details.user.email),
                      _GRow('Father Name', details.user.profile.fatherName,
                          'CNIC', details.user.profile.cnicNo),
                      _GRow('Address', details.user.profile.address,
                          'Res. Phone', details.user.profile.residencePhone),
                      _GRow('Office Address', details.user.profile.officeAddress,
                          'Office Phone', details.user.profile.officePhone),
                      _GRow('Joined Date', details.user.formattedCreatedAt,
                          'Joined Through', details.user.joinedThrough),
                      _GRow('Portal', details.user.profile.portal,
                          'Status', details.user.status),
                    ],
                  ),
                ),

                // CUSTOMER VERIFICATION
                if (details.verification.exists) ...[
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'Customer Verification',
                    icon: Icons.verified_user_outlined,
                    child: Column(
                      children: [
                        _GRow(
                          'Physical Meet',
                          details.verification.physicalMeet ? 'Yes' : 'No',
                          'Address Found',
                          details.verification.addressFound ? 'Yes' : 'No',
                        ),
                        _GRow('House', details.verification.house,
                            'Work', details.verification.work),
                        _GRow('ID Card (Front)',
                            _shortPath(details.verification.idCardFront),
                            'ID Card (Back)',
                            _shortPath(details.verification.idCardBack)),
                        if (details.verification.selfie != 'Not available')
                          _GRow('Selfie',
                              _shortPath(details.verification.selfie), '', ''),
                      ],
                    ),
                  ),
                ],

                // CUSTOM ORDERS
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Custom Orders',
                  icon: Icons.receipt_long_outlined,
                  child: ordersState.when(
                    loading: () =>
                        const _InlineLoading(label: 'Loading orders...'),
                    error: (e, _) => _InlineError(message: _cleanError(e)),
                    data: (data) => data.orders.isEmpty
                        ? const _EmptyInline(label: 'No custom orders yet.')
                        : Column(
                            children: data.orders
                                .map((o) => _OrderTile(
                                      order: o,
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              SellerCustomOrderDetailsScreen(
                                            orderUuid: o.uuid,
                                          ),
                                        ),
                                      ),
                                    ))
                                .toList(growable: false),
                          ),
                  ),
                ),

                // INSTALMENTS
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Instalments',
                  icon: Icons.payments_outlined,
                  child: instalmentsState.when(
                    loading: () =>
                        const _InlineLoading(label: 'Loading instalments...'),
                    error: (e, _) => _InlineError(message: _cleanError(e)),
                    data: (data) => data.instalments.isEmpty
                        ? const _EmptyInline(label: 'No instalments yet.')
                        : Column(
                            children: data.instalments
                                .take(10)
                                .map((item) => _InstalmentTile(
                                      item: item,
                                      onPay: item.status.toLowerCase() ==
                                              'paid'
                                          ? null
                                          : () => _showPayInstalmentSheet(
                                                context: context,
                                                ref: ref,
                                                customerUuid: customerUuid,
                                                orderId: item.orderId,
                                                instalmentPrice:
                                                    item.installmentPrice,
                                              ),
                                    ))
                                .toList(growable: false),
                          ),
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

// ── Hero card ─────────────────────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final SellerCustomerDetails details;
  const _HeroCard({required this.details});

  @override
  Widget build(BuildContext context) {
    final customer = details.user;
    final verified = customer.verified;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_C.brandDark, _C.brand],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _C.brand.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                radius: 26,
                backgroundColor: Colors.white.withValues(alpha: 0.16),
                child: Text(
                  _initials(customer.name),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
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
                        fontSize: 20,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      customer.phone,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // ✅ Green for verified, yellow for pending
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: verified
                      ? _C.success.withValues(alpha: 0.2)
                      : _C.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: verified
                        ? _C.success.withValues(alpha: 0.5)
                        : _C.warning.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      verified
                          ? Icons.verified_outlined
                          : Icons.schedule_outlined,
                      color: verified ? _C.success : _C.warning,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      verified ? 'Verified' : 'Pending',
                      style: TextStyle(
                        color: verified ? _C.success : _C.warning,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Metric(
                    label: 'Total Sales',
                    value: details.formattedTotalCustomSales),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Metric(
                    label: 'Recovery',
                    value: details.formattedTotalCustomRecovery),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Metric(
                    label: 'Rate',
                    value: details.formattedRecoveryPercentage),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Reusable section card ─────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
            decoration: BoxDecoration(
              color: _C.brand.withValues(alpha: 0.05),
              border: const Border(bottom: BorderSide(color: _C.border)),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 15, color: _C.brand),
                const SizedBox(width: 7),
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: _C.text,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.7,
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(14), child: child),
        ],
      ),
    );
  }
}

// ── 2-column grid row ─────────────────────────────────────────────────────────
class _GRow extends StatelessWidget {
  final String l1, v1, l2, v2;
  const _GRow(this.l1, this.v1, this.l2, this.v2);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _GCell(label: l1, value: v1)),
          if (l2.isNotEmpty) ...[
            const SizedBox(width: 12),
            Expanded(child: _GCell(label: l2, value: v2)),
          ],
        ],
      ),
    );
  }
}

class _GCell extends StatelessWidget {
  final String label;
  final String value;
  const _GCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _C.muted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value.isEmpty || value == 'Not available' ? '—' : value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _C.text,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

// ── Metric in hero ────────────────────────────────────────────────────────────
class _Metric extends StatelessWidget {
  final String label;
  final String value;
  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.w600,
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
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Order tile ────────────────────────────────────────────────────────────────
class _OrderTile extends StatelessWidget {
  final SellerCustomerOrderSummary order;
  final VoidCallback onTap;
  const _OrderTile({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = _statusColors(order.status);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: _C.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _C.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${order.id}',
                    style: const TextStyle(
                      color: _C.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${order.formattedTotalDealPrice} · ${order.formattedCreatedAt}',
                    style: const TextStyle(
                      color: _C.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            _StatusPill(label: order.status, fg: colors.fg, bg: colors.bg),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: _C.muted, size: 16),
          ],
        ),
      ),
    );
  }
}

// ── Instalment tile ───────────────────────────────────────────────────────────
class _InstalmentTile extends StatelessWidget {
  final SellerCustomerInstalment item;
  final VoidCallback? onPay;
  const _InstalmentTile({required this.item, this.onPay});

  @override
  Widget build(BuildContext context) {
    final colors = _statusColors(item.status);
    final isPaid = item.status.toLowerCase() == 'paid';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: isPaid ? _C.success.withValues(alpha: 0.04) : _C.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isPaid ? _C.success.withValues(alpha: 0.25) : _C.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.month,
                      style: const TextStyle(
                        color: _C.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.formattedPrice} · ${item.installmentDate}',
                      style: const TextStyle(
                        color: _C.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(label: item.status, fg: colors.fg, bg: colors.bg),
            ],
          ),
          if (!isPaid && onPay != null) ...[
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: onPay,
              icon: const Icon(Icons.payment_rounded, size: 15),
              label: const Text('Pay Instalment'),
              style: FilledButton.styleFrom(
                backgroundColor: _C.brand,
                minimumSize: const Size(double.infinity, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Pay instalment sheet ──────────────────────────────────────────────────────
void _showPayInstalmentSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String customerUuid,
  required int orderId,
  required int instalmentPrice,
}) {
  showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PayInstalmentSheet(
      orderId: orderId,
      instalmentPrice: instalmentPrice,
      onSuccess: () {
        ref.invalidate(sellerCustomerInstalmentsProvider(customerUuid));
        SnackbarService().showSuccessSnackBar('Instalment payment recorded.');
      },
    ),
  );
}

class _PayInstalmentSheet extends ConsumerStatefulWidget {
  final int orderId;
  final int instalmentPrice;
  final VoidCallback onSuccess;

  const _PayInstalmentSheet({
    required this.orderId,
    required this.instalmentPrice,
    required this.onSuccess,
  });

  @override
  ConsumerState<_PayInstalmentSheet> createState() =>
      _PayInstalmentSheetState();
}

class _PayInstalmentSheetState extends ConsumerState<_PayInstalmentSheet> {
  late final TextEditingController _amountCtrl;
  final _formKey = GlobalKey<FormState>();
  String _method = 'By Hand';
  XFile? _receipt;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _amountCtrl =
        TextEditingController(text: widget.instalmentPrice.toString());
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(sellerInstalmentsRepositoryProvider).payInstalment(
            orderId: widget.orderId,
            instalmentPrice: _amountCtrl.text.trim(),
            paymentMethod: _method,
            receipt: _receipt == null ? null : File(_receipt!.path),
          );
      if (!mounted) return;
      Navigator.pop(context, true);
      widget.onSuccess();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _cleanError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 14,
        right: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 14,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Pay Instalment',
                        style: TextStyle(
                          color: _C.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _amountCtrl,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Instalment Amount *',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (v) {
                    final n = int.tryParse(v?.trim() ?? '');
                    if (n == null || n <= 0) return 'Enter a valid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _method,
                  decoration: InputDecoration(
                    labelText: 'Payment Method *',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'By Hand', child: Text('By Hand')),
                    DropdownMenuItem(
                        value: 'JazzCash', child: Text('JazzCash')),
                    DropdownMenuItem(
                        value: 'Easypaisa', child: Text('Easypaisa')),
                    DropdownMenuItem(value: 'Bank', child: Text('Bank')),
                  ],
                  onChanged: _saving
                      ? null
                      : (v) {
                          if (v != null) setState(() => _method = v);
                        },
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _saving
                      ? null
                      : () async {
                          final f = await ImagePicker().pickImage(
                              source: ImageSource.gallery, imageQuality: 80);
                          if (f != null) setState(() => _receipt = f);
                        },
                  icon: Icon(
                    _receipt != null
                        ? Icons.check_circle_outline_rounded
                        : Icons.photo_library_outlined,
                  ),
                  label: Text(
                      _receipt != null ? 'Receipt Added' : 'Attach Receipt (Optional)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        _receipt != null ? _C.success : _C.brand,
                    side: BorderSide(
                        color: _receipt != null ? _C.success : _C.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _C.danger.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: _C.danger.withValues(alpha: 0.20)),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: _C.danger,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: _saving ? null : _submit,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.payment_rounded, size: 18),
                  label: Text(_saving ? 'Processing…' : 'Submit Payment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.brand,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
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

// ── Shared tiny widgets ───────────────────────────────────────────────────────
class _StatusPill extends StatelessWidget {
  final String label;
  final Color fg;
  final Color bg;
  const _StatusPill({required this.label, required this.fg, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w900),
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
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: _C.brand),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                color: _C.muted, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) => Text(message,
      style: const TextStyle(
          color: _C.danger, fontSize: 12, fontWeight: FontWeight.w600));
}

class _EmptyInline extends StatelessWidget {
  final String label;
  const _EmptyInline({required this.label});

  @override
  Widget build(BuildContext context) => Text(label,
      style: const TextStyle(
          color: _C.muted, fontSize: 12, fontWeight: FontWeight.w600));
}

// ── Loading / Error full-screen views ─────────────────────────────────────────
class _LoadingView extends StatelessWidget {
  final SellerCustomer? initialCustomer;
  const _LoadingView({this.initialCustomer});

  @override
  Widget build(BuildContext context) {
    if (initialCustomer == null) {
      return const Center(child: CircularProgressIndicator(color: _C.brand));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _C.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: _C.brand.withValues(alpha: 0.1),
                child: Text(
                  _initials(initialCustomer!.name),
                  style: const TextStyle(
                    color: _C.brand,
                    fontSize: 11,
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
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(
                width: 20,
                height: 20,
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
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _C.text, fontWeight: FontWeight.w700)),
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

// ── Helpers ───────────────────────────────────────────────────────────────────
({Color fg, Color bg}) _statusColors(String status) {
  final s = status.toLowerCase();
  if (s.contains('paid') && !s.contains('unpaid')) {
    return (fg: _C.success, bg: _C.success.withValues(alpha: 0.12));
  }
  if (s.contains('unpaid') || s.contains('pending')) {
    return (fg: _C.warning, bg: _C.warning.withValues(alpha: 0.12));
  }
  if (s.contains('instal') || s.contains('deliver')) {
    return (fg: _C.info, bg: _C.info.withValues(alpha: 0.12));
  }
  if (s.contains('cancel')) {
    return (fg: _C.danger, bg: _C.danger.withValues(alpha: 0.12));
  }
  return (fg: _C.brand, bg: _C.brand.withValues(alpha: 0.12));
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return 'C';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
}

/// Shows just the filename from a path, not the full path.
String _shortPath(String path) {
  if (path == 'Not available') return '—';
  return path.split('/').last;
}

String _cleanError(Object error) {
  final text = error.toString().replaceFirst('Exception: ', '').trim();
  return text.isEmpty ? 'Something went wrong. Please try again.' : text;
}
