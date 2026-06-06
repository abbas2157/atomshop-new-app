<<<<<<< HEAD
import 'dart:io';

import 'package:atompro/core/services/snackbar_services.dart';
=======
import 'package:atompro/features/seller/core/design/design.dart';
import 'package:atompro/features/seller/core/widgets/widgets.dart';
>>>>>>> main
import 'package:atompro/features/seller/custom_orders/view/seller_custom_order_details_screen.dart';
import 'package:atompro/features/seller/customers/model/seller_customers_model.dart';
import 'package:atompro/features/seller/customers/viewmodel/seller_customers_viewmodel.dart';
import 'package:atompro/features/seller/instalments/repository/seller_instalments_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

// ── Root screen — wrapped in SellerThemeScope so the pushed route inherits the
//    correct theme even when the shell's theme differs from system theme.
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
    return SellerThemeScope(
      child: Builder(
        builder: (context) {
          final c = context.sellerColors;

          final profileState =
              ref.watch(sellerCustomerProfileProvider(customerUuid));
          final instalmentsState =
              ref.watch(sellerCustomerInstalmentsProvider(customerUuid));
          final ordersState =
              ref.watch(sellerCustomerCustomOrdersProvider(customerUuid));

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: c.isDark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark,
            child: Scaffold(
              backgroundColor: c.canvas,
              appBar: AppBar(
                backgroundColor: c.canvas,
                surfaceTintColor: Colors.transparent,
                title: Text('Customer Details', style: c.isDark
                    ? context.sellerText.titleMd.copyWith(color: c.textPrimary)
                    : context.sellerText.titleMd),
                titleSpacing: 0,
                iconTheme: IconThemeData(color: c.textPrimary),
                actions: [
                  IconButton(
                    tooltip: 'Refresh',
                    icon: Icon(Icons.refresh_rounded, color: c.textPrimary),
                    onPressed: () {
                      ref.invalidate(
                          sellerCustomerProfileProvider(customerUuid));
                      ref.invalidate(
                          sellerCustomerInstalmentsProvider(customerUuid));
                      ref.invalidate(
                          sellerCustomerCustomOrdersProvider(customerUuid));
                    },
                  ),
                ],
              ),
              body: profileState.when(
                loading: () =>
                    _LoadingView(initialCustomer: initialCustomer),
                error: (error, _) => SellerErrorState(
                  message: _cleanError(error),
                  onRetry: () => ref.invalidate(
                      sellerCustomerProfileProvider(customerUuid)),
                ),
                data: (details) => RefreshIndicator(
                  color: c.accent,
                  backgroundColor: c.surface,
                  onRefresh: () async {
                    ref.invalidate(
                        sellerCustomerProfileProvider(customerUuid));
                    ref.invalidate(
                        sellerCustomerInstalmentsProvider(customerUuid));
                    ref.invalidate(
                        sellerCustomerCustomOrdersProvider(customerUuid));
                    await Future.wait([
                      ref.read(
                          sellerCustomerProfileProvider(customerUuid).future),
                      ref.read(sellerCustomerInstalmentsProvider(customerUuid)
                          .future),
                      ref.read(sellerCustomerCustomOrdersProvider(customerUuid)
                          .future),
                    ]);
                  },
                  child: ListView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: AppInsets.pageWithNav,
                    children: [
                      // ── Hero ──────────────────────────────────────────
                      _HeroCard(details: details),
                      const Gap.v(AppSpace.md),

                      // ── Customer Information ──────────────────────────
                      _SectionCard(
                        title: 'Customer Information',
                        icon: Icons.person_outline_rounded,
                        child: Column(
                          children: [
                            _GRow(
                              'Identifier',
                              details.user.profile.identifier,
                              'Name',
                              details.user.name,
                            ),
                            _GRow(
                              'Phone',
                              details.user.phone,
                              'Email',
                              details.user.email,
                            ),
                            _GRow(
                              'Father Name',
                              details.user.profile.fatherName,
                              'CNIC',
                              details.user.profile.cnicNo,
                            ),
                            _GRow(
                              'Address',
                              details.user.profile.address,
                              'Res. Phone',
                              details.user.profile.residencePhone,
                            ),
                            _GRow(
                              'Office Address',
                              details.user.profile.officeAddress,
                              'Office Phone',
                              details.user.profile.officePhone,
                            ),
                            _GRow(
                              'Joined Date',
                              details.user.formattedCreatedAt,
                              'Joined Through',
                              details.user.joinedThrough,
                            ),
                            _GRow(
                              'Portal',
                              details.user.profile.portal,
                              'Status',
                              details.user.status,
                            ),
                          ],
                        ),
                      ),

                      // ── Customer Verification ─────────────────────────
                      if (details.verification.exists) ...[
                        const Gap.v(AppSpace.md),
                        _SectionCard(
                          title: 'Customer Verification',
                          icon: Icons.verified_user_outlined,
                          child: Column(
                            children: [
                              _GRow(
                                'Physical Meet',
                                details.verification.physicalMeet
                                    ? 'Yes'
                                    : 'No',
                                'Address Found',
                                details.verification.addressFound
                                    ? 'Yes'
                                    : 'No',
                              ),
                              _GRow(
                                'House',
                                details.verification.house,
                                'Work',
                                details.verification.work,
                              ),
                              _GRow(
                                'ID Card (Front)',
                                _shortPath(details.verification.idCardFront),
                                'ID Card (Back)',
                                _shortPath(details.verification.idCardBack),
                              ),
                              if (details.verification.selfie !=
                                  'Not available')
                                _GRow(
                                  'Selfie',
                                  _shortPath(details.verification.selfie),
                                  '',
                                  '',
                                ),
                            ],
                          ),
                        ),
                      ],

                      // ── Custom Orders ─────────────────────────────────
                      const Gap.v(AppSpace.md),
                      _SectionCard(
                        title: 'Custom Orders',
                        icon: Icons.receipt_long_outlined,
                        child: ordersState.when(
                          loading: () => const _InlineLoading(
                              label: 'Loading orders…'),
                          error: (e, _) =>
                              _InlineError(message: _cleanError(e)),
                          data: (data) => data.orders.isEmpty
                              ? const _EmptyInline(
                                  label: 'No custom orders yet.')
                              : Column(
                                  children: data.orders
                                      .map(
                                        (o) => _OrderTile(
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
                                        ),
                                      )
                                      .toList(growable: false),
                                ),
                        ),
                      ),

                      // ── Instalments ───────────────────────────────────
                      const Gap.v(AppSpace.md),
                      _SectionCard(
                        title: 'Instalments',
                        icon: Icons.payments_outlined,
                        child: instalmentsState.when(
                          loading: () => const _InlineLoading(
                              label: 'Loading instalments…'),
                          error: (e, _) =>
                              _InlineError(message: _cleanError(e)),
                          data: (data) => data.instalments.isEmpty
                              ? const _EmptyInline(
                                  label: 'No instalments yet.')
                              : Column(
                                  children: data.instalments
                                      .take(10)
                                      .map(
                                        (item) =>
                                            _InstalmentTile(item: item),
                                      )
                                      .toList(growable: false),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
<<<<<<< HEAD

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
=======
              ),
>>>>>>> main
            ),
          );
        },
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
    final c = context.sellerColors;
    final text = context.sellerText;
    final customer = details.user;
    final verified = customer.verified;

    return Container(
      decoration: BoxDecoration(
        gradient: c.headerGradient,
        borderRadius: AppRadius.brXl,
        boxShadow: c.floatingShadow,
      ),
      padding: const EdgeInsets.all(AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Avatar row ──────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SellerMonogram(name: customer.name, size: 52),
              const Gap.h(AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        color: Colors.white,
                        fontSize: 20,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Gap.v(AppSpace.xxs),
                    Text(
                      customer.phone,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Verified pill on gradient (white-tinted)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.sm,
                  vertical: AppSpace.xxs + 2,
                ),
                decoration: BoxDecoration(
                  color: verified
                      ? Colors.white.withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.14),
                  borderRadius: AppRadius.brPill,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.28),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      verified
                          ? Icons.verified_outlined
                          : Icons.schedule_outlined,
                      color: Colors.white,
                      size: 13,
                    ),
                    const Gap.h(AppSpace.xxs),
                    Text(
                      verified ? 'Verified' : 'Pending',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap.v(AppSpace.md),
          // ── KPI strip ───────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: 'Total Sales',
                  value: details.formattedTotalCustomSales,
                ),
              ),
              const Gap.h(AppSpace.xs),
              Expanded(
                child: _HeroMetric(
                  label: 'Recovery',
                  value: details.formattedTotalCustomRecovery,
                ),
              ),
              const Gap.h(AppSpace.xs),
              Expanded(
                child: _HeroMetric(
                  label: 'Rate',
                  value: details.formattedRecoveryPercentage,
                ),
              ),
            ],
          ),
          // ── Recovery bar ────────────────────────────────────────────
          const Gap.v(AppSpace.sm),
          Text(
            'Recovery rate',
            style: text.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const Gap.v(AppSpace.xxs),
          ClipRRect(
            borderRadius: AppRadius.brPill,
            child: LinearProgressIndicator(
              value: _clampPct(details.formattedRecoveryPercentage),
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// Hero metric tile (lives on the gradient, so uses white text)
class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;
  const _HeroMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.xs + 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: AppRadius.brMd,
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Roboto',
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap.v(AppSpace.xxs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section card ──────────────────────────────────────────────────────────────
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
    final c = context.sellerColors;
    final text = context.sellerText;

    return SellerCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header stripe
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.md,
              AppSpace.sm,
              AppSpace.md,
              AppSpace.sm,
            ),
            decoration: BoxDecoration(
              color: c.accentSurface,
              border: Border(bottom: BorderSide(color: c.border)),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.lg),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 15, color: c.accent),
                const Gap.h(AppSpace.xs - 2),
                Text(
                  title.toUpperCase(),
                  style: text.overline.copyWith(color: c.accent),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpace.md),
            child: child,
          ),
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
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _GCell(label: l1, value: v1)),
          if (l2.isNotEmpty) ...[
            const Gap.h(AppSpace.sm),
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
    final text = context.sellerText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: text.caption),
        const Gap.v(AppSpace.xxs),
        Text(
          value.isEmpty || value == 'Not available' ? '—' : value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: text.bodySm.copyWith(
            color: context.sellerColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
    final c = context.sellerColors;
    final text = context.sellerText;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.xs),
      child: SellerCard(
        onTap: onTap,
        color: c.surfaceAlt,
        elevated: false,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.sm,
          vertical: AppSpace.xs + 2,
        ),
        child: Row(
          children: [
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
                    '${order.formattedTotalDealPrice} · ${order.formattedCreatedAt}',
                    style: text.caption,
                  ),
                ],
              ),
            ),
            SellerStatusPill(label: order.status, dense: true),
            const Gap.h(AppSpace.xxs),
            Icon(
              Icons.chevron_right_rounded,
              color: c.textTertiary,
              size: 16,
            ),
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
    final c = context.sellerColors;
    final text = context.sellerText;
    final tone = SellerStatus.toneFor(item.status, c);
    final isPaid = item.status.toLowerCase() == 'paid';
<<<<<<< HEAD
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
=======

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.xs),
      child: SellerCard(
        color: isPaid ? c.successSurface : c.surfaceAlt,
        borderColor: isPaid
            ? c.success.withValues(alpha: 0.25)
            : c.border,
        elevated: false,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.sm,
          vertical: AppSpace.xs + 2,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.month, style: text.titleSm),
                  const Gap.v(AppSpace.xxs),
                  Text(
                    '${item.formattedPrice} · ${item.installmentDate}',
                    style: text.caption,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.xs,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: tone.bg,
                borderRadius: AppRadius.brPill,
                border: Border.all(color: tone.border),
              ),
              child: Text(
                item.status,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: tone.fg,
                ),
              ),
            ),
          ],
        ),
      ),
