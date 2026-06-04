import 'package:atompro/core/services/snackbar_services.dart';
import 'package:atompro/features/seller/core/services/seller_file_service.dart';
import 'package:atompro/features/seller/custom_orders/model/seller_custom_orders_model.dart';
import 'package:atompro/features/seller/custom_orders/repository/seller_custom_orders_repository.dart';
import 'package:atompro/features/seller/custom_orders/viewmodel/seller_custom_orders_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract final class _D {
  static const brand = Color(0xFF3B5BDB);
  static const brandDeep = Color(0xFF1A2980);
  static const bg = Color(0xFFF4F6FC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF8FAFE);
  static const border = Color(0xFFE4E8F5);
  static const txt1 = Color(0xFF0A0F1E);
  static const txt2 = Color(0xFF6B7280);
  static const txt3 = Color(0xFF9CA3AF);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const info = Color(0xFF06B6D4);
}

class SellerCustomOrderDetailsScreen extends ConsumerWidget {
  final String orderUuid;
  final SellerCustomOrder? initialOrder;

  const SellerCustomOrderDetailsScreen({
    super.key,
    required this.orderUuid,
    this.initialOrder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sellerCustomOrderDetailsProvider(orderUuid));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _D.bg,
        appBar: AppBar(
          backgroundColor: _D.bg,
          surfaceTintColor: _D.bg,
          titleSpacing: 0,
          title: const Text(
            'Custom Order Details',
            style: TextStyle(
              color: _D.txt1,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Open PDF',
              onPressed: () => _openPdf(ref, orderUuid),
              icon: const Icon(Icons.picture_as_pdf_outlined),
            ),
            IconButton(
              tooltip: 'Refresh',
              onPressed: () {
                ref.invalidate(sellerCustomOrderDetailsProvider(orderUuid));
                ref.invalidate(sellerCustomOrderGuarantorProvider(orderUuid));
              },
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: state.when(
          loading: () => _LoadingView(initialOrder: initialOrder),
          error: (error, _) => _ErrorView(
            message: error.toString().replaceFirst('Exception: ', ''),
            onRetry: () =>
                ref.invalidate(sellerCustomOrderDetailsProvider(orderUuid)),
          ),
          data: (details) => _DetailsContent(
            details: details,
            orderUuid: orderUuid,
            guarantorState: ref.watch(
              sellerCustomOrderGuarantorProvider(orderUuid),
            ),
            onUpdateStatus: () => _showStatusSheet(
              context: context,
              ref: ref,
              orderUuid: orderUuid,
              currentStatus: details.order.status,
              receivedBy: details.user.name,
            ),
            // Close Deal is only relevant once the order is on Instalments
            onCloseDeal: (!details.order.dealClosed &&
                    details.order.status
                        .toLowerCase()
                        .contains('instalment'))
                ? () => _showCloseDealSheet(
                    context: context,
                    ref: ref,
                    orderUuid: orderUuid,
                    order: details.order,
                  )
                : null,
            onAddGuarantor: (initial) => _showGuarantorSheet(
              context: context,
              ref: ref,
              orderUuid: orderUuid,
              initial: initial,
            ),
            onRefresh: () async {
              ref.invalidate(sellerCustomOrderDetailsProvider(orderUuid));
              ref.invalidate(sellerCustomOrderGuarantorProvider(orderUuid));
              await Future.wait([
                ref.read(sellerCustomOrderDetailsProvider(orderUuid).future),
                ref.read(sellerCustomOrderGuarantorProvider(orderUuid).future),
              ]);
            },
          ),
        ),
      ),
    );
  }
}

Future<void> _openPdf(WidgetRef ref, String orderUuid) async {
  try {
    final url = await ref
        .read(sellerCustomOrdersRepositoryProvider)
        .getCustomOrderPdfUrl(orderUuid);
    await SellerFileService.openExternalUrl(url);
  } catch (e) {
    SnackbarService().showErrorSnackBar(_cleanError(e));
  }
}

class _DetailsContent extends StatelessWidget {
  final SellerCustomOrderDetails details;
  final String orderUuid;
  final AsyncValue<SellerCustomOrderGuarantor> guarantorState;
  final VoidCallback onUpdateStatus;
  final VoidCallback? onCloseDeal;
  final ValueChanged<SellerCustomOrderGuarantor?> onAddGuarantor;
  final Future<void> Function() onRefresh;

