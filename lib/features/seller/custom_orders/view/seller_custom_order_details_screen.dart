<<<<<<< HEAD
import 'dart:io';
=======
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
>>>>>>> main

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
import 'package:atompro/features/seller/instalments/repository/seller_instalments_repository.dart';
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
                onUpdateStatus: () => _showStatusSheet(
                  context: context,
                  ref: ref,
                  orderUuid: orderUuid,
                  currentStatus: details.order.status,
                  receivedBy: details.user.name,
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
<<<<<<< HEAD
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
              details: details,
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
                    details: details,
                  )
                : null,
            onAddGuarantor: (initial) => _showGuarantorSheet(
              context: context,
              ref: ref,
              orderUuid: orderUuid,
              initial: initial,
            ),
            onPayInstalment: (item) => _showPayInstalmentSheet(
              context: context,
              ref: ref,
              orderUuid: orderUuid,
              orderId: details.order.id,
              item: item,
              recoveryMembers: details.recoveryMembers,
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
=======
          );
        },
>>>>>>> main
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
  final void Function(SellerCustomOrderInstalment) onPayInstalment;

  const _DetailsContent({
    required this.details,
    required this.orderUuid,
    required this.guarantorState,
    required this.onUpdateStatus,
    required this.onCloseDeal,
    required this.onAddGuarantor,
    required this.onRefresh,
    required this.onPayInstalment,
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

  const _HeroCard({
    required this.order,
    required this.onUpdateStatus,
    required this.onCloseDeal,
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

  const _HeroActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: AppRadius.brMd,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brMd,
            border: Border.all(color: Colors.white.withValues(alpha: 0.34)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const Gap.h(AppSpace.xs),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: Colors.white,
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
  final void Function(SellerCustomOrderInstalment)? onPayInstalment;
  const _InstalmentsContent({required this.items, this.onPayInstalment});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    return Column(
      children: items.asMap().entries.map((e) {
        final isLast = e.key == items.length - 1;
        final item = e.value;
        final tone = item.isPaid ? c.successTone : c.warningTone;
        return Container(
          margin: EdgeInsets.only(bottom: isLast ? 0 : AppSpace.sm),
          padding: const EdgeInsets.all(AppSpace.sm),
          decoration: BoxDecoration(
            color: item.isPaid ? c.successSurface : c.surfaceAlt,
            borderRadius: AppRadius.brSm,
            border: Border.all(
              color: item.isPaid ? tone.border : c.border,
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
              if (!item.isPaid && onPayInstalment != null) ...[
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () => onPayInstalment!(item),
                  icon: const Icon(Icons.payment_rounded, size: 15),
                  label: const Text('Pay Instalment'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _D.brand,
                    minimumSize: const Size(double.infinity, 38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
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

// ═══════════════════════════════════════════════════════════════════════════
//  MODAL SHEETS (status / close-deal / guarantor)
// ═══════════════════════════════════════════════════════════════════════════
Future<void> _showStatusSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String orderUuid,
  required SellerCustomOrderDetails details,
}) async {
  final dark = context.sellerIsDark;
  final changed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
<<<<<<< HEAD
    builder: (_) => _StatusUpdateSheet(
      orderUuid: orderUuid,
      currentStatus: details.order.status,
      customerVerified: details.user.customer.verified,
      advancePrice: details.order.advancePrice,
      sourcingAgentFee: details.order.sourcingAgentFee,
      recoveryMembers: details.recoveryMembers,
=======
    builder: (_) => Theme(
      data: dark ? SellerTheme.dark : SellerTheme.light,
      child: _StatusUpdateSheet(
        orderUuid: orderUuid,
        currentStatus: currentStatus,
        receivedBy: receivedBy,
      ),
>>>>>>> main
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
  required SellerCustomOrderDetails details,
}) async {
  final dark = context.sellerIsDark;
  final changed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
<<<<<<< HEAD
    builder: (_) => _CloseDealSheet(
      orderUuid: orderUuid,
      outstandingPrincipal: details.outstandingPrincipal,
      recoveryMembers: details.recoveryMembers,
=======
    builder: (_) => Theme(
      data: dark ? SellerTheme.dark : SellerTheme.light,
      child: _CloseDealSheet(orderUuid: orderUuid, order: order),
>>>>>>> main
    ),
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

void _showPayInstalmentSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String orderUuid,
  required int orderId,
  required SellerCustomOrderInstalment item,
  required List<SellerRecoveryMember> recoveryMembers,
}) {
  showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PayInstalmentSheet(
      orderId: orderId,
      instalmentPrice: item.instalmentPrice,
      recoveryMembers: recoveryMembers,
      onSuccess: () {
        ref.invalidate(sellerCustomOrderDetailsProvider(orderUuid));
        SnackbarService().showSuccessSnackBar('Instalment payment recorded.');
      },
    ),
  );
}

class _PayInstalmentSheet extends ConsumerStatefulWidget {
  final int orderId;
  final int instalmentPrice;
  final List<SellerRecoveryMember> recoveryMembers;
  final VoidCallback onSuccess;

  const _PayInstalmentSheet({
    required this.orderId,
    required this.instalmentPrice,
    required this.recoveryMembers,
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
  int? _recoveryMemberId;
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
            recoveryMemberId: _recoveryMemberId,
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
    final members = widget.recoveryMembers;
    return _SheetShell(
      title: 'Pay Instalment',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _amountCtrl,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration:
                  const InputDecoration(labelText: 'Instalment Amount *'),
              validator: (v) {
                final n = int.tryParse(v?.trim() ?? '');
                if (n == null || n <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _method,
              decoration:
                  const InputDecoration(labelText: 'Payment Method *'),
              items: _kPaymentMethods
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged:
                  _saving ? null : (v) {
                    if (v != null) setState(() => _method = v);
                  },
            ),
            if (members.isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _recoveryMemberId,
                decoration: const InputDecoration(
                    labelText: 'Recovery Member (Optional)'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  ...members.map((m) => DropdownMenuItem(
                        value: m.user.id,
                        child: Text(m.user.name),
                      )),
                ],
                onChanged: _saving
                    ? null
                    : (v) => setState(() => _recoveryMemberId = v),
              ),
            ],
            const SizedBox(height: 12),
            _ImagePickerTile(
              label: 'Receipt Photo (Optional)',
              file: _receipt,
              onPick: () async {
                final f = await ImagePicker().pickImage(
                    source: ImageSource.gallery, imageQuality: 80);
                if (f != null) setState(() => _receipt = f);
              },
              onClear: () => setState(() => _receipt = null),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              _SheetError(message: _error!),
            ],
            const SizedBox(height: 18),
            _SheetButton(
              label: 'Submit Payment',
              icon: Icons.payment_rounded,
              loading: _saving,
              onTap: _submit,
            ),
          ],
        ),
      ),
    );
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

// ── Status flow ───────────────────────────────────────────────────────────────
List<String> _nextStatuses(String current) {
  final s = current.toLowerCase();
  if (s.contains('pending')) return ['Varification', 'Cancelled'];
  if (s.contains('varif')) return ['Processing', 'Cancelled'];
  if (s.contains('process')) return ['Delivered', 'Cancelled'];
  if (s.contains('deliver')) return ['Instalments', 'Cancelled'];
  if (s.contains('instalment')) return ['Completed', 'Cancelled'];
  return ['Varification', 'Processing', 'Delivered', 'Instalments', 'Completed', 'Cancelled'];
}

const _kPaymentMethods = ['By Hand', 'JazzCash', 'Easypaisa', 'Bank'];

const _kCustVerFailedOptions = [
  'N/A',
  'Invalid Contact Details (Wrong/Unreachable phone number)',
  'Incorrect Customer Information (Mismatch in name, CNIC, or address)',
  'Unresponsive Customer (No answer to calls/messages)',
  'Suspicious/Fraudulent Activity (Fake documents or identity concerns)',
];

const _kPlanRejectedOptions = [
  'N/A',
  'Credit Criteria Not Met (Low score or insufficient income)',
  'Required Documents Missing/Invalid (ID, salary slip, bank statement, etc.)',
  'Poor Payment History (Previous defaults on installments)',
  'High Financial Risk Detected (Red flags from verification team)',
];

const _kProductUnavailableOptions = [
  '',
  'Out of Stock (Product no longer available)',
  'Discontinued by Seller (No longer being sold)',
  'Listing Error (Wrong price, details, or duplicate listing)',
  'Delivery Issue (Seller unable to deliver in requested location)',
];

// ── Status update sheet ───────────────────────────────────────────────────────
class _StatusUpdateSheet extends ConsumerStatefulWidget {
  final String orderUuid;
  final String currentStatus;
  final bool customerVerified;
  final int advancePrice;
  final int sourcingAgentFee;
  final List<SellerRecoveryMember> recoveryMembers;

  const _StatusUpdateSheet({
    required this.orderUuid,
    required this.currentStatus,
    required this.customerVerified,
    required this.advancePrice,
    required this.sourcingAgentFee,
    required this.recoveryMembers,
  });

  @override
  ConsumerState<_StatusUpdateSheet> createState() => _StatusUpdateSheetState();
}

class _StatusUpdateSheetState extends ConsumerState<_StatusUpdateSheet> {
  final _formKey = GlobalKey<FormState>();
  late List<String> _statusOptions;
  late String _status;
  bool _saving = false;
  String? _error;

  // Varification
  final _commentCtrl = TextEditingController();

  // Processing – guarantors
  bool _addGuarantors = false;
  bool _add2ndGuarantor = false;
  final _g1Name = TextEditingController();
  final _g1FatherName = TextEditingController();
  final _g1Cnic = TextEditingController();
  final _g1Profession = TextEditingController();
  final _g1Relation = TextEditingController();
  final _g1ResAddress = TextEditingController();
  final _g1OfficeAddress = TextEditingController();
  final _g1ResTel = TextEditingController();
  final _g1OfficeTel = TextEditingController();
  String _g1HouseType = 'owned';
  final _g2Name = TextEditingController();
  final _g2FatherName = TextEditingController();
  final _g2Cnic = TextEditingController();
  final _g2Profession = TextEditingController();
  final _g2Relation = TextEditingController();
  final _g2ResAddress = TextEditingController();
  final _g2OfficeAddress = TextEditingController();
  final _g2ResTel = TextEditingController();
  final _g2OfficeTel = TextEditingController();
  String _g2HouseType = 'owned';

  // Delivered
  String _recievedBy = 'By Himself';
  XFile? _deliveredPicture;

  // Instalments
  late final TextEditingController _advancePriceCtrl;
  late final TextEditingController _sourcingFeeCtrl;
  String _perMonthPct = '4.0';
  String _instalmentTenure = '12';
  String _instalmentPaymentMethod = 'By Hand';
  int _dayOfMonth = 5;
  int? _instalmentRecoveryMemberId;
  XFile? _instalmentPicture;

  // Cancelled
  String _custVerFailed = 'N/A';
  String _planRejected = 'N/A';
  String _productUnavailable = '';
  final _cancelReasonCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _statusOptions = _nextStatuses(widget.currentStatus);
    _status = _statusOptions.first;
    _advancePriceCtrl = TextEditingController(
      text: widget.advancePrice > 0 ? widget.advancePrice.toString() : '',
    );
    _sourcingFeeCtrl = TextEditingController(
      text: widget.sourcingAgentFee >= 0 ? widget.sourcingAgentFee.toString() : '',
    );
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    for (final c in [
      _g1Name, _g1FatherName, _g1Cnic, _g1Profession, _g1Relation,
      _g1ResAddress, _g1OfficeAddress, _g1ResTel, _g1OfficeTel,
      _g2Name, _g2FatherName, _g2Cnic, _g2Profession, _g2Relation,
      _g2ResAddress, _g2OfficeAddress, _g2ResTel, _g2OfficeTel,
      _advancePriceCtrl, _sourcingFeeCtrl, _cancelReasonCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  bool get _blocked => !widget.customerVerified && _status != 'Cancelled';

  Future<void> _submit() async {
    if (_blocked) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _saving = true; _error = null; });

    try {
      final body = <String, dynamic>{'status': _status};
      final files = <String, File>{};

      switch (_status) {
        case 'Varification':
          body['comment'] = _commentCtrl.text.trim();
        case 'Processing':
          if (_addGuarantors) {
            final list = [
              _buildGuarantorMap(
                _g1Name, _g1FatherName, _g1Cnic, _g1Profession, _g1Relation,
                _g1ResAddress, _g1OfficeAddress, _g1ResTel, _g1OfficeTel, _g1HouseType,
              ),
              if (_add2ndGuarantor)
                _buildGuarantorMap(
                  _g2Name, _g2FatherName, _g2Cnic, _g2Profession, _g2Relation,
                  _g2ResAddress, _g2OfficeAddress, _g2ResTel, _g2OfficeTel, _g2HouseType,
                ),
            ];
            body['guarantor'] = list;
          }
        case 'Delivered':
          body['recieved_by'] = _recievedBy;
          if (_deliveredPicture != null) files['delivered_pictrue'] = File(_deliveredPicture!.path);
        case 'Instalments':
          body['advance_price'] = _advancePriceCtrl.text.trim();
          body['per_month_percentage'] = _perMonthPct;
          body['sourcing_agent_fee'] = _sourcingFeeCtrl.text.trim();
          body['installment_tenure'] = int.parse(_instalmentTenure);
          body['payment_method'] = _instalmentPaymentMethod;
          body['day_of_month'] = _dayOfMonth;
          if (_instalmentRecoveryMemberId != null) body['recovery_member_id'] = _instalmentRecoveryMemberId;
          if (_instalmentPicture != null) files['instalment_pictrue'] = File(_instalmentPicture!.path);
        case 'Cancelled':
          body['customer_verification_failed'] = _custVerFailed;
          body['installment_plan_rejected'] = _planRejected;
          body['product_unavailable'] = _productUnavailable;
          final r = _cancelReasonCtrl.text.trim();
          if (r.isNotEmpty) body['reason'] = r;
        default:
          break;
      }

      await ref.read(sellerCustomOrdersRepositoryProvider).updateCustomOrderStatus(
        orderUuid: widget.orderUuid,
        body: body,
        files: files,
      );
      if (!mounted) return;
      SnackbarService().showSuccessSnackBar('Order status updated.');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _cleanError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Map<String, dynamic> _buildGuarantorMap(
    TextEditingController name, TextEditingController fatherName,
    TextEditingController cnic, TextEditingController profession,
    TextEditingController relation, TextEditingController resAddress,
    TextEditingController officeAddress, TextEditingController resTel,
    TextEditingController officeTel, String houseType,
  ) {
    String t(TextEditingController c) => c.text.trim();
    return {
      if (t(name).isNotEmpty) 'name': t(name),
      if (t(fatherName).isNotEmpty) 'father_name': t(fatherName),
      if (t(cnic).isNotEmpty) 'cnic': t(cnic),
      if (t(profession).isNotEmpty) 'profession': t(profession),
      if (t(relation).isNotEmpty) 'relation': t(relation),
      if (t(resAddress).isNotEmpty) 'res_address': t(resAddress),
      if (t(officeAddress).isNotEmpty) 'office_address': t(officeAddress),
      if (t(resTel).isNotEmpty) 'res_tel': t(resTel),
      if (t(officeTel).isNotEmpty) 'office_tel': t(officeTel),
      'house_type': houseType,
    };
  }

  @override
  Widget build(BuildContext context) {
    final text = context.sellerText;
    return _SheetShell(
      title: 'Update Order Status',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
<<<<<<< HEAD
              value: _status,
              decoration: const InputDecoration(labelText: 'New Status'),
=======
              initialValue: _status,
              style: text.body,
              decoration: _inputDecoration(context, 'Status'),
>>>>>>> main
              items: [
                for (final s in _statusOptions)
                  DropdownMenuItem(value: s, child: Text(s)),
              ],
              onChanged: _saving
                  ? null
                  : (v) { if (v != null) setState(() => _status = v); },
            ),
<<<<<<< HEAD
            if (_blocked) ...[
              const SizedBox(height: 10),
              _WarningBanner(
                message: 'This customer is not verified. Verify them first to proceed. Only Cancelled is allowed without verification.',
              ),
            ],
            if (!_blocked) ...[
              if (_status == 'Varification') ..._varificationFields(),
              if (_status == 'Processing') ..._processingFields(),
              if (_status == 'Delivered') ..._deliveredFields(),
              if (_status == 'Instalments') ..._instalmentsFields(),
              if (_status == 'Cancelled') ..._cancelledFields(),
              if (_status == 'Completed') ..._completedNote(),
            ],
=======
            const Gap.v(AppSpace.sm),
            _SheetField(
              controller: _receivedByCtrl,
              label: 'Received / handled by',
              hint: 'Customer or receiver name',
              enabled: !_saving,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Receiver name is required.';
                }
                return null;
              },
            ),
>>>>>>> main
            if (_error != null) ...[
              const Gap.v(AppSpace.sm),
              _SheetError(message: _error!),
            ],
            const Gap.v(AppSpace.md),
            SellerButton(
              label: 'Save Status',
              icon: Icons.save_outlined,
              loading: _saving,
<<<<<<< HEAD
              onTap: _blocked ? () {} : _submit,
=======
              onPressed: _saving ? null : _submit,
>>>>>>> main
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _varificationFields() => [
    const SizedBox(height: 12),
    TextFormField(
      controller: _commentCtrl,
      enabled: !_saving,
      maxLines: 3,
      decoration: const InputDecoration(labelText: 'Verification Notes *'),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'Comment is required.' : null,
    ),
  ];

  List<Widget> _processingFields() => [
    const SizedBox(height: 10),
    Row(
      children: [
        Checkbox(
          value: _addGuarantors,
          activeColor: _D.brand,
          onChanged: _saving ? null : (v) => setState(() => _addGuarantors = v ?? false),
        ),
        const Text(
          'Add Guarantors (Optional)',
          style: TextStyle(color: _D.txt1, fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ],
    ),
    if (_addGuarantors) ...[
      _GuarantorFormSection(
        label: 'Guarantor 1',
        saving: _saving,
        name: _g1Name, fatherName: _g1FatherName, cnic: _g1Cnic,
        profession: _g1Profession, relation: _g1Relation,
        resAddress: _g1ResAddress, officeAddress: _g1OfficeAddress,
        resTel: _g1ResTel, officeTel: _g1OfficeTel,
        houseType: _g1HouseType,
        onHouseTypeChanged: (v) => setState(() => _g1HouseType = v),
      ),
      const SizedBox(height: 8),
      if (!_add2ndGuarantor)
        OutlinedButton.icon(
          onPressed: _saving ? null : () => setState(() => _add2ndGuarantor = true),
          icon: const Icon(Icons.person_add_outlined, size: 15),
          label: const Text('Add 2nd Guarantor'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _D.brand,
            side: const BorderSide(color: _D.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        )
      else ...[
        const SizedBox(height: 4),
        _GuarantorFormSection(
          label: 'Guarantor 2',
          saving: _saving,
          name: _g2Name, fatherName: _g2FatherName, cnic: _g2Cnic,
          profession: _g2Profession, relation: _g2Relation,
          resAddress: _g2ResAddress, officeAddress: _g2OfficeAddress,
          resTel: _g2ResTel, officeTel: _g2OfficeTel,
          houseType: _g2HouseType,
          onHouseTypeChanged: (v) => setState(() => _g2HouseType = v),
        ),
      ],
    ],
  ];

  List<Widget> _deliveredFields() => [
    const SizedBox(height: 12),
    DropdownButtonFormField<String>(
      value: _recievedBy,
      decoration: const InputDecoration(labelText: 'Received By *'),
      items: const [
        DropdownMenuItem(value: 'By Himself', child: Text('By Himself')),
        DropdownMenuItem(value: 'By Someone else', child: Text('By Someone else')),
      ],
      onChanged: _saving ? null : (v) { if (v != null) setState(() => _recievedBy = v); },
    ),
    const SizedBox(height: 12),
    _ImagePickerTile(
      label: 'Delivery Photo (Optional)',
      file: _deliveredPicture,
      onPick: () async {
        final f = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
        if (f != null) setState(() => _deliveredPicture = f);
      },
      onClear: () => setState(() => _deliveredPicture = null),
    ),
  ];

  List<Widget> _instalmentsFields() {
    final pctOptions = [for (var i = 0; i <= 60; i++) (i / 10).toStringAsFixed(1)];
    final tenureOptions = [for (var t = 3; t <= 24; t++) '$t'];
    final dayOptions = [for (var d = 1; d <= 31; d++) d];
    return [
      const SizedBox(height: 12),
      TextFormField(
        controller: _advancePriceCtrl,
        enabled: !_saving,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(labelText: 'Advance Price *'),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required.' : null,
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        value: _perMonthPct,
        decoration: const InputDecoration(labelText: 'Per Month % *'),
        items: pctOptions
            .map((p) => DropdownMenuItem(value: p, child: Text('$p%')))
            .toList(),
        onChanged: _saving ? null : (v) { if (v != null) setState(() => _perMonthPct = v); },
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _sourcingFeeCtrl,
        enabled: !_saving,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(labelText: 'Sourcing Agent Fee *'),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required.' : null,
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        value: _instalmentTenure,
        decoration: const InputDecoration(labelText: 'Installment Tenure *'),
        items: tenureOptions
            .map((t) => DropdownMenuItem(value: t, child: Text('$t months')))
            .toList(),
        onChanged: _saving ? null : (v) { if (v != null) setState(() => _instalmentTenure = v); },
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        value: _instalmentPaymentMethod,
        decoration: const InputDecoration(labelText: 'Payment Method *'),
        items: _kPaymentMethods
            .map((m) => DropdownMenuItem(value: m, child: Text(m)))
            .toList(),
        onChanged: _saving ? null : (v) { if (v != null) setState(() => _instalmentPaymentMethod = v); },
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<int>(
        value: _dayOfMonth,
        decoration: const InputDecoration(labelText: 'Monthly Due Day'),
        items: dayOptions
            .map((d) => DropdownMenuItem(value: d, child: Text('$d')))
            .toList(),
        onChanged: _saving ? null : (v) { if (v != null) setState(() => _dayOfMonth = v); },
      ),
      if (widget.recoveryMembers.isNotEmpty) ...[
        const SizedBox(height: 12),
        DropdownButtonFormField<int?>(
          value: _instalmentRecoveryMemberId,
          decoration: const InputDecoration(labelText: 'Recovery Member (Optional)'),
          items: [
            const DropdownMenuItem(value: null, child: Text('None')),
            for (final m in widget.recoveryMembers)
              DropdownMenuItem(value: m.user.id, child: Text(m.user.name)),
          ],
          onChanged: _saving ? null : (v) => setState(() => _instalmentRecoveryMemberId = v),
        ),
      ],
      const SizedBox(height: 12),
      _ImagePickerTile(
        label: 'Receipt Photo (Optional)',
        file: _instalmentPicture,
        onPick: () async {
          final f = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
          if (f != null) setState(() => _instalmentPicture = f);
        },
        onClear: () => setState(() => _instalmentPicture = null),
      ),
    ];
  }

  List<Widget> _cancelledFields() => [
    const SizedBox(height: 12),
    DropdownButtonFormField<String>(
      value: _custVerFailed,
      decoration: const InputDecoration(labelText: 'Customer Verification Issue'),
      items: _kCustVerFailedOptions
          .map((o) => DropdownMenuItem(value: o, child: Text(o, overflow: TextOverflow.ellipsis)))
          .toList(),
      onChanged: _saving ? null : (v) { if (v != null) setState(() => _custVerFailed = v); },
    ),
    const SizedBox(height: 12),
    DropdownButtonFormField<String>(
      value: _planRejected,
      decoration: const InputDecoration(labelText: 'Installment Plan Issue'),
      items: _kPlanRejectedOptions
          .map((o) => DropdownMenuItem(value: o, child: Text(o, overflow: TextOverflow.ellipsis)))
          .toList(),
      onChanged: _saving ? null : (v) { if (v != null) setState(() => _planRejected = v); },
    ),
    const SizedBox(height: 12),
    DropdownButtonFormField<String>(
      value: _productUnavailable,
      decoration: const InputDecoration(labelText: 'Product Unavailability'),
      items: _kProductUnavailableOptions
          .map((o) => DropdownMenuItem(value: o, child: Text(o.isEmpty ? 'N/A' : o, overflow: TextOverflow.ellipsis)))
          .toList(),
      onChanged: _saving ? null : (v) { if (v != null) setState(() => _productUnavailable = v); },
    ),
    const SizedBox(height: 12),
    TextFormField(
      controller: _cancelReasonCtrl,
      enabled: !_saving,
      maxLines: 2,
      decoration: const InputDecoration(labelText: 'Additional Reason (Optional)'),
    ),
  ];

  List<Widget> _completedNote() => [
    const SizedBox(height: 10),
    Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _D.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _D.success.withValues(alpha: 0.25)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, color: _D.success, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'All installments must be Paid before the order can be Completed. The server will validate this.',
              style: TextStyle(
                color: _D.success, fontSize: 12,
                fontWeight: FontWeight.w700, height: 1.4,
              ),
            ),
          ),
        ],
      ),
    ),
  ];
}

// ── Close Deal sheet ──────────────────────────────────────────────────────────
class _CloseDealSheet extends ConsumerStatefulWidget {
  final String orderUuid;
  final int outstandingPrincipal;
  final List<SellerRecoveryMember> recoveryMembers;

  const _CloseDealSheet({
    required this.orderUuid,
    required this.outstandingPrincipal,
    required this.recoveryMembers,
  });

  @override
  ConsumerState<_CloseDealSheet> createState() => _CloseDealSheetState();
}

class _CloseDealSheetState extends ConsumerState<_CloseDealSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _outstandingCtrl;
  final _settlementCtrl = TextEditingController(text: '0');
  String _paymentMethod = 'By Hand';
  int? _recoveryMemberId;
  XFile? _receipt;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _outstandingCtrl = TextEditingController(
      text: widget.outstandingPrincipal > 0 ? widget.outstandingPrincipal.toString() : '',
    );
  }

  @override
  void dispose() {
    _outstandingCtrl.dispose();
    _settlementCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _saving = true; _error = null; });

    try {
      await ref.read(sellerCustomOrdersRepositoryProvider).closeCustomOrderDeal(
        orderUuid: widget.orderUuid,
        paymentMethod: _paymentMethod,
        outstandingAmount: int.tryParse(_outstandingCtrl.text.trim()),
        settlementAmount: int.tryParse(_settlementCtrl.text.trim()),
        recoveryMemberId: _recoveryMemberId,
        receipt: _receipt != null ? File(_receipt!.path) : null,
      );
      if (!mounted) return;
      SnackbarService().showSuccessSnackBar('Deal closed successfully.');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _cleanError(e));
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _outstandingCtrl,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Outstanding Amount (Optional)'),
            ),
<<<<<<< HEAD
            const SizedBox(height: 12),
            TextFormField(
              controller: _settlementCtrl,
=======
            const Gap.v(AppSpace.sm),
            _NumberField(
              controller: _advanceCtrl,
              label: 'Advance price',
>>>>>>> main
              enabled: !_saving,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Settlement / Waiver Amount'),
            ),
<<<<<<< HEAD
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _paymentMethod,
              decoration: const InputDecoration(labelText: 'Payment Method *'),
              items: _kPaymentMethods
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: _saving ? null : (v) { if (v != null) setState(() => _paymentMethod = v); },
            ),
            if (widget.recoveryMembers.isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                value: _recoveryMemberId,
                decoration: const InputDecoration(labelText: 'Recovery Member (Optional)'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  for (final m in widget.recoveryMembers)
                    DropdownMenuItem(value: m.user.id, child: Text(m.user.name)),
                ],
                onChanged: _saving ? null : (v) => setState(() => _recoveryMemberId = v),
              ),
            ],
            const SizedBox(height: 12),
            _ImagePickerTile(
              label: 'Receipt Photo (Optional)',
              file: _receipt,
              onPick: () async {
                final f = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
                if (f != null) setState(() => _receipt = f);
              },
              onClear: () => setState(() => _receipt = null),
=======
            const Gap.v(AppSpace.sm),
            _NumberField(
              controller: _tenureCtrl,
              label: 'Installment tenure',
              enabled: !_saving,
            ),
            const Gap.v(AppSpace.sm),
            _NumberField(
              controller: _percentageCtrl,
              label: 'Per month percentage',
              enabled: !_saving,
>>>>>>> main
            ),
            if (_error != null) ...[
              const Gap.v(AppSpace.sm),
              _SheetError(message: _error!),
            ],
            const Gap.v(AppSpace.md),
            SellerButton(
              label: 'Close Deal',
              icon: Icons.handshake_outlined,
              loading: _saving,
              onPressed: _saving ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

<<<<<<< HEAD
// ── Shared helper widgets ─────────────────────────────────────────────────────
class _WarningBanner extends StatelessWidget {
  final String message;
  const _WarningBanner({required this.message});
=======
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
  final String? Function(String?)? validator;

  const _SheetField({
    required this.controller,
    required this.label,
    this.hint,
    required this.enabled,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
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
      validator: validator,
      style: text.body,
      cursorColor: c.accent,
      decoration: _inputDecoration(context, label, hint: hint),
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool enabled;
>>>>>>> main

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _D.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _D.warning.withValues(alpha: 0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: _D.warning, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: _D.txt1, fontSize: 12,
                fontWeight: FontWeight.w600, height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePickerTile extends StatelessWidget {
  final String label;
  final XFile? file;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _ImagePickerTile({
    required this.label,
    required this.file,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(color: _D.txt3, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        if (file == null)
          OutlinedButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.photo_library_outlined, size: 16),
            label: const Text('Select Photo'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _D.brand,
              side: const BorderSide(color: _D.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          )
        else
          Row(
            children: [
              const Icon(Icons.check_circle, color: _D.success, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  file!.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _D.txt2, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded, color: _D.danger, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
      ],
    );
  }
}

class _GuarantorFormSection extends StatelessWidget {
  final String label;
  final bool saving;
  final TextEditingController name, fatherName, cnic, profession, relation,
      resAddress, officeAddress, resTel, officeTel;
  final String houseType;
  final ValueChanged<String> onHouseTypeChanged;

  const _GuarantorFormSection({
    required this.label,
    required this.saving,
    required this.name,
    required this.fatherName,
    required this.cnic,
    required this.profession,
    required this.relation,
    required this.resAddress,
    required this.officeAddress,
    required this.resTel,
    required this.officeTel,
    required this.houseType,
    required this.onHouseTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _D.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _D.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _D.txt1, fontSize: 13, fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          _tf(name, 'Name', saving),
          const SizedBox(height: 10),
          _tf(fatherName, "Father's Name", saving),
          const SizedBox(height: 10),
          _tf(cnic, 'CNIC (xxxxx-xxxxxxx-x)', saving),
          const SizedBox(height: 10),
          _tf(profession, 'Profession', saving),
          const SizedBox(height: 10),
          _tf(relation, 'Relation to Customer', saving),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: houseType,
            decoration: const InputDecoration(labelText: 'House Type'),
            items: const [
              DropdownMenuItem(value: 'owned', child: Text('Owned')),
              DropdownMenuItem(value: 'rented', child: Text('Rented')),
              DropdownMenuItem(value: 'family', child: Text('Family')),
            ],
            onChanged: saving ? null : (v) { if (v != null) onHouseTypeChanged(v); },
          ),
          const SizedBox(height: 10),
          _tf(resAddress, 'Residential Address', saving),
          const SizedBox(height: 10),
          _tf(officeAddress, 'Office Address', saving),
          const SizedBox(height: 10),
          _tf(resTel, 'Residential Phone', saving, type: TextInputType.phone),
          const SizedBox(height: 10),
          _tf(officeTel, 'Office Phone', saving, type: TextInputType.phone),
        ],
      ),
    );
  }

  static Widget _tf(
    TextEditingController ctrl,
    String lbl,
    bool saving, {
    TextInputType type = TextInputType.text,
  }) {
    return TextFormField(
      controller: ctrl,
      enabled: !saving,
      keyboardType: type,
      decoration: InputDecoration(labelText: lbl),
=======
    final c = context.sellerColors;
    final text = context.sellerText;
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: text.body,
      cursorColor: c.accent,
      decoration: _inputDecoration(context, label),
      validator: (value) {
        final number = int.tryParse(value?.trim() ?? '');
        if (number == null || number <= 0) return '$label is required.';
        return null;
      },
>>>>>>> main
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
