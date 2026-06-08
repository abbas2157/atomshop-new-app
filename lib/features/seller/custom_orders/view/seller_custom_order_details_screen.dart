// ═══════════════════════════════════════════════════════════════════════════
//  seller_custom_order_details_screen.dart  —  Seller Design System
//
//  Rebuilt on the unified Seller Design System. All Riverpod / business logic
//  is unchanged: detail + guarantor providers, PDF open, status update, close
//  deal and guarantor save flows behave exactly as before. Pure presentation.
//
//  This screen is pushed as its own route, so the top Scaffold is wrapped in a
//  [SellerThemeScope]; the modal sheets capture brightness and wrap their
//  result in an explicit [Theme] so they render in the correct palette.
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:io';

import 'package:atompro/core/services/snackbar_services.dart';
import 'package:atompro/features/seller/core/design/design.dart';
import 'package:atompro/features/seller/core/services/seller_file_service.dart';
import 'package:atompro/features/seller/core/widgets/widgets.dart';
import 'package:atompro/features/seller/custom_orders/model/seller_custom_orders_model.dart';
import 'package:atompro/features/seller/custom_orders/repository/seller_custom_orders_repository.dart';
import 'package:atompro/features/seller/custom_orders/viewmodel/seller_custom_orders_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

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
    return SellerThemeScope(
      child: Builder(
        builder: (context) {
          final c = context.sellerColors;
          final text = context.sellerText;
          final state = ref.watch(sellerCustomOrderDetailsProvider(orderUuid));

          return Scaffold(
            backgroundColor: c.canvas,
            appBar: AppBar(
              backgroundColor: c.canvas,
              surfaceTintColor: c.canvas,
              titleSpacing: 0,
              title: Text('Custom Order Details', style: text.titleMd),
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
              error: (error, _) => SellerErrorState(
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
                onUpdateStatus: () => _showStatusPickerSheet(
                  context: context,
                  ref: ref,
                  orderUuid: orderUuid,
                  details: details,
                ),
                // Close Deal is only relevant once the order is on Instalments
                onCloseDeal:
                    (!details.order.dealClosed &&
                        details.order.status
                            .toLowerCase()
                            .contains('instalment'))
                    ? () => _showCloseDealSheet(
                        context: context,
                        ref: ref,
                        orderUuid: orderUuid,
                        details: details,
                      )
                    : null,
                // Pay Instalment — only while there's an unpaid instalment
                // the server can settle (Instalment / Outstanding type).
                onPayInstalment:
                    _nextPayableInstalment(details.instalments) != null
                    ? (instalment) => _showPayInstalmentSheet(
                        context: context,
                        ref: ref,
                        orderUuid: orderUuid,
                        details: details,
                        instalment: instalment,
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
          );
        },
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
  final ValueChanged<SellerCustomOrderInstalment>? onPayInstalment;
  final ValueChanged<SellerCustomOrderGuarantor?> onAddGuarantor;
  final Future<void> Function() onRefresh;

  const _DetailsContent({
    required this.details,
    required this.orderUuid,
    required this.guarantorState,
    required this.onUpdateStatus,
    required this.onCloseDeal,
    required this.onPayInstalment,
    required this.onAddGuarantor,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final order = details.order;
    final user = details.user;
    final customer = user.customer;
    final specs = order.product.customFieldsMap;

    return RefreshIndicator(
      color: c.accent,
      backgroundColor: c.surface,
      onRefresh: onRefresh,
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: AppInsets.pageWithNav,
        children: [
          _HeroCard(
            order: order,
            onUpdateStatus: onUpdateStatus,
            onCloseDeal: onCloseDeal,
            onPayInstalment: onPayInstalment == null
                ? null
                : () => onPayInstalment!(_nextPayableInstalment(details.instalments)!),
          ),
          const Gap.v(AppSpace.md),

          // ORDER DETAILS
          _SectionCard(
            title: 'Order Details',
            icon: Icons.receipt_long_outlined,
            child: _OrderDetailsContent(order: order),
          ),

          // PRODUCT SPECS (custom fields — only when present)
          if (specs.isNotEmpty) ...[
            const Gap.v(AppSpace.sm),
            _SectionCard(
              title: 'Product Specifications',
              icon: Icons.tune_outlined,
              child: _SpecsGrid(specs: specs),
            ),
          ],

          // PRODUCT INFORMATION
          const Gap.v(AppSpace.sm),
          _SectionCard(
            title: 'Product Information',
            icon: Icons.inventory_2_outlined,
            child: Column(
              children: [
                _GridRow('Product', order.product.title, 'PR Number',
                    order.product.prNumber),
                _GridRow('Product Price', order.product.formattedPrice,
                    'Advance Price', order.product.formattedAdvancePrice),
              ],
            ),
          ),

          // OTHER DETAILS
          const Gap.v(AppSpace.sm),
          _SectionCard(
            title: 'Other Details',
            icon: Icons.info_outline_rounded,
            child: Column(
              children: [
                _GridRow('Outstanding', 'Rs ${details.outstandingPrincipal}',
                    'Settlement', order.formattedSettlementAmount),
                _GridRow(
                    'Deal Closed', order.dealClosed ? 'Yes' : 'No', '', ''),
              ],
            ),
          ),

          // CUSTOMER DETAILS
          const Gap.v(AppSpace.sm),
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
            const Gap.v(AppSpace.sm),
            _SectionCard(
              title: 'Instalment Details',
              icon: Icons.payments_outlined,
              child: _InstalmentsContent(
                items: details.instalments,
                onPayInstalment: onPayInstalment,
              ),
            ),
          ],

          // ORDER GUARANTORS
          const Gap.v(AppSpace.sm),
          _GuarantorSection(
            state: guarantorState,
            onAdd: () => onAddGuarantor(guarantorState.asData?.value),
          ),

          // ORDER CHANGE HISTORY
          if (details.statusHistory.isNotEmpty) ...[
            const Gap.v(AppSpace.sm),
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

// ── Hero card ────────────────────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final SellerCustomOrderDetailOrder order;
  final VoidCallback onUpdateStatus;
  final VoidCallback? onCloseDeal;
  final VoidCallback? onPayInstalment;

  const _HeroCard({
    required this.order,
    required this.onUpdateStatus,
    required this.onCloseDeal,
    required this.onPayInstalment,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;

    return Container(
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
            padding: const EdgeInsets.all(AppSpace.md + 2),
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
                          fontFamily: 'Roboto',
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                    ),
                    const Gap.h(AppSpace.sm),
                    _HeroStatusPill(label: order.status),
                  ],
                ),
                const Gap.v(AppSpace.md),
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
                const Gap.v(AppSpace.sm),
                Wrap(
                  spacing: AppSpace.xs,
                  runSpacing: AppSpace.xs,
                  children: [
                    _HeroChip(icon: Icons.public_rounded, label: order.portal),
                    _HeroChip(
                      icon: Icons.calendar_month_outlined,
                      label: order.formattedCreatedAt,
                    ),
                    _HeroChip(
                        icon: Icons.tag_outlined,
                        label: order.product.prNumber),
                  ],
                ),
                const Gap.v(AppSpace.md),
                if (onPayInstalment != null) ...[
                  _HeroActionButton(
                    icon: Icons.payments_rounded,
                    label: 'Pay Instalment',
                    onTap: onPayInstalment!,
                    filled: true,
                  ),
                  const Gap.v(AppSpace.sm),
                ],
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
                      const Gap.h(AppSpace.sm),
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

/// A status pill rendered on the hero gradient (frosted, always white text).
class _HeroStatusPill extends StatelessWidget {
  final String label;
  const _HeroStatusPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.xs + 1,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: AppRadius.brPill,
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontFamily: 'Roboto',
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HeroActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  /// Solid white fill for the highest-priority action on the card (e.g. the
  /// next collectible payment) so it stands out from the outlined actions.
  final bool filled;

  const _HeroActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final fg = filled ? c.accent : Colors.white;
    return Material(
      color: filled ? Colors.white : Colors.white.withValues(alpha: 0.14),
      borderRadius: AppRadius.brMd,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 44,
          width: double.infinity,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brMd,
            border: filled
                ? null
                : Border.all(color: Colors.white.withValues(alpha: 0.34)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: fg),
              const Gap.h(AppSpace.xs),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: fg,
                    fontSize: 12,
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
            fontFamily: 'Roboto',
            color: Colors.white.withValues(alpha: 0.62),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Gap.v(AppSpace.xxs - 1),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.xs + 1,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: AppRadius.brPill,
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const Gap.h(AppSpace.xxs + 1),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Roboto',
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
    final c = context.sellerColors;
    return SellerCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.md,
              vertical: AppSpace.sm,
            ),
            decoration: BoxDecoration(
              color: c.accentSurface,
              border: Border(bottom: BorderSide(color: c.border)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: c.accent),
                const Gap.h(AppSpace.xs),
                Expanded(
                  child: Text(title.toUpperCase(),
                      style: context.sellerText.overline.copyWith(
                        color: c.accent,
                      )),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(AppSpace.md), child: child),
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
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _Cell(label: label1, value: value1)),
          const Gap.h(AppSpace.sm),
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
    final text = context.sellerText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: text.caption),
        const Gap.v(AppSpace.xxs - 1),
        Text(
          value.isEmpty ? '—' : value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: text.bodySm.copyWith(
            color: context.sellerColors.textPrimary,
            fontWeight: FontWeight.w700,
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
        _GridRow('Total Deal Amount', order.formattedTotalDealPrice,
            'Advance Amount', order.formattedAdvancePrice),
        _GridRow('Sourcing Agent Fee', order.formattedSourcingAgentFee,
            'Installment Tenure', '${order.tenure} months'),
        _GridRow('Monthly %', '${order.perMonthPercentage}% / mo', 'Order Date',
            order.formattedCreatedAt),
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
    final c = context.sellerColors;
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
          margin: EdgeInsets.only(bottom: isLast ? 0 : AppSpace.xs),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                    child: _SpecCell(title: pair[0].key, value: pair[0].value)),
                if (pair.length > 1) ...[
                  const Gap.h(AppSpace.xs),
                  Container(width: 1, color: c.border),
                  const Gap.h(AppSpace.xs),
                  Expanded(
                      child:
                          _SpecCell(title: pair[1].key, value: pair[1].value)),
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
    final c = context.sellerColors;
    final text = context.sellerText;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.sm,
        vertical: AppSpace.xs,
      ),
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: AppRadius.brSm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(title, style: text.caption),
          ),
          const Gap.h(AppSpace.xs - 2),
          Expanded(
            flex: 5,
            child: Text(
              value.isEmpty ? '—' : value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.bodySm.copyWith(
                color: c.textPrimary,
                fontWeight: FontWeight.w800,
              ),
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
    final c = context.sellerColors;
    final text = context.sellerText;
    const na = '—';
    return Column(
      children: [
        _GridRow('Identifier', hasCustomer ? customer.identifier : na, 'Name',
            user.name),
        _GridRow('Phone', user.phone, 'Email', user.email),
        _GridRow('Father Name', hasCustomer ? customer.fatherName : na, 'CNIC',
            hasCustomer ? customer.cnicNo : na),
        _GridRow('Address', hasCustomer ? customer.address : na, 'Res. Phone',
            hasCustomer ? customer.residencePhone : na),
        _GridRow('Office Address', hasCustomer ? customer.officeAddress : na,
            'Office Phone', hasCustomer ? customer.officePhone : na),
        _GridRow('Joined Date', user.formattedCreatedAt, 'Joined Through',
            user.joinedThrough),
        _GridRow('Portal', hasCustomer ? customer.portal : na, 'Status',
            user.status),
        if (hasCustomer) ...[
          const Gap.v(AppSpace.xxs),
          Divider(height: 1, color: c.divider),
          const Gap.v(AppSpace.sm),
          Row(
            children: [
              Text('KYC Verification', style: text.label),
              const Spacer(),
              SellerStatusPill(
                label: customer.verified ? 'Verified' : 'Not Verified',
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
  /// Pays whichever instalment the server will actually settle next — see
  /// [_nextPayableInstalment]. Null when nothing is currently payable.
  final ValueChanged<SellerCustomOrderInstalment>? onPayInstalment;

  const _InstalmentsContent({required this.items, required this.onPayInstalment});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final nextPayable = _nextPayableInstalment(items);
    return Column(
      children: items.asMap().entries.map((e) {
        final isLast = e.key == items.length - 1;
        final item = e.value;
        final tone = item.isPaid ? c.successTone : c.warningTone;
        final isNextPayable = onPayInstalment != null && item.id == nextPayable?.id;
        return Container(
          margin: EdgeInsets.only(bottom: isLast ? 0 : AppSpace.sm),
          padding: const EdgeInsets.all(AppSpace.sm),
          decoration: BoxDecoration(
            color: item.isPaid ? c.successSurface : c.surfaceAlt,
            borderRadius: AppRadius.brSm,
            border: Border.all(
              color: isNextPayable
                  ? c.accent
                  : item.isPaid
                  ? tone.border
                  : c.border,
              width: isNextPayable ? 1.4 : 1,
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
                      style: text.bodyLg.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  SellerStatusPill(label: item.status),
                ],
              ),
              const Gap.v(AppSpace.xs),
              Divider(height: 1, color: c.divider),
              const Gap.v(AppSpace.xs),
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
              if (isNextPayable) ...[
                const Gap.v(AppSpace.xs),
                SellerButton(
                  label: 'Pay This Instalment',
                  icon: Icons.payments_outlined,
                  onPressed: () => onPayInstalment!(item),
                ),
              ],
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
    final c = context.sellerColors;
    final text = context.sellerText;
    return Column(
      children: items.asMap().entries.map((e) {
        final isLast = e.key == items.length - 1;
        final item = e.value;
        final tone = SellerStatus.toneFor(item.status, c);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tone.bg,
                    shape: BoxShape.circle,
                    border: Border.all(color: tone.border),
                  ),
                  child: Icon(
                    Icons.radio_button_checked_rounded,
                    size: 13,
                    color: tone.fg,
                  ),
                ),
                if (!isLast)
                  Container(width: 1.5, height: 44, color: c.border),
              ],
            ),
            const Gap.h(AppSpace.sm),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpace.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SellerStatusPill(label: item.status),
                        const Spacer(),
                        Text(item.formattedCreatedAt, style: text.caption),
                      ],
                    ),
                    if (item.comment.isNotEmpty &&
                        item.comment != 'Not available') ...[
                      const Gap.v(AppSpace.xxs + 1),
                      Text(
                        item.comment,
                        style: text.bodySm.copyWith(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    // Render all payload key-value pairs
                    if (item.payloadDetails.isNotEmpty) ...[
                      const Gap.v(AppSpace.xs - 2),
                      Container(
                        padding: const EdgeInsets.all(AppSpace.xs),
                        decoration: BoxDecoration(
                          color: c.surfaceAlt,
                          borderRadius: AppRadius.brSm,
                          border: Border.all(color: c.border),
                        ),
                        child: Column(
                          children: item.payloadDetails.entries.map((kv) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpace.xxs / 2,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 110,
                                    child: Text(
                                      _formatPayloadKey(kv.key),
                                      style: text.caption,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      kv.value.isEmpty ? '—' : kv.value,
                                      style: text.caption.copyWith(
                                        color: c.textPrimary,
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
                    const Gap.v(AppSpace.xxs - 1),
                    Text(item.role, style: text.caption),
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
    final text = context.sellerText;
    return _SectionCard(
      title: 'Order Guarantors',
      icon: Icons.assignment_ind_outlined,
      child: state.when(
        loading: () => Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
          child: Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const Gap.h(AppSpace.sm),
              Text('Loading guarantor...', style: text.bodySm),
            ],
          ),
        ),
        error: (error, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SheetError(
              message: error.toString().replaceFirst('Exception: ', ''),
            ),
            const Gap.v(AppSpace.sm),
            SellerButton.secondary(
              label: 'Add Guarantor',
              icon: Icons.add_rounded,
              onPressed: onAdd,
            ),
          ],
        ),
        data: (guarantor) {
          if (!guarantor.exists) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('No guarantor added for this order.', style: text.bodySm),
                const Gap.v(AppSpace.sm),
                SellerButton.secondary(
                  label: 'Add Guarantor',
                  icon: Icons.add_rounded,
                  onPressed: onAdd,
                ),
              ],
            );
          }
          return Column(
            children: [
              _GridRow('Name', guarantor.name, 'Phone', guarantor.phone),
              _GridRow('CNIC', guarantor.cnic, 'Added', guarantor.createdAt),
              _GridRow('Address', guarantor.address, '', ''),
              const Gap.v(AppSpace.xs),
              SellerButton.secondary(
                label: 'Update Guarantor',
                icon: Icons.edit_outlined,
                onPressed: onAdd,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  final SellerCustomOrder? initialOrder;

  const _LoadingView({this.initialOrder});

  @override
  Widget build(BuildContext context) {
    final text = context.sellerText;
    if (initialOrder == null) {
      return const SellerListSkeleton();
    }
    return ListView(
      padding: AppInsets.pageWithNav,
      children: [
        SellerCard(
          padding: const EdgeInsets.all(AppSpace.md + 2),
          child: Row(
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const Gap.h(AppSpace.sm),
              Expanded(
                child: Text(
                  'Loading ${initialOrder!.product.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyLg.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ],
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

String _cleanError(Object error) {
  final text = error.toString().replaceFirst('Exception: ', '').trim();
  return text.isEmpty ? 'Something went wrong. Please try again.' : text;
}

/// The instalment that `POST /instalment/pay` will actually settle next —
/// the server always marks the first `Unpaid` row of type Instalment or
/// Outstanding as Paid, regardless of which row the seller taps.
SellerCustomOrderInstalment? _nextPayableInstalment(
  List<SellerCustomOrderInstalment> items,
) {
  for (final item in items) {
    if (!item.isPaid &&
        (item.type == 'Instalment' || item.type == 'Outstanding')) {
      return item;
    }
  }
  return null;
}

// ═══════════════════════════════════════════════════════════════════════════
//  MODAL SHEETS (status / close-deal / guarantor)
// ═══════════════════════════════════════════════════════════════════════════
/// Opens the status picker. Each row launches its own form sheet (below).
Future<void> _showStatusPickerSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String orderUuid,
  required SellerCustomOrderDetails details,
}) async {
  final dark = context.sellerIsDark;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Theme(
      data: dark ? SellerTheme.dark : SellerTheme.light,
      child: _StatusPickerSheet(orderUuid: orderUuid, details: details),
    ),
  );
}

Future<void> _showCloseDealSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String orderUuid,
  required SellerCustomOrderDetails details,
}) async {
  final dark = context.sellerIsDark;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Theme(
      data: dark ? SellerTheme.dark : SellerTheme.light,
      child: _CloseDealSheet(orderUuid: orderUuid, details: details),
    ),
  );
}

Future<void> _showPayInstalmentSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String orderUuid,
  required SellerCustomOrderDetails details,
  required SellerCustomOrderInstalment instalment,
}) async {
  final dark = context.sellerIsDark;
  final paid = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Theme(
      data: dark ? SellerTheme.dark : SellerTheme.light,
      child: _PayInstalmentSheet(
        orderUuid: orderUuid,
        orderId: details.order.id,
        instalment: instalment,
        recoveryMembers: details.recoveryMembers,
      ),
    ),
  );

  if (paid == true) {
    ref.invalidate(sellerCustomOrderDetailsProvider(orderUuid));
  }
}

Future<void> _showGuarantorSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String orderUuid,
  required SellerCustomOrderGuarantor? initial,
}) async {
  final dark = context.sellerIsDark;
  final changed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Theme(
      data: dark ? SellerTheme.dark : SellerTheme.light,
      child: _GuarantorSheet(orderUuid: orderUuid, initial: initial),
    ),
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
            _SheetField(
              controller: _nameCtrl,
              label: 'Name',
              enabled: !_saving,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().length < 3) {
                  return 'Enter guarantor name.';
                }
                return null;
              },
            ),
            const Gap.v(AppSpace.sm),
            _SheetField(
              controller: _phoneCtrl,
              label: 'Phone',
              enabled: !_saving,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              validator: (value) {
                final digits = value?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
                if (digits.length < 10) return 'Enter a valid phone number.';
                return null;
              },
            ),
            const Gap.v(AppSpace.sm),
            _SheetField(
              controller: _cnicCtrl,
              label: 'CNIC',
              enabled: !_saving,
              textInputAction: TextInputAction.next,
              validator: (value) {
                final digits = value?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
                if (digits.length < 13) return 'Enter a valid CNIC.';
                return null;
              },
            ),
            const Gap.v(AppSpace.sm),
            _SheetField(
              controller: _addressCtrl,
              label: 'Address',
              enabled: !_saving,
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().length < 8) {
                  return 'Enter guarantor address.';
                }
                return null;
              },
            ),
            if (_error != null) ...[
              const Gap.v(AppSpace.sm),
              _SheetError(message: _error!),
            ],
            const Gap.v(AppSpace.md),
            SellerButton(
              label: editing ? 'Update Guarantor' : 'Save Guarantor',
              icon: Icons.assignment_ind_outlined,
              loading: _saving,
              onPressed: _saving ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  STATUS PICKER  —  lists the 6 statuses; gates everything but Cancelled when
//  the customer is not verified. Each row opens its specific form sheet.
// ═══════════════════════════════════════════════════════════════════════════
enum _OrderStatus {
  varification('Varification', Icons.verified_user_outlined, 1),
  processing('Processing', Icons.engineering_outlined, 2),
  delivered('Delivered', Icons.local_shipping_outlined, 3),
  instalments('Instalments', Icons.payments_outlined, 4),
  completed('Completed', Icons.task_alt_outlined, 5),
  cancelled('Cancelled', Icons.cancel_outlined, 99);

  const _OrderStatus(this.label, this.icon, this.rank);
  final String label;
  final IconData icon;

  /// Position in the linear flow. `Cancelled` (99) sits outside the chain.
  final int rank;
}

/// Rank of the order's CURRENT status in the linear flow:
/// Pending → Varification → Processing → Delivered → Instalments → Completed.
/// Completed (5) and Cancelled (99) are terminal.
int _statusRank(String status) {
  switch (status.toLowerCase().trim()) {
    case 'pending':
      return 0;
    case 'varification':
    case 'verification':
      return 1;
    case 'processing':
      return 2;
    case 'delivered':
      return 3;
    case 'instalments':
    case 'installments':
      return 4;
    case 'completed':
      return 5;
    case 'cancelled':
    case 'canceled':
      return 99;
    default:
      return 0; // unknown → treat as a fresh order
  }
}

class _StatusPickerSheet extends ConsumerWidget {
  final String orderUuid;
  final SellerCustomOrderDetails details;

  const _StatusPickerSheet({required this.orderUuid, required this.details});

  void _openForm(BuildContext context, WidgetRef ref, _OrderStatus status) {
    final dark = context.sellerIsDark;
    // Close the picker, then open the specific form sheet.
    Navigator.pop(context);
    final parentContext = context;
    showModalBottomSheet<void>(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Theme(
        data: dark ? SellerTheme.dark : SellerTheme.light,
        child: switch (status) {
          _OrderStatus.varification =>
            _VarificationSheet(orderUuid: orderUuid),
          _OrderStatus.processing => _ProcessingSheet(orderUuid: orderUuid),
          _OrderStatus.delivered => _DeliveredSheet(orderUuid: orderUuid),
          _OrderStatus.instalments =>
            _InstalmentsSheet(orderUuid: orderUuid, details: details),
          _OrderStatus.completed => _CompletedSheet(orderUuid: orderUuid),
          _OrderStatus.cancelled => _CancelledSheet(orderUuid: orderUuid),
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final verified = details.user.customer.verified;
    final currentRank = _statusRank(details.order.status);

    // Forward-only: offer just the next step in the chain, plus Cancelled
    // (allowed at any stage before a terminal state). Never a previous status.
    final allowed = _OrderStatus.values.where((s) {
      if (s == _OrderStatus.cancelled) return currentRank < 5;
      return s.rank == currentRank + 1;
    }).toList();

    final showVerifyWarning =
        !verified && allowed.any((s) => s != _OrderStatus.cancelled);

    return _SheetShell(
      title: 'Update Status',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Current status context
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.sm),
            child: Row(
              children: [
                Text('Current: ', style: text.bodySm),
                SellerStatusPill(label: details.order.status, dense: true),
              ],
            ),
          ),
          if (allowed.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpace.md),
              decoration: BoxDecoration(
                color: c.surfaceAlt,
                borderRadius: AppRadius.brMd,
                border: Border.all(color: c.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 18, color: c.textTertiary),
                  const Gap.h(AppSpace.xs),
                  Expanded(
                    child: Text(
                      'This order is "${details.order.status}". No further '
                      'status changes are available.',
                      style: text.bodySm,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            if (showVerifyWarning) ...[
              Container(
                padding: const EdgeInsets.all(AppSpace.sm),
                decoration: BoxDecoration(
                  color: c.warningSurface,
                  borderRadius: AppRadius.brSm,
                  border: Border.all(color: c.warningTone.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 18, color: c.warningTone.fg),
                    const Gap.h(AppSpace.xs),
                    Expanded(
                      child: Text(
                        'This customer is not verified. Verify them first to '
                        'proceed.',
                        style: text.bodySm.copyWith(color: c.warningTone.fg),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap.v(AppSpace.sm),
            ],
            for (final status in allowed) ...[
              _StatusRow(
                status: status,
                // Only Cancelled stays enabled when unverified.
                enabled: verified || status == _OrderStatus.cancelled,
                onTap: () => _openForm(context, ref, status),
              ),
              if (status != allowed.last) const Gap.v(AppSpace.xs),
            ],
          ],
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final _OrderStatus status;
  final bool enabled;
  final VoidCallback onTap;

  const _StatusRow({
    required this.status,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    return Material(
      color: enabled ? c.surfaceAlt : c.surfaceAlt.withValues(alpha: 0.5),
      borderRadius: AppRadius.brMd,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.sm,
            vertical: AppSpace.sm,
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: enabled ? c.accentSurface : c.surface,
                  borderRadius: AppRadius.brSm,
                ),
                child: Icon(
                  status.icon,
                  size: 18,
                  color: enabled ? c.accent : c.textTertiary,
                ),
              ),
              const Gap.h(AppSpace.sm),
              Expanded(
                child: Text(
                  status.label,
                  style: text.bodyLg.copyWith(
                    fontWeight: FontWeight.w700,
                    color: enabled ? c.textPrimary : c.textTertiary,
                  ),
                ),
              ),
              Icon(
                enabled ? Icons.chevron_right_rounded : Icons.lock_outline_rounded,
                size: 18,
                color: enabled ? c.textTertiary : c.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Status 1: Varification ───────────────────────────────────────────────────
class _VarificationSheet extends ConsumerStatefulWidget {
  final String orderUuid;
  const _VarificationSheet({required this.orderUuid});

  @override
  ConsumerState<_VarificationSheet> createState() => _VarificationSheetState();
}

class _VarificationSheetState extends ConsumerState<_VarificationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _commentCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(sellerCustomOrdersRepositoryProvider).setVarification(
            orderUuid: widget.orderUuid,
            comment: _commentCtrl.text.trim(),
          );
      if (!mounted) return;
      Navigator.pop(context);
      ref.invalidate(sellerCustomOrderDetailsProvider(widget.orderUuid));
      SnackbarService().showSuccessSnackBar('Order moved to Varification.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      SnackbarService()
          .showErrorSnackBar(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: 'Varification',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SheetField(
              controller: _commentCtrl,
              label: 'Verification comment',
              hint: 'Notes about the verification',
              enabled: !_saving,
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Comment is required.';
                }
                return null;
              },
            ),
            const Gap.v(AppSpace.md),
            SellerButton(
              label: 'Submit Varification',
              icon: Icons.verified_user_outlined,
              loading: _saving,
              onPressed: _saving ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status 2: Processing (up to 2 optional guarantors) ───────────────────────
class _GuarantorEntry {
  final nameCtrl = TextEditingController();
  final fatherNameCtrl = TextEditingController();
  final professionCtrl = TextEditingController();
  final relationCtrl = TextEditingController();
  final resAddressCtrl = TextEditingController();
  final officeAddressCtrl = TextEditingController();
  final resTelCtrl = TextEditingController();
  final officeTelCtrl = TextEditingController();
  final cnicCtrl = TextEditingController();
  String houseType = 'owned';

  void dispose() {
    nameCtrl.dispose();
    fatherNameCtrl.dispose();
    professionCtrl.dispose();
    relationCtrl.dispose();
    resAddressCtrl.dispose();
    officeAddressCtrl.dispose();
    resTelCtrl.dispose();
    officeTelCtrl.dispose();
    cnicCtrl.dispose();
  }

  /// Builds the map of non-empty fields; returns null if nothing was entered.
  Map<String, String>? toMap() {
    final map = <String, String>{};
    void put(String key, String value) {
      final v = value.trim();
      if (v.isNotEmpty) map[key] = v;
    }

    put('name', nameCtrl.text);
    put('father_name', fatherNameCtrl.text);
    put('profession', professionCtrl.text);
    put('relation', relationCtrl.text);
    put('res_address', resAddressCtrl.text);
    put('office_address', officeAddressCtrl.text);
    put('res_tel', resTelCtrl.text);
    put('office_tel', officeTelCtrl.text);
    put('cnic', cnicCtrl.text);
    if (map.isEmpty) return null;
    // house_type only matters if other fields exist.
    map['house_type'] = houseType;
    return map;
  }
}

class _ProcessingSheet extends ConsumerStatefulWidget {
  final String orderUuid;
  const _ProcessingSheet({required this.orderUuid});

  @override
  ConsumerState<_ProcessingSheet> createState() => _ProcessingSheetState();
}

class _ProcessingSheetState extends ConsumerState<_ProcessingSheet> {
  final List<_GuarantorEntry> _entries = [_GuarantorEntry()];
  bool _saving = false;

  @override
  void dispose() {
    for (final e in _entries) {
      e.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      final guarantors = _entries
          .map((e) => e.toMap())
          .whereType<Map<String, String>>()
          .toList(growable: false);
      await ref.read(sellerCustomOrdersRepositoryProvider).setProcessing(
            orderUuid: widget.orderUuid,
            guarantors: guarantors,
          );
      if (!mounted) return;
      Navigator.pop(context);
      ref.invalidate(sellerCustomOrderDetailsProvider(widget.orderUuid));
      SnackbarService().showSuccessSnackBar('Order moved to Processing.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      SnackbarService()
          .showErrorSnackBar(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = context.sellerText;
    return _SheetShell(
      title: 'Processing',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Guarantors are optional. You may add up to 2, or submit without '
            'any.',
            style: text.bodySm,
          ),
          const Gap.v(AppSpace.sm),
          for (var i = 0; i < _entries.length; i++) ...[
            _GuarantorCard(
              index: i,
              entry: _entries[i],
              enabled: !_saving,
              onRemove: _entries.length > 1
                  ? () {
                      setState(() {
                        _entries.removeAt(i).dispose();
                      });
                    }
                  : null,
            ),
            const Gap.v(AppSpace.sm),
          ],
          if (_entries.length < 2)
            SellerButton.secondary(
              label: 'Add another guarantor',
              icon: Icons.person_add_alt_1_outlined,
              onPressed: _saving
                  ? null
                  : () => setState(() => _entries.add(_GuarantorEntry())),
            ),
          const Gap.v(AppSpace.md),
          SellerButton(
            label: 'Submit Processing',
            icon: Icons.engineering_outlined,
            loading: _saving,
            onPressed: _saving ? null : _submit,
          ),
        ],
      ),
    );
  }
}

class _GuarantorCard extends StatelessWidget {
  final int index;
  final _GuarantorEntry entry;
  final bool enabled;
  final VoidCallback? onRemove;

  const _GuarantorCard({
    required this.index,
    required this.entry,
    required this.enabled,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    return Container(
      padding: const EdgeInsets.all(AppSpace.sm),
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Guarantor ${index + 1}',
                    style: text.label.copyWith(color: c.accent)),
              ),
              if (onRemove != null)
                InkWell(
                  onTap: enabled ? onRemove : null,
                  borderRadius: AppRadius.brPill,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpace.xxs),
                    child: Icon(Icons.delete_outline_rounded,
                        size: 18, color: c.danger),
                  ),
                ),
            ],
          ),
          const Gap.v(AppSpace.xs),
          _SheetField(
            controller: entry.nameCtrl,
            label: 'Name',
            enabled: enabled,
          ),
          const Gap.v(AppSpace.xs),
          _SheetField(
            controller: entry.fatherNameCtrl,
            label: 'Father name',
            enabled: enabled,
          ),
          const Gap.v(AppSpace.xs),
          _SheetField(
            controller: entry.professionCtrl,
            label: 'Profession',
            enabled: enabled,
          ),
          const Gap.v(AppSpace.xs),
          _SheetField(
            controller: entry.relationCtrl,
            label: 'Relation',
            enabled: enabled,
          ),
          const Gap.v(AppSpace.xs),
          _SheetField(
            controller: entry.cnicCtrl,
            label: 'CNIC (xxxxx-xxxxxxx-x)',
            enabled: enabled,
            keyboardType: TextInputType.number,
            inputFormatters: [_CnicFormatter()],
          ),
          const Gap.v(AppSpace.xs),
          _SheetField(
            controller: entry.resAddressCtrl,
            label: 'Residential address',
            enabled: enabled,
            maxLines: 2,
          ),
          const Gap.v(AppSpace.xs),
          _SheetField(
            controller: entry.officeAddressCtrl,
            label: 'Office address',
            enabled: enabled,
            maxLines: 2,
          ),
          const Gap.v(AppSpace.xs),
          _SheetField(
            controller: entry.resTelCtrl,
            label: 'Residential tel',
            enabled: enabled,
            keyboardType: TextInputType.phone,
          ),
          const Gap.v(AppSpace.xs),
          _SheetField(
            controller: entry.officeTelCtrl,
            label: 'Office tel',
            enabled: enabled,
            keyboardType: TextInputType.phone,
          ),
          const Gap.v(AppSpace.xs),
          Text('House type', style: text.label),
          const Gap.v(AppSpace.xxs),
          _SegmentedField<String>(
            value: entry.houseType,
            enabled: enabled,
            options: const [
              ('owned', 'Owned'),
              ('rented', 'Rented'),
              ('family', 'Family'),
            ],
            onChanged: (v) => entry.houseType = v,
          ),
        ],
      ),
    );
  }
}

// ── Status 3: Delivered ──────────────────────────────────────────────────────
class _DeliveredSheet extends ConsumerStatefulWidget {
  final String orderUuid;
  const _DeliveredSheet({required this.orderUuid});

  @override
  ConsumerState<_DeliveredSheet> createState() => _DeliveredSheetState();
}

class _DeliveredSheetState extends ConsumerState<_DeliveredSheet> {
  String? _receivedBy;
  File? _photo;
  bool _saving = false;

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1400,
    );
    if (picked == null) return;
    setState(() => _photo = File(picked.path));
  }

  Future<void> _submit() async {
    if (_receivedBy == null) {
      SnackbarService().showErrorSnackBar('Please select who received it.');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(sellerCustomOrdersRepositoryProvider).setDelivered(
            orderUuid: widget.orderUuid,
            receivedBy: _receivedBy!,
            photo: _photo,
          );
      if (!mounted) return;
      Navigator.pop(context);
      ref.invalidate(sellerCustomOrderDetailsProvider(widget.orderUuid));
      SnackbarService().showSuccessSnackBar('Order marked as Delivered.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      SnackbarService()
          .showErrorSnackBar(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = context.sellerText;
    return _SheetShell(
      title: 'Delivered',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Received by', style: text.label),
          const Gap.v(AppSpace.xxs),
          _SegmentedField<String>(
            value: _receivedBy,
            enabled: !_saving,
            options: const [
              ('By Himself', 'By Himself'),
              ('By Someone else', 'By Someone else'),
            ],
            onChanged: (v) => setState(() => _receivedBy = v),
          ),
          const Gap.v(AppSpace.md),
          Text('Delivery photo (optional)', style: text.label),
          const Gap.v(AppSpace.xs),
          _ReceiptPicker(
            receipt: _photo,
            onPick: _saving ? () {} : _pickPhoto,
            onClear: () => setState(() => _photo = null),
          ),
          const Gap.v(AppSpace.md),
          SellerButton(
            label: 'Submit Delivered',
            icon: Icons.local_shipping_outlined,
            loading: _saving,
            onPressed: _saving ? null : _submit,
          ),
        ],
      ),
    );
  }
}

// ── Status 4: Instalments ────────────────────────────────────────────────────
class _InstalmentsSheet extends ConsumerStatefulWidget {
  final String orderUuid;
  final SellerCustomOrderDetails details;
  const _InstalmentsSheet({required this.orderUuid, required this.details});

  @override
  ConsumerState<_InstalmentsSheet> createState() => _InstalmentsSheetState();
}

class _InstalmentsSheetState extends ConsumerState<_InstalmentsSheet> {
  static const _methods = ['By Hand', 'JazzCash', 'Easypaisa', 'Bank'];

  late final TextEditingController _advanceCtrl;
  late final TextEditingController _percentageCtrl;
  late final TextEditingController _sourcingCtrl;
  late final TextEditingController _tenureCtrl;
  late final TextEditingController _dayCtrl;

  String _method = _methods.first;
  int? _recoveryMemberId;
  File? _receipt;
  bool _saving = false;

  SellerCustomOrderDetailOrder get _order => widget.details.order;

  @override
  void initState() {
    super.initState();
    _advanceCtrl =
        TextEditingController(text: _order.advancePrice.toString());
    _percentageCtrl = TextEditingController(
      text: _order.perMonthPercentage.toDouble().toStringAsFixed(1),
    );
    _sourcingCtrl =
        TextEditingController(text: _order.sourcingAgentFee.toString());
    final tenure = (_order.tenure >= 3 && _order.tenure <= 24)
        ? _order.tenure
        : 6;
    _tenureCtrl = TextEditingController(text: tenure.toString());
    _dayCtrl = TextEditingController(text: '5');
    for (final ctrl in [
      _advanceCtrl,
      _percentageCtrl,
      _sourcingCtrl,
      _tenureCtrl,
    ]) {
      ctrl.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _advanceCtrl.dispose();
    _percentageCtrl.dispose();
    _sourcingCtrl.dispose();
    _tenureCtrl.dispose();
    _dayCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickReceipt() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1400,
    );
    if (picked == null) return;
    setState(() => _receipt = File(picked.path));
  }

  // Live preview maths (display only).
  double get _advance => double.tryParse(_advanceCtrl.text.trim()) ?? 0;
  double get _perMonthPct => double.tryParse(_percentageCtrl.text.trim()) ?? 0;
  double get _sourcingFee => double.tryParse(_sourcingCtrl.text.trim()) ?? 0;
  int get _tenure => int.tryParse(_tenureCtrl.text.trim()) ?? 0;
  double get _financed => _order.product.price - _advance;
  double get _totalMarkup =>
      _tenure == 0 ? 0 : (_perMonthPct * _tenure / 100) * _financed;
  double get _perInstallment => _tenure == 0
      ? 0
      : (_financed + _totalMarkup + _sourcingFee) / _tenure;
  double get _totalDeal => _order.product.price + _totalMarkup + _sourcingFee;

  String? _validate() {
    if ((double.tryParse(_advanceCtrl.text.trim()) ?? -1) < 0) {
      return 'Enter a valid advance price.';
    }
    final pct = double.tryParse(_percentageCtrl.text.trim());
    if (pct == null || pct < 0.0 || pct > 6.0) {
      return 'Per month percentage must be between 0.0 and 6.0.';
    }
    if ((double.tryParse(_sourcingCtrl.text.trim()) ?? -1) < 0) {
      return 'Enter a valid sourcing agent fee.';
    }
    if (_tenure < 3 || _tenure > 24) {
      return 'Installment tenure must be between 3 and 24.';
    }
    final day = int.tryParse(_dayCtrl.text.trim());
    if (day == null || day < 1 || day > 31) {
      return 'Day of month must be between 1 and 31.';
    }
    return null;
  }

  Future<void> _submit() async {
    final error = _validate();
    if (error != null) {
      SnackbarService().showErrorSnackBar(error);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(sellerCustomOrdersRepositoryProvider).setInstalments(
            orderUuid: widget.orderUuid,
            advancePrice: _advanceCtrl.text.trim(),
            perMonthPercentage: _percentageCtrl.text.trim(),
            sourcingAgentFee: _sourcingCtrl.text.trim(),
            installmentTenure: _tenureCtrl.text.trim(),
            paymentMethod: _method,
            dayOfMonth: _dayCtrl.text.trim(),
            recoveryMemberId: _recoveryMemberId?.toString(),
            receipt: _receipt,
          );
      if (!mounted) return;
      Navigator.pop(context);
      ref.invalidate(sellerCustomOrderDetailsProvider(widget.orderUuid));
      SnackbarService().showSuccessSnackBar('Installment plan created.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      SnackbarService()
          .showErrorSnackBar(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final members = widget.details.recoveryMembers;

    return _SheetShell(
      title: 'Instalments',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DecimalField(
            controller: _advanceCtrl,
            label: 'Advance price',
            enabled: !_saving,
            decimal: false,
          ),
          const Gap.v(AppSpace.sm),
          _DecimalField(
            controller: _percentageCtrl,
            label: 'Per month % (0.0 – 6.0)',
            enabled: !_saving,
            decimal: true,
          ),
          const Gap.v(AppSpace.sm),
          _DecimalField(
            controller: _sourcingCtrl,
            label: 'Sourcing agent fee',
            enabled: !_saving,
            decimal: false,
          ),
          const Gap.v(AppSpace.sm),
          _DecimalField(
            controller: _tenureCtrl,
            label: 'Installment tenure (3 – 24)',
            enabled: !_saving,
            decimal: false,
          ),
          const Gap.v(AppSpace.sm),
          _DecimalField(
            controller: _dayCtrl,
            label: 'Day of month (1 – 31)',
            enabled: !_saving,
            decimal: false,
          ),
          const Gap.v(AppSpace.md),
          Text('Payment method', style: text.label),
          const Gap.v(AppSpace.xs),
          _MethodChips(
            methods: _methods,
            selected: _method,
            enabled: !_saving,
            onChanged: (m) => setState(() => _method = m),
          ),
          const Gap.v(AppSpace.md),
          Text('Recovery member (optional)', style: text.label),
          const Gap.v(AppSpace.xs),
          _RecoveryMemberDropdown(
            members: members,
            value: _recoveryMemberId,
            enabled: !_saving,
            onChanged: (v) => setState(() => _recoveryMemberId = v),
          ),
          const Gap.v(AppSpace.md),
          Text('Receipt (optional)', style: text.label),
          const Gap.v(AppSpace.xs),
          _ReceiptPicker(
            receipt: _receipt,
            onPick: _saving ? () {} : _pickReceipt,
            onClear: () => setState(() => _receipt = null),
          ),
          const Gap.v(AppSpace.md),
          // ── Live calculation preview ──
          Container(
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              color: c.accentSurface,
              borderRadius: AppRadius.brMd,
              border: Border.all(color: c.accentTone.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.calculate_outlined, size: 16, color: c.accent),
                    const Gap.h(AppSpace.xs),
                    Text('Plan preview',
                        style: text.label.copyWith(color: c.accent)),
                  ],
                ),
                const Gap.v(AppSpace.sm),
                _PreviewRow(label: 'Financed amount', value: _money(_financed)),
                _PreviewRow(label: 'Total markup', value: _money(_totalMarkup)),
                _PreviewRow(
                    label: 'Per installment', value: _money(_perInstallment)),
                _PreviewRow(
                  label: 'Total deal',
                  value: _money(_totalDeal),
                  emphasize: true,
                ),
              ],
            ),
          ),
          const Gap.v(AppSpace.md),
          SellerButton(
            label: 'Create Installment Plan',
            icon: Icons.payments_outlined,
            loading: _saving,
            onPressed: _saving ? null : _submit,
          ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;
  const _PreviewRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: emphasize
                    ? text.label.copyWith(color: c.textPrimary)
                    : text.bodySm),
          ),
          Text(
            value,
            style: (emphasize ? text.bodyLg : text.bodySm).copyWith(
              fontWeight: FontWeight.w800,
              color: emphasize ? c.accent : c.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status 5: Completed ──────────────────────────────────────────────────────
class _CompletedSheet extends ConsumerStatefulWidget {
  final String orderUuid;
  const _CompletedSheet({required this.orderUuid});

  @override
  ConsumerState<_CompletedSheet> createState() => _CompletedSheetState();
}

class _CompletedSheetState extends ConsumerState<_CompletedSheet> {
  bool _saving = false;

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(sellerCustomOrdersRepositoryProvider)
          .setCompleted(orderUuid: widget.orderUuid);
      if (!mounted) return;
      Navigator.pop(context);
      ref.invalidate(sellerCustomOrderDetailsProvider(widget.orderUuid));
      SnackbarService().showSuccessSnackBar('Order marked as Completed.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      SnackbarService()
          .showErrorSnackBar(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    return _SheetShell(
      title: 'Completed',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpace.sm),
            decoration: BoxDecoration(
              color: c.successSurface,
              borderRadius: AppRadius.brSm,
              border: Border.all(color: c.successTone.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.task_alt_outlined,
                    size: 18, color: c.successTone.fg),
                const Gap.h(AppSpace.xs),
                Expanded(
                  child: Text(
                    'Mark this order complete? All installments must be paid.',
                    style: text.bodySm.copyWith(color: c.successTone.fg),
                  ),
                ),
              ],
            ),
          ),
          const Gap.v(AppSpace.md),
          SellerButton(
            label: 'Mark Completed',
            icon: Icons.task_alt_outlined,
            loading: _saving,
            onPressed: _saving ? null : _submit,
          ),
        ],
      ),
    );
  }
}

// ── Status 6: Cancelled ──────────────────────────────────────────────────────
class _CancelledSheet extends ConsumerStatefulWidget {
  final String orderUuid;
  const _CancelledSheet({required this.orderUuid});

  @override
  ConsumerState<_CancelledSheet> createState() => _CancelledSheetState();
}

class _CancelledSheetState extends ConsumerState<_CancelledSheet> {
  static const _verificationFailed = [
    'N/A',
    'Invalid Contact Details (Wrong/Unreachable phone number)',
    'Incorrect Customer Information (Mismatch in name, CNIC, or address)',
    'Unresponsive Customer (No answer to calls/messages)',
    'Suspicious/Fraudulent Activity (Fake documents or identity concerns)',
  ];
  static const _planRejected = [
    'N/A',
    'Credit Criteria Not Met (Low score or insufficient income)',
    'Required Documents Missing/Invalid (ID, salary slip, bank statement, etc.)',
    'Poor Payment History (Previous defaults on installments)',
    'High Financial Risk Detected (Red flags from verification team)',
  ];
  // value → label; the first uses an empty value with an "N/A" label.
  static const _productUnavailable = <(String, String)>[
    ('', 'N/A'),
    ('Out of Stock (Product no longer available)',
        'Out of Stock (Product no longer available)'),
    ('Discontinued by Seller (No longer being sold)',
        'Discontinued by Seller (No longer being sold)'),
    ('Listing Error (Wrong price, details, or duplicate listing)',
        'Listing Error (Wrong price, details, or duplicate listing)'),
    ('Delivery Issue (Seller unable to deliver in requested location)',
        'Delivery Issue (Seller unable to deliver in requested location)'),
  ];

  String _verification = _verificationFailed.first;
  String _rejected = _planRejected.first;
  String _product = '';
  final _reasonCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await ref.read(sellerCustomOrdersRepositoryProvider).setCancelled(
            orderUuid: widget.orderUuid,
            customerVerificationFailed:
                _verification == 'N/A' ? null : _verification,
            installmentPlanRejected: _rejected == 'N/A' ? null : _rejected,
            productUnavailable: _product.isEmpty ? null : _product,
            reason: _reasonCtrl.text.trim().isEmpty
                ? null
                : _reasonCtrl.text.trim(),
          );
      if (!mounted) return;
      Navigator.pop(context);
      ref.invalidate(sellerCustomOrderDetailsProvider(widget.orderUuid));
      SnackbarService().showSuccessSnackBar('Order has been Cancelled.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      SnackbarService()
          .showErrorSnackBar(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = context.sellerText;
    return _SheetShell(
      title: 'Cancelled',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Customer verification failed', style: text.label),
          const Gap.v(AppSpace.xxs),
          _SheetDropdown<String>(
            value: _verification,
            enabled: !_saving,
            items: [
              for (final v in _verificationFailed) (v, v),
            ],
            onChanged: (v) => setState(() => _verification = v),
          ),
          const Gap.v(AppSpace.sm),
          Text('Installment plan rejected', style: text.label),
          const Gap.v(AppSpace.xxs),
          _SheetDropdown<String>(
            value: _rejected,
            enabled: !_saving,
            items: [
              for (final v in _planRejected) (v, v),
            ],
            onChanged: (v) => setState(() => _rejected = v),
          ),
          const Gap.v(AppSpace.sm),
          Text('Product unavailable', style: text.label),
          const Gap.v(AppSpace.xxs),
          _SheetDropdown<String>(
            value: _product,
            enabled: !_saving,
            items: _productUnavailable,
            onChanged: (v) => setState(() => _product = v),
          ),
          const Gap.v(AppSpace.sm),
          _SheetField(
            controller: _reasonCtrl,
            label: 'Other reason (optional)',
            enabled: !_saving,
            maxLines: 3,
          ),
          const Gap.v(AppSpace.md),
          SellerButton(
            label: 'Cancel Order',
            icon: Icons.cancel_outlined,
            variant: SellerButtonVariant.danger,
            loading: _saving,
            onPressed: _saving ? null : _submit,
          ),
        ],
      ),
    );
  }
}

// ── Pay Instalment ───────────────────────────────────────────────────────────
/// The server always settles the first `Unpaid` instalment of type
/// `Instalment`/`Outstanding` — [instalment] (from [_nextPayableInstalment])
/// is shown purely as context; its amount seeds the editable field.
class _PayInstalmentSheet extends ConsumerStatefulWidget {
  final String orderUuid;
  final int orderId;
  final SellerCustomOrderInstalment instalment;
  final List<SellerRecoveryMember> recoveryMembers;

  const _PayInstalmentSheet({
    required this.orderUuid,
    required this.orderId,
    required this.instalment,
    required this.recoveryMembers,
  });

  @override
  ConsumerState<_PayInstalmentSheet> createState() => _PayInstalmentSheetState();
}

class _PayInstalmentSheetState extends ConsumerState<_PayInstalmentSheet> {
  static const _methods = ['By Hand', 'JazzCash', 'Easypaisa', 'Bank'];

  late final TextEditingController _amountCtrl;
  String? _method;
  int? _recoveryMemberId;
  File? _receipt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: widget.instalment.instalmentPrice.toString(),
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickReceipt() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1400,
    );
    if (picked == null) return;
    setState(() => _receipt = File(picked.path));
  }

  Future<void> _submit() async {
    final amount = int.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (amount <= 0) {
      SnackbarService().showErrorSnackBar('Enter a valid instalment amount.');
      return;
    }
    if (_method == null) {
      SnackbarService().showErrorSnackBar('Please select a payment method.');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(sellerCustomOrdersRepositoryProvider).payInstalment(
            orderId: widget.orderId,
            instalmentPrice: amount.toString(),
            paymentMethod: _method!,
            recoveryMemberId: _recoveryMemberId?.toString(),
            receipt: _receipt,
          );
      if (!mounted) return;
      Navigator.pop(context, true);
      SnackbarService().showSuccessSnackBar('Instalment paid successfully.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      SnackbarService().showErrorSnackBar(_cleanError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final instalment = widget.instalment;

    return _SheetShell(
      title: 'Pay Instalment',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Context — which instalment this payment will settle.
          Container(
            padding: const EdgeInsets.all(AppSpace.sm),
            decoration: BoxDecoration(
              color: c.surfaceAlt,
              borderRadius: AppRadius.brSm,
              border: Border.all(color: c.border),
            ),
            child: Row(
              children: [
                SellerIconBadge(
                  icon: Icons.receipt_long_rounded,
                  tone: c.accentTone,
                  size: 38,
                  iconSize: 19,
                ),
                const Gap.h(AppSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${instalment.month} • ${instalment.type}',
                        style: text.bodyLg.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const Gap.v(2),
                      Text(
                        'Due ${instalment.formattedInstalmentPrice} on ${instalment.instalmentDate}',
                        style: text.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Gap.v(AppSpace.md),
          Text('Amount collected', style: text.label),
          const Gap.v(AppSpace.xs),
          _DecimalField(
            controller: _amountCtrl,
            label: 'Instalment amount',
            enabled: !_saving,
            decimal: false,
          ),
          const Gap.v(AppSpace.md),
          Text('Payment method', style: text.label),
          const Gap.v(AppSpace.xs),
          _MethodChips(
            methods: _methods,
            selected: _method,
            enabled: !_saving,
            onChanged: (m) => setState(() => _method = m),
          ),
          const Gap.v(AppSpace.md),
          Text('Recovery member (optional)', style: text.label),
          const Gap.v(AppSpace.xs),
          _RecoveryMemberDropdown(
            members: widget.recoveryMembers,
            value: _recoveryMemberId,
            enabled: !_saving,
            onChanged: (v) => setState(() => _recoveryMemberId = v),
          ),
          const Gap.v(AppSpace.md),
          Text('Receipt (optional)', style: text.label),
          const Gap.v(AppSpace.xs),
          _ReceiptPicker(
            receipt: _receipt,
            onPick: _saving ? () {} : _pickReceipt,
            onClear: () => setState(() => _receipt = null),
          ),
          const Gap.v(AppSpace.md),
          SellerButton(
            label: 'Confirm Payment',
            icon: Icons.payments_rounded,
            loading: _saving,
            onPressed: _saving ? null : _submit,
          ),
        ],
      ),
    );
  }
}

// ── Close Deal (early settlement) ────────────────────────────────────────────
class _CloseDealSheet extends ConsumerStatefulWidget {
  final String orderUuid;
  final SellerCustomOrderDetails details;

  const _CloseDealSheet({required this.orderUuid, required this.details});

  @override
  ConsumerState<_CloseDealSheet> createState() => _CloseDealSheetState();
}

class _CloseDealSheetState extends ConsumerState<_CloseDealSheet> {
  static const _methods = ['By Hand', 'JazzCash', 'Easypaisa', 'Bank'];

  late final TextEditingController _outstandingCtrl;
  late final TextEditingController _settlementCtrl;

  String? _method;
  int? _recoveryMemberId;
  File? _receipt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _outstandingCtrl = TextEditingController(
      text: widget.details.outstandingPrincipal.toString(),
    );
    _settlementCtrl = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _outstandingCtrl.dispose();
    _settlementCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickReceipt() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1400,
    );
    if (picked == null) return;
    setState(() => _receipt = File(picked.path));
  }

  Future<void> _submit() async {
    if (_method == null) {
      SnackbarService().showErrorSnackBar('Please select a payment method.');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(sellerCustomOrdersRepositoryProvider).closeCustomOrderDeal(
            orderUuid: widget.orderUuid,
            outstandingAmount: _outstandingCtrl.text.trim().isEmpty
                ? null
                : _outstandingCtrl.text.trim(),
            settlementAmount: _settlementCtrl.text.trim().isEmpty
                ? '0'
                : _settlementCtrl.text.trim(),
            paymentMethod: _method!,
            recoveryMemberId: _recoveryMemberId?.toString(),
            receipt: _receipt,
          );
      if (!mounted) return;
      Navigator.pop(context);
      ref.invalidate(sellerCustomOrderDetailsProvider(widget.orderUuid));
      SnackbarService().showSuccessSnackBar('Deal closed successfully.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      SnackbarService()
          .showErrorSnackBar(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = context.sellerText;
    final members = widget.details.recoveryMembers;
    return _SheetShell(
      title: 'Close Deal',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DecimalField(
            controller: _outstandingCtrl,
            label: 'Outstanding amount',
            enabled: !_saving,
            decimal: false,
          ),
          const Gap.v(AppSpace.sm),
          _DecimalField(
            controller: _settlementCtrl,
            label: 'Settlement amount',
            enabled: !_saving,
            decimal: false,
          ),
          const Gap.v(AppSpace.md),
          Text('Payment method', style: text.label),
          const Gap.v(AppSpace.xs),
          _MethodChips(
            methods: _methods,
            selected: _method,
            enabled: !_saving,
            onChanged: (m) => setState(() => _method = m),
          ),
          const Gap.v(AppSpace.md),
          Text('Recovery member (optional)', style: text.label),
          const Gap.v(AppSpace.xs),
          _RecoveryMemberDropdown(
            members: members,
            value: _recoveryMemberId,
            enabled: !_saving,
            onChanged: (v) => setState(() => _recoveryMemberId = v),
          ),
          const Gap.v(AppSpace.md),
          Text('Receipt (optional)', style: text.label),
          const Gap.v(AppSpace.xs),
          _ReceiptPicker(
            receipt: _receipt,
            onPick: _saving ? () {} : _pickReceipt,
            onClear: () => setState(() => _receipt = null),
          ),
          const Gap.v(AppSpace.md),
          SellerButton(
            label: 'Close Deal',
            icon: Icons.handshake_outlined,
            loading: _saving,
            onPressed: _saving ? null : _submit,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  SHARED SHEET WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

/// Pill chips for the payment method (By Hand / JazzCash / Easypaisa / Bank).
class _MethodChips extends StatelessWidget {
  final List<String> methods;
  final String? selected;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const _MethodChips({
    required this.methods,
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    return Wrap(
      spacing: AppSpace.xs,
      runSpacing: AppSpace.xs,
      children: methods.map((m) {
        final isSelected = m == selected;
        return GestureDetector(
          onTap: enabled ? () => onChanged(m) : null,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.md,
              vertical: AppSpace.xs + 2,
            ),
            decoration: BoxDecoration(
              color: isSelected ? c.accent : c.surface,
              borderRadius: AppRadius.brPill,
              border: Border.all(color: isSelected ? c.accent : c.border),
            ),
            child: Text(
              m,
              style: text.labelSm.copyWith(
                color: isSelected ? c.onAccent : c.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}

/// Segmented selector for small enumerations (received_by / house_type).
class _SegmentedField<T> extends StatefulWidget {
  final T? value;
  final bool enabled;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;

  const _SegmentedField({
    required this.value,
    required this.enabled,
    required this.options,
    required this.onChanged,
  });

  @override
  State<_SegmentedField<T>> createState() => _SegmentedFieldState<T>();
}

class _SegmentedFieldState<T> extends State<_SegmentedField<T>> {
  late T? _value = widget.value;

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    return Row(
      children: widget.options.asMap().entries.map((entry) {
        final option = entry.value;
        final isSelected = _value == option.$1;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: entry.key == widget.options.length - 1 ? 0 : AppSpace.xs,
            ),
            child: GestureDetector(
              onTap: widget.enabled
                  ? () {
                      setState(() => _value = option.$1);
                      widget.onChanged(option.$1);
                    }
                  : null,
              child: AnimatedContainer(
                duration: AppMotion.fast,
                padding: const EdgeInsets.symmetric(vertical: AppSpace.xs + 2),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? c.accentSurface : c.surface,
                  borderRadius: AppRadius.brSm,
                  border: Border.all(
                    color: isSelected ? c.accent : c.border,
                    width: isSelected ? 1.4 : 1,
                  ),
                ),
                child: Text(
                  option.$2,
                  textAlign: TextAlign.center,
                  style: text.labelSm.copyWith(
                    color: isSelected ? c.accent : c.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}

/// Themed dropdown used by the Cancelled reasons.
class _SheetDropdown<T> extends StatelessWidget {
  final T value;
  final bool enabled;
  final List<(T, String)> items;
  final ValueChanged<T> onChanged;

  const _SheetDropdown({
    required this.value,
    required this.enabled,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      style: text.bodySm.copyWith(color: c.textPrimary),
      dropdownColor: c.surface,
      decoration: _inputDecoration(context, ''),
      items: [
        for (final item in items)
          DropdownMenuItem(
            value: item.$1,
            child: Text(
              item.$2,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.bodySm.copyWith(color: c.textPrimary),
            ),
          ),
      ],
      onChanged: enabled
          ? (v) {
              if (v != null) onChanged(v);
            }
          : null,
    );
  }
}

/// Optional recovery-member dropdown (sends user_id as recovery_member_id).
class _RecoveryMemberDropdown extends StatelessWidget {
  final List<SellerRecoveryMember> members;
  final int? value;
  final bool enabled;
  final ValueChanged<int?> onChanged;

  const _RecoveryMemberDropdown({
    required this.members,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    return DropdownButtonFormField<int?>(
      initialValue: value,
      isExpanded: true,
      style: text.bodySm.copyWith(color: c.textPrimary),
      dropdownColor: c.surface,
      decoration: _inputDecoration(context, ''),
      hint: Text('Not assigned', style: text.bodySm),
      items: [
        DropdownMenuItem<int?>(
          value: null,
          child: Text('Not assigned', style: text.bodySm),
        ),
        for (final m in members)
          DropdownMenuItem<int?>(
            value: m.userId,
            child: Text(
              m.user.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodySm.copyWith(color: c.textPrimary),
            ),
          ),
      ],
      onChanged: enabled ? onChanged : null,
    );
  }
}

/// A number field that optionally accepts a single decimal point.
class _DecimalField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool enabled;
  final bool decimal;

  const _DecimalField({
    required this.controller,
    required this.label,
    required this.enabled,
    required this.decimal,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [
        decimal
            ? FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
            : FilteringTextInputFormatter.digitsOnly,
      ],
      style: text.body,
      cursorColor: c.accent,
      decoration: _inputDecoration(context, label),
    );
  }
}

/// CNIC mask: xxxxx-xxxxxxx-x.
class _CnicFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final trimmed = digits.length > 13 ? digits.substring(0, 13) : digits;
    final buffer = StringBuffer();
    for (var i = 0; i < trimmed.length; i++) {
      if (i == 5 || i == 12) buffer.write('-');
      buffer.write(trimmed[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Formats a numeric value as `Rs 1,234`.
String _money(num value) {
  final rounded = value.round();
  final negative = rounded < 0;
  final digits = rounded.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final remaining = digits.length - i;
    buffer.write(digits[i]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write(',');
  }
  return 'Rs ${negative ? '-' : ''}$buffer';
}

InputDecoration _inputDecoration(
  BuildContext context,
  String label, {
  String? hint,
}) {
  final c = context.sellerColors;
  final text = context.sellerText;
  return InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: text.bodySm,
    floatingLabelStyle: text.labelSm.copyWith(color: c.accent),
    hintStyle: text.bodySm.copyWith(color: c.textTertiary),
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
  );
}

/// A generic themed form field used across the detail sheets.
class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool enabled;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _SheetField({
    required this.controller,
    required this.label,
    this.hint,
    required this.enabled,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      validator: validator,
      style: text.body,
      cursorColor: c.accent,
      decoration: _inputDecoration(context, label, hint: hint),
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
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpace.sm,
        right: AppSpace.sm,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpace.sm,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.lg,
          AppSpace.md,
          AppSpace.lg,
          AppSpace.lg,
        ),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: AppRadius.brXl,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text(title, style: text.titleMd)),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: c.textSecondary),
                  ),
                ],
              ),
              const Gap.v(AppSpace.xs),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Image picker tile shared by the Delivered / Instalments / Close-Deal sheets.
class _ReceiptPicker extends StatelessWidget {
  final File? receipt;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _ReceiptPicker({
    required this.receipt,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;

    if (receipt != null) {
      return Row(
        children: [
          ClipRRect(
            borderRadius: AppRadius.brSm,
            child: Image.file(
              receipt!,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
          ),
          const Gap.h(AppSpace.sm),
          Expanded(
            child: Text(
              receipt!.path.split(Platform.pathSeparator).last,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodySm,
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, size: 18, color: c.textTertiary),
            onPressed: onClear,
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: onPick,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
        decoration: BoxDecoration(
          color: c.surfaceAlt,
          borderRadius: AppRadius.brMd,
          border: Border.all(color: c.border),
        ),
        child: Column(
          children: [
            Icon(Icons.add_photo_alternate_rounded, color: c.accent, size: 22),
            const Gap.v(AppSpace.xs - 2),
            Text(
              'Upload image',
              style: text.bodySm.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
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
    final c = context.sellerColors;
    final text = context.sellerText;
    return Container(
      padding: const EdgeInsets.all(AppSpace.xs + 2),
      decoration: BoxDecoration(
        color: c.dangerSurface,
        borderRadius: AppRadius.brSm,
        border: Border.all(color: c.dangerTone.border),
      ),
      child: Text(
        message,
        style: text.labelSm.copyWith(color: c.danger),
      ),
    );
  }
}
