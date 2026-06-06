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
              child: _InstalmentsContent(items: details.instalments),
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
  const _InstalmentsContent({required this.items});

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
  required String currentStatus,
  required String receivedBy,
}) async {
  final dark = context.sellerIsDark;
  final changed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Theme(
      data: dark ? SellerTheme.dark : SellerTheme.light,
      child: _StatusUpdateSheet(
        orderUuid: orderUuid,
        currentStatus: currentStatus,
        receivedBy: receivedBy,
      ),
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
  final dark = context.sellerIsDark;
  final changed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Theme(
      data: dark ? SellerTheme.dark : SellerTheme.light,
      child: _CloseDealSheet(orderUuid: orderUuid, order: order),
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
    final text = context.sellerText;
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
              style: text.body,
              decoration: _inputDecoration(context, 'Status'),
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
            if (_error != null) ...[
              const Gap.v(AppSpace.sm),
              _SheetError(message: _error!),
            ],
            const Gap.v(AppSpace.md),
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
            const Gap.v(AppSpace.sm),
            _NumberField(
              controller: _advanceCtrl,
              label: 'Advance price',
              enabled: !_saving,
            ),
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

  const _NumberField({
    required this.controller,
    required this.label,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
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
