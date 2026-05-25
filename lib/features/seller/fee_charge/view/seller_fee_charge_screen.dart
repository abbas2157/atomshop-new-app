import 'package:atompro/core/services/snackbar_services.dart';
import 'package:atompro/features/seller/fee_charge/model/seller_fee_charge_model.dart';
import 'package:atompro/features/seller/fee_charge/repository/seller_fee_charge_repository.dart';
import 'package:atompro/features/seller/fee_charge/viewmodel/seller_fee_charge_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract final class _F {
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pay Fee Charge'),
        content: Text('Confirm payment for ${data.formattedOutstanding}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Pay'),
          ),
        ],
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
    final state = ref.watch(sellerFeeChargeProvider(_page));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _F.bg,
        appBar: AppBar(
          backgroundColor: _F.bg,
          surfaceTintColor: _F.bg,
          titleSpacing: 0,
          title: const Text(
            'Fee Charge',
            style: TextStyle(
              color: _F.text,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: () => ref.invalidate(sellerFeeChargeProvider(_page)),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: RefreshIndicator(
            color: _F.brand,
            onRefresh: () async {
              ref.invalidate(sellerFeeChargeProvider(_page));
              await ref.read(sellerFeeChargeProvider(_page).future);
            },
            child: ListView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
              children: [
                state.when(
                  loading: () => const _LoadingView(),
                  error: (error, _) => _ErrorCard(
                    message: _cleanError(error),
                    onRetry: () =>
                        ref.invalidate(sellerFeeChargeProvider(_page)),
                  ),
                  data: (data) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SummaryHeader(
                        data: data,
                        paying: _paying,
                        onPay: data.hasOutstanding ? () => _payFee(data) : null,
                      ),
                      const SizedBox(height: 12),
                      _RangeStrip(
                        total: data.pagination.total,
                        from: data.pagination.from,
                        to: data.pagination.to,
                      ),
                      const SizedBox(height: 12),
                      if (data.charges.isEmpty)
                        const _EmptyState()
                      else
                        ...data.charges.map(
                          (charge) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _FeeChargeCard(charge: charge),
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

class _SummaryHeader extends StatelessWidget {
  final SellerFeeChargeResponse data;
  final bool paying;
  final VoidCallback? onPay;

  const _SummaryHeader({
    required this.data,
    required this.paying,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_F.brandDark, _F.brand],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _F.brand.withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                  size: 27,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fee Charge',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Seller fee summary and payment',
                      style: TextStyle(
                        color: Color(0xFFDDE5FF),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            data.formattedOutstanding,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Outstanding balance',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.74),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  label: 'Grand Total',
                  value: data.formattedGrandTotal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryMetric(
                  label: 'Paid',
                  value: data.formattedTotalPaid,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: paying ? null : onPay,
              icon: paying
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.payments_outlined, size: 18),
              label: Text(
                data.hasOutstanding ? 'Pay Outstanding' : 'Fully Paid',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _F.brand,
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.45),
                disabledForegroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
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
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeeChargeCard extends StatelessWidget {
  final SellerFeeCharge charge;

  const _FeeChargeCard({required this.charge});

  @override
  Widget build(BuildContext context) {
    final colors = charge.paid
        ? (fg: _F.success, bg: _F.success.withValues(alpha: 0.12))
        : (fg: _F.warning, bg: _F.warning.withValues(alpha: 0.12));

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _F.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _F.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _F.brand.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.receipt_long_outlined, color: _F.brand),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      charge.type,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _F.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      charge.formattedCreatedAt,
                      style: const TextStyle(
                        color: _F.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(label: charge.status, fg: colors.fg, bg: colors.bg),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  label: 'Amount',
                  value: charge.formattedAmount,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniMetric(
                  label: 'Paid',
                  value: charge.formattedPaidAmount,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniMetric(
                  label: 'Pending',
                  value: charge.formattedPendingAmount,
                ),
              ),
            ],
          ),
          if (charge.note != 'Not available') ...[
            const SizedBox(height: 10),
            Text(
              charge.note,
              style: const TextStyle(
                color: _F.muted,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
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
        color: _F.surfaceAlt,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _F.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _F.muted,
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
              color: _F.text,
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
        color: _F.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _F.border),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Charge Records',
              style: TextStyle(
                color: _F.text,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            total == 0 ? '0 records' : '${from ?? 0}-${to ?? 0} of $total',
            style: const TextStyle(
              color: _F.muted,
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
              color: _F.muted,
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

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (_) => Container(
          height: 118,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _F.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _F.border),
          ),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
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
        color: _F.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _F.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: _F.danger),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _F.text, fontWeight: FontWeight.w700),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _F.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _F.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.receipt_long_outlined, color: _F.muted, size: 32),
          SizedBox(height: 10),
          Text(
            'No fee charge records found.',
            style: TextStyle(color: _F.text, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 5),
          Text(
            'The summary above is still returned by the seller API.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _F.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

String _cleanError(Object error) {
  final text = error.toString().replaceFirst('Exception: ', '').trim();
  return text.isEmpty ? 'Something went wrong. Please try again.' : text;
}