>>>>>>> main
    );
  }
}

// ── Inline helpers ────────────────────────────────────────────────────────────
class _InlineLoading extends StatelessWidget {
  final String label;
  const _InlineLoading({required this.label});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    return Row(
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: c.accent,
          ),
        ),
        const Gap.h(AppSpace.xs),
        Text(label, style: text.bodySm),
      ],
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    return Text(
      message,
      style: context.sellerText.bodySm.copyWith(color: c.danger),
    );
  }
}

class _EmptyInline extends StatelessWidget {
  final String label;
  const _EmptyInline({required this.label});

  @override
  Widget build(BuildContext context) =>
      Text(label, style: context.sellerText.bodySm);
}

// ── Full-screen loading (with optional initial-customer preview) ──────────────
class _LoadingView extends StatelessWidget {
  final SellerCustomer? initialCustomer;
  const _LoadingView({this.initialCustomer});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;

    if (initialCustomer == null) {
      return Center(
        child: CircularProgressIndicator(color: c.accent),
      );
    }

    return ListView(
      padding: AppInsets.pageWithNav,
      children: [
        SellerCard(
          child: Row(
            children: [
              SellerMonogram(name: initialCustomer!.name, size: 44),
              const Gap.h(AppSpace.sm),
              Expanded(
                child: Text(initialCustomer!.name, style: text.titleSm),
              ),
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: c.accent,
                ),
              ),
            ],
          ),
        ),
        const Gap.v(AppSpace.md),
        const SellerListSkeleton(count: 3, itemHeight: 100),
      ],
    );
  }
}

// ── Pure-logic helpers ────────────────────────────────────────────────────────
String _shortPath(String path) {
  if (path == 'Not available') return '—';
  return path.split('/').last;
}

String _cleanError(Object error) {
  final raw = error.toString().replaceFirst('Exception: ', '').trim();
  return raw.isEmpty ? 'Something went wrong. Please try again.' : raw;
}

double _clampPct(String pct) {
  final v = double.tryParse(pct.replaceAll('%', '').trim()) ?? 0;
  return (v / 100).clamp(0.0, 1.0);
}