  const _DetailsContent({
    required this.details,
    required this.orderUuid,
    required this.guarantorState,
    required this.onUpdateStatus,
    required this.onCloseDeal,
    required this.onAddGuarantor,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final order = details.order;
    final user = details.user;
    final customer = user.customer;
    final specs = order.product.customFieldsMap;

    return RefreshIndicator(
      color: _D.brand,
      onRefresh: onRefresh,
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
        children: [
          _HeroCard(
            order: order,
            onUpdateStatus: onUpdateStatus,
            onCloseDeal: onCloseDeal,
          ),
          const SizedBox(height: 14),

          // ORDER DETAILS
          _SectionCard(
            title: 'Order Details',
            icon: Icons.receipt_long_outlined,
            child: _OrderDetailsContent(order: order),
          ),

          // PRODUCT SPECS (custom fields — only when present)
          if (specs.isNotEmpty) ...[
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Product Specifications',
              icon: Icons.tune_outlined,
              child: _SpecsGrid(specs: specs),
            ),
          ],

          // PRODUCT INFORMATION
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Product Information',
            icon: Icons.inventory_2_outlined,
            child: Column(
              children: [
                _GridRow('Product', order.product.title, 'PR Number', order.product.prNumber),
                _GridRow('Product Price', order.product.formattedPrice, 'Advance Price', order.product.formattedAdvancePrice),
              ],
            ),
          ),

          // OTHER DETAILS
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Other Details',
            icon: Icons.info_outline_rounded,
            child: Column(
              children: [
                _GridRow('Outstanding', 'Rs ${details.outstandingPrincipal}', 'Settlement', order.formattedSettlementAmount),
                _GridRow('Deal Closed', order.dealClosed ? 'Yes' : 'No', '', ''),
              ],
            ),
          ),

          // CUSTOMER DETAILS
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Customer Details',
            icon: Icons.person_outline_rounded,
            child: _CustomerContent(
              user: user,
              customer: customer,
              hasCustomer: customer.hasData,
            ),
          ),

          // INSTALMENT DETAILS
          if (details.instalments.isNotEmpty) ...[
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Instalment Details',
              icon: Icons.payments_outlined,
              child: _InstalmentsContent(items: details.instalments),
            ),
          ],

          // ORDER GUARANTORS
          const SizedBox(height: 12),
          _GuarantorSection(
            state: guarantorState,
            onAdd: () => onAddGuarantor(guarantorState.asData?.value),
          ),

          // ORDER CHANGE HISTORY
          if (details.statusHistory.isNotEmpty) ...[
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Order Change History',
              icon: Icons.history_rounded,
              child: _HistoryContent(items: details.statusHistory),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final SellerCustomOrderDetailOrder order;
  final VoidCallback onUpdateStatus;
  final VoidCallback? onCloseDeal;

  const _HeroCard({
    required this.order,
    required this.onUpdateStatus,
    required this.onCloseDeal,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _statusColors(order.status);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_D.brandDeep, _D.brand],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _D.brand.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: -34,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        order.product.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _StatusPill(
                      label: order.status,
                      fg: colors.fg,
                      bg: colors.bg,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
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
                        value: '${order.tenure} mo.',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _HeroChip(icon: Icons.public_rounded, label: order.portal),
                    _HeroChip(
                      icon: Icons.calendar_month_outlined,
                      label: order.formattedCreatedAt,
                    ),
                    _HeroChip(icon: Icons.tag_outlined, label: order.product.prNumber),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _HeroActionButton(
                        icon: Icons.edit_note_rounded,
                        label: 'Update Status',
                        onTap: onUpdateStatus,
                      ),
                    ),
                    if (onCloseDeal != null) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: _HeroActionButton(
                          icon: Icons.handshake_outlined,
                          label: 'Close Deal',
                          onTap: onCloseDeal!,
                        ),
                      ),
                    ],
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

class _HeroActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HeroActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.34)),
        minimumSize: const Size(0, 44),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            color: Colors.white.withValues(alpha: 0.62),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
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

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable section container ───────────────────────────────────────────────
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
        color: _D.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _D.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
            decoration: BoxDecoration(
              color: _D.brand.withValues(alpha: 0.05),
              border: const Border(bottom: BorderSide(color: _D.border)),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(13),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 15, color: _D.brand),
                const SizedBox(width: 7),
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: _D.txt1,
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
class _GridRow extends StatelessWidget {
  final String label1;
  final String value1;
  final String label2;
  final String value2;

