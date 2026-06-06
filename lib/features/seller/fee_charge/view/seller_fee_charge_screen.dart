// ============================================================
//  seller_fee_charge_screen.dart  —  Design System v2
//
//  Reskinned on the Seller Design System: unified tokens,
//  colour extension (light + dark), shared component library.
//  Business logic, data model, pay-fee flow and pagination
//  are 100% preserved.
// ============================================================

import 'package:atompro/core/services/snackbar_services.dart';
import 'package:atompro/features/seller/core/design/design.dart';
import 'package:atompro/features/seller/core/widgets/widgets.dart';
import 'package:atompro/features/seller/fee_charge/model/seller_fee_charge_model.dart';
import 'package:atompro/features/seller/fee_charge/repository/seller_fee_charge_repository.dart';
import 'package:atompro/features/seller/fee_charge/viewmodel/seller_fee_charge_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SellerFeeChargeScreen extends ConsumerStatefulWidget {
  const SellerFeeChargeScreen({super.key});

  @override
  ConsumerState<SellerFeeChargeScreen> createState() =>
      _SellerFeeChargeScreenState();
}

class _SellerFeeChargeScreenState extends ConsumerState<SellerFeeChargeScreen> {
  int _page = 1;
  bool _paying = false;

  Future<void> _payFee(SellerFeeChargeResponse data) async {
    final dark = context.sellerIsDark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Theme(
        data: dark ? SellerTheme.dark : SellerTheme.light,
        child: Builder(
          builder: (context) {
            final c = context.sellerColors;
            final text = context.sellerText;
            return Dialog(
              backgroundColor: c.surface,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.brXl,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SellerIconBadge(
                      icon: Icons.payments_rounded,
                      tone: c.accentTone,
                      size: 52,
                      iconSize: 26,
                      radius: AppRadius.lg,
                    ),
                    const Gap.v(AppSpace.md),
                    Text('Pay Fee Charge', style: text.titleMd),
                    const Gap.v(AppSpace.xs),
                    Text(
                      'Confirm payment for ${data.formattedOutstanding}?',
                      textAlign: TextAlign.center,
                      style: text.bodySm,
                    ),
                    const Gap.v(AppSpace.lg),
                    Row(
                      children: [
                        Expanded(
                          child: SellerButton.secondary(
                            label: 'Cancel',
                            onPressed: () => Navigator.pop(context, false),
                          ),
                        ),
                        const Gap.h(AppSpace.sm),
                        Expanded(
                          child: SellerButton(
                            label: 'Pay',
                            icon: Icons.payments_rounded,
                            onPressed: () => Navigator.pop(context, true),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
    if (confirmed != true) return;

    setState(() => _paying = true);
    try {
      await ref.read(sellerFeeChargeRepositoryProvider).payFeeCharge();
      ref.invalidate(sellerFeeChargeProvider(_page));
      SnackbarService().showSuccessSnackBar('Fee charge payment submitted.');
    } catch (e) {
      SnackbarService().showErrorSnackBar(_cleanError(e));
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final state = ref.watch(sellerFeeChargeProvider(_page));

    return Scaffold(
      backgroundColor: c.canvas,
      body: state.when(
        loading: () => _FeeChargeSkeleton(c: c),
        error: (error, _) => SafeArea(
          child: Column(
            children: [
              SellerGradientHeader(
                leading: SellerIconBadge(
                  icon: Icons.account_balance_wallet_outlined,
                  tone: c.accentTone,
                  size: 42,
                  iconSize: 22,
                ),
                title: 'Fee Charge',
                subtitle: 'Seller fee summary and payment',
                actions: [
                  SellerHeaderIconButton(
                    icon: Icons.refresh_rounded,
                    onTap: () => ref.invalidate(sellerFeeChargeProvider(_page)),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
              Expanded(
                child: SellerErrorState(
                  message: _cleanError(error),
                  onRetry: () => ref.invalidate(sellerFeeChargeProvider(_page)),
                ),
              ),
            ],
          ),
        ),
        data: (data) => Column(
          children: [
            _FeeChargeHeader(
              data: data,
              paying: _paying,
              onPay: data.hasOutstanding ? () => _payFee(data) : null,
              onRefresh: () => ref.invalidate(sellerFeeChargeProvider(_page)),
            ),
            Expanded(
              child: RefreshIndicator(
                color: c.accent,
                backgroundColor: c.surface,
                onRefresh: () async {
                  ref.invalidate(sellerFeeChargeProvider(_page));
                  await ref.read(sellerFeeChargeProvider(_page).future);
                },
                child: ListView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: AppInsets.pageWithNav,
                  children: [
                    _RangeStrip(
                      total: data.pagination.total,
                      from: data.pagination.from,
                      to: data.pagination.to,
                    ),
                    const Gap.v(AppSpace.sm),
                    if (data.charges.isEmpty)
                      SellerEmptyState(
                        icon: Icons.receipt_long_rounded,
                        title: 'No fee charge records',
                        message:
                            'The summary above is still returned by the seller API.',
                      )
                    else
                      ...data.charges.map(
                        (charge) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpace.sm),
                          child: _FeeChargeCard(charge: charge),
                        ),
                      ),
                    if (data.pagination.lastPage > 1) ...[
                      const Gap.v(AppSpace.xs),
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  HEADER — gradient with outstanding amount in bottom slot
// ═══════════════════════════════════════════════════════════
class _FeeChargeHeader extends StatelessWidget {
  final SellerFeeChargeResponse data;
  final bool paying;
  final VoidCallback? onPay;
  final VoidCallback onRefresh;

  const _FeeChargeHeader({
    required this.data,
    required this.paying,
    required this.onPay,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;

    return SellerGradientHeader(
      leading: SellerIconBadge(
        icon: Icons.account_balance_wallet_outlined,
        tone: c.accentTone,
        size: 42,
        iconSize: 22,
      ),
      title: 'Fee Charge',
      subtitle: 'Seller fee summary and payment',
      actions: [
        SellerHeaderIconButton(
          icon: Icons.refresh_rounded,
          onTap: onRefresh,
          tooltip: 'Refresh',
        ),
      ],
      bottom: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Outstanding hero amount
          Text(
            data.formattedOutstanding,
            style: TextStyle(
              fontFamily: 'Roboto',
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const Gap.v(AppSpace.xxs),
          Text(
            'Outstanding balance',
            style: TextStyle(
              fontFamily: 'Roboto',
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap.v(AppSpace.md),
          // Grand Total / Paid mini-metrics row
          Row(
            children: [
              Expanded(
                child: _HeaderMetricBox(
                  label: 'Grand Total',
                  value: data.formattedGrandTotal,
                ),
              ),
              const Gap.h(AppSpace.sm),
              Expanded(
                child: _HeaderMetricBox(
                  label: 'Paid',
                  value: data.formattedTotalPaid,
                ),
              ),
            ],
          ),
          const Gap.v(AppSpace.md),
          // Pay button
          SellerButton(
            label: data.hasOutstanding ? 'Pay Outstanding' : 'Fully Paid',
            icon: paying ? null : Icons.payments_outlined,
            loading: paying,
            onPressed: paying ? null : onPay,
            variant: SellerButtonVariant.secondary,
          ),
        ],
      ),
    );
  }
}

/// A frosted metric box rendered inside the gradient header.
class _HeaderMetricBox extends StatelessWidget {
  final String label;
  final String value;

  const _HeaderMetricBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.sm,
        vertical: AppSpace.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: AppRadius.brMd,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Roboto',
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap.v(AppSpace.xxs),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  RANGE STRIP
// ═══════════════════════════════════════════════════════════
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
    final text = context.sellerText;

    return SellerCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm,
      ),
      child: Row(
        children: [
          SellerIconBadge(
            icon: Icons.receipt_long_rounded,
            tone: context.sellerColors.infoTone,
            size: 32,
            iconSize: 16,
          ),
          const Gap.h(AppSpace.sm),
          Expanded(
            child: Text('Charge Records', style: text.titleSm),
          ),
          Text(
            total == 0 ? '0 records' : '${from ?? 0}–${to ?? 0} of $total',
            style: text.labelSm,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  FEE CHARGE CARD
// ═══════════════════════════════════════════════════════════
class _FeeChargeCard extends StatelessWidget {
  final SellerFeeCharge charge;

  const _FeeChargeCard({required this.charge});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final tone = charge.paid ? c.successTone : c.warningTone;

    return SellerCard(
      accentEdge: tone.fg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              SellerIconBadge(
                icon: Icons.receipt_long_rounded,
                tone: c.accentTone,
                size: 42,
                iconSize: 21,
              ),
              const Gap.h(AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      charge.type,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleSm,
                    ),
                    const Gap.v(AppSpace.xxs),
                    Text(
                      charge.formattedCreatedAt,
                      style: text.caption,
                    ),
                  ],
                ),
              ),
              const Gap.h(AppSpace.xs),
              SellerStatusPill(label: charge.status, tone: tone),
            ],
          ),
          const Gap.v(AppSpace.sm),
          Divider(color: c.divider, height: 1),
          const Gap.v(AppSpace.sm),
          // Amount / Paid / Pending row
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  label: 'Amount',
                  value: charge.formattedAmount,
                ),
              ),
              const Gap.h(AppSpace.xs),
              Expanded(
                child: _MiniMetric(
                  label: 'Paid',
                  value: charge.formattedPaidAmount,
                ),
              ),
              const Gap.h(AppSpace.xs),
              Expanded(
                child: _MiniMetric(
                  label: 'Pending',
                  value: charge.formattedPendingAmount,
                ),
              ),
            ],
          ),
          if (charge.note != 'Not available') ...[
            const Gap.v(AppSpace.sm),
            Text(charge.note, style: text.bodySm),
          ],
        ],
      ),
    );
  }
}

/// A compact metric cell used inside the fee charge card.
class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;

  const _MiniMetric({required this.label, required this.value});

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
        border: Border.all(color: c.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.caption),
          const Gap.v(AppSpace.xxs),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.labelSm.copyWith(color: c.textPrimary),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  PAGINATION BAR
// ═══════════════════════════════════════════════════════════
class _PaginationBar extends StatelessWidget {
  final SellerFeeChargePagination pagination;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const _PaginationBar({
    required this.pagination,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final text = context.sellerText;

    return Row(
      children: [
        Expanded(
          child: SellerButton.secondary(
            label: 'Previous',
            icon: Icons.chevron_left_rounded,
            onPressed: onPrevious,
            size: SellerButtonSize.small,
          ),
        ),
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpace.sm),
          child: Text(
            '${pagination.currentPage} / ${pagination.lastPage}',
            style: text.labelSm,
          ),
        ),
        Expanded(
          child: SellerButton.secondary(
            label: 'Next',
            trailingIcon: Icons.chevron_right_rounded,
            onPressed: onNext,
            size: SellerButtonSize.small,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  LOADING SKELETON
// ═══════════════════════════════════════════════════════════
class _FeeChargeSkeleton extends StatelessWidget {
  final SellerColors c;
  const _FeeChargeSkeleton({required this.c});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Gradient header placeholder
        Container(
          height: 260,
          decoration: BoxDecoration(
            gradient: c.headerGradient,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(AppRadius.xxl),
            ),
          ),
        ),
        const Gap.v(AppSpace.md),
        Expanded(
          child: SellerShimmer(
            child: SellerListSkeleton(count: 4, itemHeight: 130),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  HELPERS
// ═══════════════════════════════════════════════════════════
String _cleanError(Object error) {
  final msg = error.toString().replaceFirst('Exception: ', '').trim();
  return msg.isEmpty ? 'Something went wrong. Please try again.' : msg;
}
