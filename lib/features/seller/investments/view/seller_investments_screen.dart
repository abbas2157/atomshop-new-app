import 'package:atompro/core/services/snackbar_services.dart';
import 'package:atompro/features/seller/investments/model/seller_investment_model.dart';
import 'package:atompro/features/seller/investments/repository/seller_investments_repository.dart';
import 'package:atompro/features/seller/investments/viewmodel/seller_investments_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract final class _I {
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

class SellerInvestmentsScreen extends ConsumerStatefulWidget {
  const SellerInvestmentsScreen({super.key});

  @override
  ConsumerState<SellerInvestmentsScreen> createState() =>
      _SellerInvestmentsScreenState();
}

class _SellerInvestmentsScreenState
    extends ConsumerState<SellerInvestmentsScreen> {
  int _page = 1;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sellerInvestmentsProvider(_page));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _I.bg,
        appBar: AppBar(
          backgroundColor: _I.bg,
          surfaceTintColor: _I.bg,
          titleSpacing: 0,
          title: const Text(
            'Investments',
            style: TextStyle(
              color: _I.text,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: () => ref.invalidate(sellerInvestmentsProvider(_page)),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: RefreshIndicator(
            color: _I.brand,
            onRefresh: () async {
              ref.invalidate(sellerInvestmentsProvider(_page));
              await ref.read(sellerInvestmentsProvider(_page).future);
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
                        ref.invalidate(sellerInvestmentsProvider(_page)),
                  ),
                  data: (data) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SummaryHeader(data: data),
                      const SizedBox(height: 12),
                      _RangeStrip(
                        total: data.pagination.total,
                        from: data.pagination.from,
                        to: data.pagination.to,
                      ),
                      const SizedBox(height: 12),
                      if (data.investments.isEmpty)
                        const _EmptyState()
                      else
                        ...data.investments.map(
                          (investment) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _InvestmentCard(
                              investment: investment,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SellerInvestmentDetailsScreen(
                                    investment: investment,
                                  ),
                                ),
                              ),
                            ),
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

class SellerInvestmentDetailsScreen extends ConsumerStatefulWidget {
  final SellerInvestment investment;

  const SellerInvestmentDetailsScreen({super.key, required this.investment});

  @override
  ConsumerState<SellerInvestmentDetailsScreen> createState() =>
      _SellerInvestmentDetailsScreenState();
}

class _SellerInvestmentDetailsScreenState
    extends ConsumerState<SellerInvestmentDetailsScreen> {
  bool _saving = false;

  Future<void> _updateStatus(String status) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Status'),
        content: Text('Change investment status to "$status"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Update'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      await ref
          .read(sellerInvestmentsRepositoryProvider)
          .updateStatus(investmentId: widget.investment.id, status: status);
      ref.invalidate(sellerInvestmentDetailsProvider(widget.investment.id));
      SnackbarService().showSuccessSnackBar('Investment status updated.');
    } catch (e) {
      SnackbarService().showErrorSnackBar(_cleanError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      sellerInvestmentDetailsProvider(widget.investment.id),
    );

    return Scaffold(
      backgroundColor: _I.bg,
      appBar: AppBar(
        backgroundColor: _I.bg,
        surfaceTintColor: _I.bg,
        title: const Text('Investment Details'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: _I.brand,
          onRefresh: () async {
            ref.invalidate(
              sellerInvestmentDetailsProvider(widget.investment.id),
            );
            await ref.read(
              sellerInvestmentDetailsProvider(widget.investment.id).future,
            );
          },
          child: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
            children: [
              _InvestmentHero(investment: widget.investment),
              const SizedBox(height: 12),
              state.when(
                loading: () => const _SectionLoading(),
                error: (error, _) => _ErrorCard(
                  message: _cleanError(error),
                  onRetry: () => ref.invalidate(
                    sellerInvestmentDetailsProvider(widget.investment.id),
                  ),
                ),
                data: (details) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StatusActions(
                      saving: _saving,
                      currentStatus: details.investment.status,
                      onSelect: _updateStatus,
                    ),
                    const SizedBox(height: 12),
                    _DetailsCard(details: details),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  final SellerInvestmentsResponse data;

  const _SummaryHeader({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_I.brandDark, _I.brand],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _I.brand.withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: const Icon(Icons.trending_up_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Investments',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${data.pagination.total} records - ${data.activeCount} active',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  data.formattedTotalAmount,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InvestmentCard extends StatelessWidget {
  final SellerInvestment investment;
  final VoidCallback onTap;

  const _InvestmentCard({required this.investment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = _statusColors(investment.status);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: _I.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _I.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 23,
                  backgroundColor: _I.brand.withValues(alpha: 0.1),
                  child: Text(
                    _initials(investment.investorName),
                    style: const TextStyle(
                      color: _I.brand,
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
                        investment.investorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _I.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        investment.formattedCreatedAt,
                        style: const TextStyle(
                          color: _I.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusPill(
                  label: investment.status,
                  fg: colors.fg,
                  bg: colors.bg,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MiniMetric(
                    label: 'Amount',
                    value: investment.formattedAmount,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniMetric(
                    label: 'Paid',
                    value: investment.formattedPaidAmount,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniMetric(
                    label: 'Profit',
                    value: investment.formattedProfitAmount,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InvestmentHero extends StatelessWidget {
  final SellerInvestment investment;

  const _InvestmentHero({required this.investment});

  @override
  Widget build(BuildContext context) {
    final colors = _statusColors(investment.status);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _I.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _I.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 27,
            backgroundColor: _I.brand.withValues(alpha: 0.1),
            child: Text(
              _initials(investment.investorName),
              style: const TextStyle(
                color: _I.brand,
                fontSize: 17,
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
                  investment.investorName,
                  style: const TextStyle(
                    color: _I.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  investment.formattedAmount,
                  style: const TextStyle(
                    color: _I.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          _StatusPill(label: investment.status, fg: colors.fg, bg: colors.bg),
        ],
      ),
    );
  }
}

class _StatusActions extends StatelessWidget {
  final bool saving;
  final String currentStatus;
  final ValueChanged<String> onSelect;

  const _StatusActions({
    required this.saving,
    required this.currentStatus,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    const statuses = ['active', 'pending', 'inactive'];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _I.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _I.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Update Status',
            style: TextStyle(
              color: _I.text,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: statuses
                .map((status) {
                  final selected =
                      currentStatus.toLowerCase().trim() ==
                      status.toLowerCase();
                  return ChoiceChip(
                    selected: selected,
                    label: Text(status),
                    onSelected: saving || selected
                        ? null
                        : (_) => onSelect(status),
                  );
                })
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final SellerInvestmentDetails details;

  const _DetailsCard({required this.details});

  @override
  Widget build(BuildContext context) {
    final fields = details.fields.entries.toList(growable: false);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _I.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _I.border),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: _I.brand, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Investment Data',
                  style: TextStyle(
                    color: _I.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (fields.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Text(
                'No additional fields returned.',
                style: TextStyle(color: _I.muted, fontWeight: FontWeight.w700),
              ),
            )
          else
            ...fields.map(
              (entry) => _InfoRow(label: entry.key, value: entry.value),
            ),
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
        color: _I.surfaceAlt,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _I.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _I.muted,
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
              color: _I.text,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F2F8))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: const TextStyle(
                color: _I.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: _I.text,
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
        color: _I.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _I.border),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Investment Records',
              style: TextStyle(
                color: _I.text,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            total == 0 ? '0 records' : '${from ?? 0}-${to ?? 0} of $total',
            style: const TextStyle(
              color: _I.muted,
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
  final SellerInvestmentsPagination pagination;
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
              color: _I.muted,
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
          height: 120,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _I.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _I.border),
          ),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
    );
  }
}

class _SectionLoading extends StatelessWidget {
  const _SectionLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(color: _I.brand),
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
        color: _I.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _I.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: _I.danger),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _I.text, fontWeight: FontWeight.w700),
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
        color: _I.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _I.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.trending_up_rounded, color: _I.muted, size: 32),
          SizedBox(height: 10),
          Text(
            'No investments found.',
            style: TextStyle(color: _I.text, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

({Color fg, Color bg}) _statusColors(String status) {
  final normalized = status.toLowerCase();
  if (normalized == 'active' ||
      normalized == 'paid' ||
      normalized == 'approved') {
    return (fg: _I.success, bg: _I.success.withValues(alpha: 0.12));
  }
  if (normalized == 'inactive' ||
      normalized == 'rejected' ||
      normalized == 'cancelled') {
    return (fg: _I.danger, bg: _I.danger.withValues(alpha: 0.12));
  }
  return (fg: _I.warning, bg: _I.warning.withValues(alpha: 0.12));
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return 'I';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first.substring(0, 1)}${parts[1].substring(0, 1)}'
      .toUpperCase();
}

String _cleanError(Object error) {
  final text = error.toString().replaceFirst('Exception: ', '').trim();
  return text.isEmpty ? 'Something went wrong. Please try again.' : text;
}