  const _GridRow(this.label1, this.value1, this.label2, this.value2);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _Cell(label: label1, value: value1)),
          const SizedBox(width: 12),
          Expanded(child: _Cell(label: label2, value: value2)),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String label;
  final String value;
  const _Cell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _D.txt3,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value.isEmpty ? '—' : value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _D.txt1,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

// ── Order details grid ────────────────────────────────────────────────────────
class _OrderDetailsContent extends StatelessWidget {
  final SellerCustomOrderDetailOrder order;
  const _OrderDetailsContent({required this.order});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _GridRow('Total Deal Amount', order.formattedTotalDealPrice, 'Advance Amount', order.formattedAdvancePrice),
        _GridRow('Sourcing Agent Fee', order.formattedSourcingAgentFee, 'Installment Tenure', '${order.tenure} months'),
        _GridRow('Monthly %', '${order.perMonthPercentage}% / mo', 'Order Date', order.formattedCreatedAt),
      ],
    );
  }
}

// ── Product specs grid — TITLE VALUE | TITLE VALUE ───────────────────────────
class _SpecsGrid extends StatelessWidget {
  final Map<String, String> specs;
  const _SpecsGrid({required this.specs});

  @override
  Widget build(BuildContext context) {
    final entries = specs.entries.toList();
    final rows = <List<MapEntry<String, String>>>[];
    for (var i = 0; i < entries.length; i += 2) {
      rows.add([
        entries[i],
        if (i + 1 < entries.length) entries[i + 1],
      ]);
    }
    return Column(
      children: rows.asMap().entries.map((re) {
        final isLast = re.key == rows.length - 1;
        final pair = re.value;
        return Container(
          margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Expanded(child: _SpecCell(title: pair[0].key, value: pair[0].value)),
                if (pair.length > 1) ...[
                  const SizedBox(width: 1),
                  Container(width: 1, color: _D.border),
                  const SizedBox(width: 1),
                  Expanded(child: _SpecCell(title: pair[1].key, value: pair[1].value)),
                ],
              ],
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _SpecCell extends StatelessWidget {
  final String title;
  final String value;
  const _SpecCell({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _D.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              title,
              style: const TextStyle(
                color: _D.txt2,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 5,
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(
                color: _D.txt1,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Customer details ──────────────────────────────────────────────────────────
class _CustomerContent extends StatelessWidget {
  final SellerCustomOrderUser user;
  final SellerCustomOrderCustomer customer;
  final bool hasCustomer;

  const _CustomerContent({
    required this.user,
    required this.customer,
    required this.hasCustomer,
  });

  @override
  Widget build(BuildContext context) {
    const na = '—';
    return Column(
      children: [
        _GridRow('Identifier', hasCustomer ? customer.identifier : na,
            'Name', user.name),
        _GridRow('Phone', user.phone, 'Email', user.email),
        _GridRow('Father Name', hasCustomer ? customer.fatherName : na,
            'CNIC', hasCustomer ? customer.cnicNo : na),
        _GridRow('Address', hasCustomer ? customer.address : na,
            'Res. Phone', hasCustomer ? customer.residencePhone : na),
        _GridRow(
            'Office Address', hasCustomer ? customer.officeAddress : na,
            'Office Phone', hasCustomer ? customer.officePhone : na),
        _GridRow('Joined Date', user.formattedCreatedAt,
            'Joined Through', user.joinedThrough),
        _GridRow('Portal', hasCustomer ? customer.portal : na,
            'Status', user.status),
        if (hasCustomer) ...[
          const SizedBox(height: 4),
          const Divider(height: 1, color: _D.border),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                'KYC Verification',
                style: TextStyle(
                  color: _D.txt2,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              _StatusPill(
                label: customer.verified ? 'Verified' : 'Not Verified',
                fg: customer.verified ? _D.success : _D.danger,
                bg: (customer.verified ? _D.success : _D.danger)
                    .withValues(alpha: 0.12),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ── Instalments ───────────────────────────────────────────────────────────────
class _InstalmentsContent extends StatelessWidget {
  final List<SellerCustomOrderInstalment> items;
  const _InstalmentsContent({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.asMap().entries.map((e) {
        final isLast = e.key == items.length - 1;
        final item = e.value;
        final fg = item.isPaid ? _D.success : _D.warning;
        final bg = (item.isPaid ? _D.success : _D.warning)
            .withValues(alpha: 0.12);
        return Container(
          margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: item.isPaid
                ? _D.success.withValues(alpha: 0.04)
                : _D.surfaceAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: item.isPaid
                  ? _D.success.withValues(alpha: 0.25)
                  : _D.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.month,
                      style: const TextStyle(
                        color: _D.txt1,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _StatusPill(label: item.status, fg: fg, bg: bg),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 1, color: _D.border),
              const SizedBox(height: 8),
              _GridRow(
                'Amount',
                item.formattedInstalmentPrice,
                'Paid Amount',
                item.formattedPaidPrice,
              ),
              _GridRow(
                'Due Date',
                item.instalmentDate,
                'Paid Date',
                item.paidDate,
              ),
              if (item.paymentMethod != 'Not available')
                _GridRow('Payment Method', item.paymentMethod, '', ''),
            ],
          ),
        );
      }).toList(growable: false),
    );
  }
}

// ── Order change history (timeline) ──────────────────────────────────────────
class _HistoryContent extends StatelessWidget {
  final List<SellerCustomOrderStatusHistory> items;
  const _HistoryContent({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.asMap().entries.map((e) {
        final isLast = e.key == items.length - 1;
        final item = e.value;
        final c = _statusColors(item.status);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: c.bg,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: c.fg.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    Icons.radio_button_checked_rounded,
                    size: 13,
                    color: c.fg,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 1.5,
                    height: 44,
                    color: _D.border,
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _StatusPill(
                          label: item.status,
                          fg: c.fg,
                          bg: c.bg,
                        ),
                        const Spacer(),
                        Text(
                          item.formattedCreatedAt,
                          style: const TextStyle(
                            color: _D.txt3,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (item.comment.isNotEmpty &&
                        item.comment != 'Not available') ...[
                      const SizedBox(height: 5),
                      Text(
                        item.comment,
                        style: const TextStyle(
                          color: _D.txt1,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ],
                    // Render all payload key-value pairs
                    if (item.payloadDetails.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _D.surfaceAlt,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _D.border),
                        ),
                        child: Column(
                          children: item.payloadDetails.entries.map((kv) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 110,
                                    child: Text(
                                      _formatPayloadKey(kv.key),
                                      style: const TextStyle(
                                        color: _D.txt3,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      kv.value.isEmpty ? '—' : kv.value,
                                      style: const TextStyle(
                                        color: _D.txt1,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(growable: false),
                        ),
                      ),
                    ],
                    const SizedBox(height: 3),
                    Text(
                      item.role,
                      style: const TextStyle(
                        color: _D.txt3,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(growable: false),
    );
  }
}

class _GuarantorSection extends StatelessWidget {
  final AsyncValue<SellerCustomOrderGuarantor> state;
  final VoidCallback onAdd;

  const _GuarantorSection({required this.state, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Order Guarantors',
      icon: Icons.assignment_ind_outlined,
      child: state.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Text(
                  'Loading guarantor...',
                  style: TextStyle(
                    color: _D.txt2,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          error: (error, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SheetError(
                message: error.toString().replaceFirst('Exception: ', ''),
              ),
              const SizedBox(height: 10),
              _InlineAction(
                icon: Icons.add_rounded,
                label: 'Add Guarantor',
                onTap: onAdd,
              ),
            ],
          ),
          data: (guarantor) {
            if (!guarantor.exists) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'No guarantor added for this order.',
                    style: TextStyle(
                      color: _D.txt2,
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InlineAction(
                    icon: Icons.add_rounded,
                    label: 'Add Guarantor',
                    onTap: onAdd,
                  ),
                ],
              );
            }
            return Column(
              children: [
                _GridRow('Name', guarantor.name, 'Phone', guarantor.phone),
                _GridRow('CNIC', guarantor.cnic, 'Added', guarantor.createdAt),
                _GridRow('Address', guarantor.address, '', ''),
                const SizedBox(height: 10),
                _InlineAction(
                  icon: Icons.edit_outlined,
                  label: 'Update Guarantor',
                  onTap: onAdd,
                ),
              ],
            );
          },
        ),
    );
  }
}

class _InlineAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _InlineAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: _D.brand,
        side: const BorderSide(color: _D.border),
        minimumSize: const Size(double.infinity, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  final SellerCustomOrder? initialOrder;

  const _LoadingView({this.initialOrder});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      children: [
        if (initialOrder != null)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _D.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _D.border),
            ),
            child: Row(
              children: [
                const CircularProgressIndicator(strokeWidth: 2),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Loading ${initialOrder!.product.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _D.txt1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          const Center(child: CircularProgressIndicator()),
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
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _D.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _D.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, color: _D.danger, size: 34),
              const SizedBox(height: 12),
              const Text(
                'Could not load order details',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _D.txt1,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _D.txt2, fontSize: 12),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Converts snake_case payload key to "Title Case".
String _formatPayloadKey(String key) {
  return key
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

({Color fg, Color bg}) _statusColors(String status) {
  final s = status.toLowerCase();
  if (s.contains('complete') || s.contains('deliver')) {
    return (fg: _D.success, bg: _D.success.withValues(alpha: 0.12));
  }
  if (s.contains('pending')) {
    return (fg: _D.warning, bg: _D.warning.withValues(alpha: 0.14));
  }
  if (s.contains('cancel')) {
    return (fg: _D.danger, bg: _D.danger.withValues(alpha: 0.12));
  }
  if (s.contains('verif')) {
    return (fg: _D.info, bg: _D.info.withValues(alpha: 0.14));
  }
  return (fg: _D.brand, bg: _D.brand.withValues(alpha: 0.12));
}

String _cleanError(Object error) {
  final text = error.toString().replaceFirst('Exception: ', '').trim();
  return text.isEmpty ? 'Something went wrong. Please try again.' : text;
}

Future<void> _showStatusSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String orderUuid,
  required String currentStatus,
  required String receivedBy,
}) async {
  final changed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _StatusUpdateSheet(
      orderUuid: orderUuid,
      currentStatus: currentStatus,
      receivedBy: receivedBy,
    ),
  );

  if (changed == true) {
    ref.invalidate(sellerCustomOrderDetailsProvider(orderUuid));
    ref.invalidate(sellerCustomOrdersRepositoryProvider);
  }
}

Future<void> _showCloseDealSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String orderUuid,
  required SellerCustomOrderDetailOrder order,
}) async {
  final changed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CloseDealSheet(orderUuid: orderUuid, order: order),
  );

  if (changed == true) {
    ref.invalidate(sellerCustomOrderDetailsProvider(orderUuid));
    ref.invalidate(sellerCustomOrdersRepositoryProvider);
  }
}

Future<void> _showGuarantorSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String orderUuid,
  required SellerCustomOrderGuarantor? initial,
}) async {
  final changed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _GuarantorSheet(orderUuid: orderUuid, initial: initial),
  );

  if (changed == true) {
    ref.invalidate(sellerCustomOrderGuarantorProvider(orderUuid));
    ref.invalidate(sellerCustomOrderDetailsProvider(orderUuid));
  }
}

class _GuarantorSheet extends ConsumerStatefulWidget {
  final String orderUuid;
  final SellerCustomOrderGuarantor? initial;

  const _GuarantorSheet({required this.orderUuid, this.initial});

  @override
  ConsumerState<_GuarantorSheet> createState() => _GuarantorSheetState();
}

class _GuarantorSheetState extends ConsumerState<_GuarantorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _cnicCtrl;
  late final TextEditingController _addressCtrl;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _nameCtrl = TextEditingController(
      text: initial?.exists == true ? initial!.name : '',
    );
    _phoneCtrl = TextEditingController(
      text: initial?.exists == true ? initial!.phone : '',
    );
    _cnicCtrl = TextEditingController(
      text: initial?.exists == true ? initial!.cnic : '',
    );
    _addressCtrl = TextEditingController(
      text: initial?.exists == true ? initial!.address : '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _cnicCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref
          .read(sellerCustomOrdersRepositoryProvider)
          .storeCustomOrderGuarantor(
            orderUuid: widget.orderUuid,
            name: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            cnic: _cnicCtrl.text.trim(),
            address: _addressCtrl.text.trim(),
          );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initial?.exists == true;
    return _SheetShell(
      title: editing ? 'Update Guarantor' : 'Add Guarantor',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameCtrl,
              enabled: !_saving,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) {
                if (value == null || value.trim().length < 3) {
                  return 'Enter guarantor name.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              enabled: !_saving,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Phone'),
              validator: (value) {
                final digits = value?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
                if (digits.length < 10) return 'Enter a valid phone number.';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cnicCtrl,
              enabled: !_saving,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'CNIC'),
              validator: (value) {
                final digits = value?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
                if (digits.length < 13) return 'Enter a valid CNIC.';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressCtrl,
              enabled: !_saving,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Address'),
              validator: (value) {
                if (value == null || value.trim().length < 8) {
                  return 'Enter guarantor address.';
                }
                return null;
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              _SheetError(message: _error!),
            ],
            const SizedBox(height: 18),
            _SheetButton(
              label: editing ? 'Update Guarantor' : 'Save Guarantor',
              icon: Icons.assignment_ind_outlined,
              loading: _saving,
              onTap: _submit,
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
  final String receivedBy;

  const _StatusUpdateSheet({
    required this.orderUuid,
    required this.currentStatus,
    required this.receivedBy,
  });

  @override
  ConsumerState<_StatusUpdateSheet> createState() => _StatusUpdateSheetState();
}

class _StatusUpdateSheetState extends ConsumerState<_StatusUpdateSheet> {
  final _formKey = GlobalKey<FormState>();
  final _receivedByCtrl = TextEditingController();

  late String _status = _statusOptions.contains(widget.currentStatus)
      ? widget.currentStatus
      : _statusOptions.first;
  bool _saving = false;
  String? _error;

  static const _statusOptions = [
    'Pending',
    'Varification',
    'Instalments',
    'Delivered',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    final value = widget.receivedBy.trim();
    if (value.isNotEmpty && value != 'Not available') {
      _receivedByCtrl.text = value;
    }
  }

  @override
  void dispose() {
    _receivedByCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref
          .read(sellerCustomOrdersRepositoryProvider)
          .updateCustomOrderStatus(
            orderUuid: widget.orderUuid,
            status: _status,
            receivedBy: _receivedByCtrl.text.trim(),
          );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: [
                for (final status in _statusOptions)
                  DropdownMenuItem(value: status, child: Text(status)),
              ],
              onChanged: _saving
                  ? null
                  : (value) {
                      if (value != null) setState(() => _status = value);
                    },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _receivedByCtrl,
              enabled: !_saving,
              decoration: const InputDecoration(
                labelText: 'Received / handled by',
                hintText: 'Customer or receiver name',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Receiver name is required.';
                }
                return null;
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              _SheetError(message: _error!),
            ],
            const SizedBox(height: 18),
            _SheetButton(
              label: 'Save Status',
              icon: Icons.save_outlined,
              loading: _saving,
              onTap: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _CloseDealSheet extends ConsumerStatefulWidget {
  final String orderUuid;
  final SellerCustomOrderDetailOrder order;

  const _CloseDealSheet({required this.orderUuid, required this.order});

  @override
  ConsumerState<_CloseDealSheet> createState() => _CloseDealSheetState();
}

class _CloseDealSheetState extends ConsumerState<_CloseDealSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _totalCtrl;
  late final TextEditingController _advanceCtrl;
  late final TextEditingController _tenureCtrl;
  late final TextEditingController _percentageCtrl;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _totalCtrl = TextEditingController(
      text: widget.order.totalDealPrice.toString(),
    );
    _advanceCtrl = TextEditingController(
      text: widget.order.advancePrice.toString(),
    );
    _tenureCtrl = TextEditingController(text: widget.order.tenure.toString());
    _percentageCtrl = TextEditingController(
      text: widget.order.perMonthPercentage.toString(),
    );
  }

  @override
  void dispose() {
    _totalCtrl.dispose();
    _advanceCtrl.dispose();
    _tenureCtrl.dispose();
    _percentageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref
          .read(sellerCustomOrdersRepositoryProvider)
          .closeCustomOrderDeal(
            orderUuid: widget.orderUuid,
            totalDealPrice: _totalCtrl.text.trim(),
            advancePrice: _advanceCtrl.text.trim(),
            installmentTenure: _tenureCtrl.text.trim(),
            perMonthPercentage: _percentageCtrl.text.trim(),
          );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: 'Close Deal',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _NumberField(
              controller: _totalCtrl,
              label: 'Total deal price',
              enabled: !_saving,
            ),
            const SizedBox(height: 12),
            _NumberField(
              controller: _advanceCtrl,
              label: 'Advance price',
              enabled: !_saving,
            ),
            const SizedBox(height: 12),
            _NumberField(
              controller: _tenureCtrl,
              label: 'Installment tenure',
              enabled: !_saving,
            ),
            const SizedBox(height: 12),
            _NumberField(
              controller: _percentageCtrl,
              label: 'Per month percentage',
              enabled: !_saving,
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              _SheetError(message: _error!),
            ],
            const SizedBox(height: 18),
            _SheetButton(
              label: 'Close Deal',
              icon: Icons.handshake_outlined,
              loading: _saving,
              onTap: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool enabled;

  const _NumberField({
    required this.controller,
    required this.label,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final number = int.tryParse(value?.trim() ?? '');
        if (number == null || number <= 0) return '$label is required.';
        return null;
      },
    );
  }
}

class _SheetShell extends StatelessWidget {
  final String title;
  final Widget child;

  const _SheetShell({required this.title, required this.child});

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
          color: _D.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: _D.txt1,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetError extends StatelessWidget {
  final String message;

  const _SheetError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _D.danger.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _D.danger.withValues(alpha: 0.20)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: _D.danger,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool loading;
  final VoidCallback onTap;

  const _SheetButton({
    required this.label,
    required this.icon,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
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
          : Icon(icon, size: 18),
      label: Text(loading ? 'Saving' : label),
      style: ElevatedButton.styleFrom(
        backgroundColor: _D.brand,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
