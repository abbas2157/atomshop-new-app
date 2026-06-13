// ============================================================
//  seller_investments_screen.dart  —  Design System reskin
//
//  All business logic, providers, navigation and status-change
//  flow are 100% preserved.  Only presentation/styling has been
//  updated to the Seller Design System.
// ============================================================

import 'package:atompro/core/seller_plan_upgrade_exception.dart';
import 'package:atompro/core/services/snackbar_services.dart';
import 'package:atompro/features/seller/core/design/design.dart';
import 'package:atompro/features/seller/core/widgets/widgets.dart';
import 'package:atompro/features/seller/investments/model/seller_investment_model.dart';
import 'package:atompro/features/seller/investments/repository/seller_investments_repository.dart';
import 'package:atompro/features/seller/investments/viewmodel/seller_investments_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ═══════════════════════════════════════════════════════════
//  LIST SCREEN
// ═══════════════════════════════════════════════════════════

class SellerInvestmentsScreen extends ConsumerStatefulWidget {
  const SellerInvestmentsScreen({super.key});

  @override
  ConsumerState<SellerInvestmentsScreen> createState() =>
      _SellerInvestmentsScreenState();
}

class _SellerInvestmentsScreenState
    extends ConsumerState<SellerInvestmentsScreen> {
  int _page = 1;

  void _refresh() => ref.invalidate(sellerInvestmentsProvider(_page));

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final state = ref.watch(sellerInvestmentsProvider(_page));

    return Scaffold(
      backgroundColor: c.canvas,
      body: state.when(
        loading: () => Column(
          children: [
            SellerGradientHeader(
              leading: SellerIconBadge(
                icon: Icons.trending_up_rounded,
                tone: SellerTone(
                  fg: Colors.white,
                  bg: Colors.white.withValues(alpha: 0.18),
                  border: Colors.white.withValues(alpha: 0.25),
                ),
                size: 42,
                iconSize: 22,
                radius: AppRadius.md,
              ),
              title: 'Investments',
              actions: [
                SellerHeaderIconButton(
                  icon: Icons.refresh_rounded,
                  onTap: _refresh,
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const Expanded(child: SellerListSkeleton(count: 5)),
          ],
        ),
        error: (error, _) => SafeArea(
          child: Column(
            children: [
              SellerGradientHeader(
                leading: SellerIconBadge(
                  icon: Icons.trending_up_rounded,
                  tone: SellerTone(
                    fg: Colors.white,
                    bg: Colors.white.withValues(alpha: 0.18),
                    border: Colors.white.withValues(alpha: 0.25),
                  ),
                  size: 42,
                  iconSize: 22,
                  radius: AppRadius.md,
                ),
                title: 'Investments',
                actions: [
                  SellerHeaderIconButton(
                    icon: Icons.refresh_rounded,
                    onTap: _refresh,
                    tooltip: 'Refresh',
                  ),
                ],
              ),
              Expanded(
                child: error is SellerPlanUpgradeException
                    ? SellerPlanGateState(exception: error)
                    : SellerErrorState(
                        message: _cleanError(error),
                        onRetry: _refresh,
                      ),
              ),
            ],
          ),
        ),
        data: (data) => Column(
          children: [
            SellerGradientHeader(
              leading: SellerIconBadge(
                icon: Icons.trending_up_rounded,
                tone: SellerTone(
                  fg: Colors.white,
                  bg: Colors.white.withValues(alpha: 0.18),
                  border: Colors.white.withValues(alpha: 0.25),
                ),
                size: 42,
                iconSize: 22,
                radius: AppRadius.md,
              ),
              title: 'Investments',
              subtitle:
                  '${data.pagination.total} records · ${data.activeCount} active',
              actions: [
                SellerHeaderIconButton(
                  icon: Icons.refresh_rounded,
                  onTap: _refresh,
                  tooltip: 'Refresh',
                ),
              ],
              bottom: _HeaderKpis(data: data),
            ),
            Expanded(
              child: RefreshIndicator(
                color: c.accent,
                backgroundColor: c.surface,
                onRefresh: () async {
                  _refresh();
                  await ref.read(sellerInvestmentsProvider(_page).future);
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
                    const Gap.v(AppSpace.md),
                    if (data.investments.isEmpty)
                      const SellerEmptyState(
                        icon: Icons.trending_up_rounded,
                        title: 'No investments found',
                        message:
                            'No investment records are available right now.',
                      )
                    else
                      ...data.investments.map(
                        (investment) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpace.sm),
                          child: _InvestmentCard(
                            investment: investment,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    SellerInvestmentDetailsScreen(
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
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  DETAIL SCREEN
// ═══════════════════════════════════════════════════════════

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
    final confirmed = await _showStatusConfirmDialog(context, status);
    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      await ref
          .read(sellerInvestmentsRepositoryProvider)
          .updateStatus(
            investmentId: widget.investment.id,
            status: status,
          );
      ref.invalidate(
        sellerInvestmentDetailsProvider(widget.investment.id),
      );
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

    return SellerThemeScope(
      child: Builder(
        builder: (context) {
          final c = context.sellerColors;

          return Scaffold(
            backgroundColor: c.canvas,
            body: Column(
              children: [
                SellerGradientHeader(
                  leading: SellerMonogram(
                    name: widget.investment.investorName,
                    size: 42,
                  ),
                  title: widget.investment.investorName,
                  subtitle: widget.investment.formattedAmount,
                  actions: [
                    SellerStatusPill(
                      label: widget.investment.status,
                      dense: true,
                    ),
                    const Gap.h(AppSpace.xs),
                    SellerHeaderIconButton(
                      icon: Icons.refresh_rounded,
                      onTap: () => ref.invalidate(
                        sellerInvestmentDetailsProvider(
                          widget.investment.id,
                        ),
                      ),
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: c.accent,
                    backgroundColor: c.surface,
                    onRefresh: () async {
                      ref.invalidate(
                        sellerInvestmentDetailsProvider(
                          widget.investment.id,
                        ),
                      );
                      await ref.read(
                        sellerInvestmentDetailsProvider(
                          widget.investment.id,
                        ).future,
                      );
                    },
                    child: ListView(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: AppInsets.pageWithNav,
                      children: [
                        _InvestorHeroCard(
                          investment: widget.investment,
                        ),
                        const Gap.v(AppSpace.md),
                        state.when(
                          loading: () => const SellerListSkeleton(
                            count: 3,
                            itemHeight: 64,
                          ),
                          error: (error, _) => error is SellerPlanUpgradeException
                              ? SellerPlanGateState(exception: error)
                              : SellerErrorState(
                                  message: _cleanError(error),
                                  onRetry: () => ref.invalidate(
                                    sellerInvestmentDetailsProvider(
                                      widget.investment.id,
                                    ),
                                  ),
                                ),
                          data: (details) => Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.stretch,
                            children: [
                              _StatusActionsCard(
                                saving: _saving,
                                currentStatus:
                                    details.investment.status,
                                onSelect: _updateStatus,
                              ),
                              const Gap.v(AppSpace.md),
                              _DetailsCard(details: details),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  HEADER KPI STRIP  (inside gradient header bottom slot)
// ═══════════════════════════════════════════════════════════

class _HeaderKpis extends StatelessWidget {
  final SellerInvestmentsResponse data;
  const _HeaderKpis({required this.data});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _GradientStat(
          label: 'Total',
          value: data.formattedTotalAmount,
        ),
        _GradientDivider(),
        _GradientStat(
          label: 'Active',
          value: '${data.activeCount}',
        ),
        _GradientDivider(),
        _GradientStat(
          label: 'Records',
          value: '${data.pagination.total}',
        ),
      ],
    );
  }
}

class _GradientStat extends StatelessWidget {
  final String label;
  final String value;
  const _GradientStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const Gap.v(AppSpace.xxxs),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Roboto',
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: AppSpace.md),
      color: Colors.white.withValues(alpha: 0.2),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  INVESTMENT LIST CARD
// ═══════════════════════════════════════════════════════════

class _InvestmentCard extends StatelessWidget {
  final SellerInvestment investment;
  final VoidCallback onTap;

  const _InvestmentCard({required this.investment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final tone = SellerStatus.toneFor(investment.status, c);

    return SellerCard(
      onTap: onTap,
      accentEdge: tone.fg,
      padding: const EdgeInsets.all(AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── header row: avatar / name / date / status ─────
          Row(
            children: [
              SellerMonogram(name: investment.investorName, size: 40),
              const Gap.h(AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      investment.investorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleSm,
                    ),
                    const Gap.v(AppSpace.xxxs),
                    Text(
                      investment.formattedCreatedAt,
                      style: text.caption,
                    ),
                  ],
                ),
              ),
              const Gap.h(AppSpace.xs),
              SellerStatusPill(label: investment.status),
              const Gap.h(AppSpace.xs),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: c.textTertiary,
              ),
            ],
          ),
          const Gap.v(AppSpace.sm),
          Divider(color: c.divider, height: 1),
          const Gap.v(AppSpace.sm),
          // ── 3-metric row ──────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _MetricCell(
                  label: 'Amount',
                  value: investment.formattedAmount,
                  tone: c.accentTone,
                ),
              ),
              Container(width: 1, height: 34, color: c.divider),
              Expanded(
                child: _MetricCell(
                  label: 'Paid',
                  value: investment.formattedPaidAmount,
                  tone: c.successTone,
                ),
              ),
              Container(width: 1, height: 34, color: c.divider),
              Expanded(
                child: _MetricCell(
                  label: 'Profit',
                  value: investment.formattedProfitAmount,
                  tone: c.violetTone,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  final String label;
  final String value;
  final SellerTone tone;

  const _MetricCell({
    required this.label,
    required this.value,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final text = context.sellerText;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.overline),
          const Gap.v(AppSpace.xxxs),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.labelSm.copyWith(
              color: tone.fg,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  DETAIL SCREEN — INVESTOR HERO CARD
// ═══════════════════════════════════════════════════════════

class _InvestorHeroCard extends StatelessWidget {
  final SellerInvestment investment;
  const _InvestorHeroCard({required this.investment});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;

    return SellerCard(
      child: Column(
        children: [
          // ── avatar + name + phone + status ────────────────
          Row(
            children: [
              SellerIconBadge(
                icon: Icons.person_rounded,
                tone: c.accentTone,
                size: 48,
                iconSize: 24,
                radius: AppRadius.lg,
              ),
              const Gap.h(AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      investment.investorName,
                      style: text.titleMd,
                    ),
                    if (investment.investorPhone.isNotEmpty) ...[
                      const Gap.v(AppSpace.xxxs),
                      Text(
                        investment.investorPhone,
                        style: text.bodySm,
                      ),
                    ],
                  ],
                ),
              ),
              SellerStatusPill(label: investment.status),
            ],
          ),
          const Gap.v(AppSpace.md),
          Divider(color: c.divider, height: 1),
          const Gap.v(AppSpace.xs),
          // ── key financials ─────────────────────────────────
          SellerDataRow(
            label: 'Investment Amount',
            value: investment.formattedAmount,
            emphasize: true,
          ),
          SellerDataRow(
            label: 'Paid Amount',
            value: investment.formattedPaidAmount,
          ),
          SellerDataRow(
            label: 'Profit Amount',
            value: investment.formattedProfitAmount,
          ),
          if (investment.type.isNotEmpty)
            SellerDataRow(label: 'Type', value: investment.type),
          SellerDataRow(
            label: 'Created',
            value: investment.formattedCreatedAt,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  DETAIL SCREEN — STATUS ACTION CARD
// ═══════════════════════════════════════════════════════════

class _StatusActionsCard extends StatelessWidget {
  final bool saving;
  final String currentStatus;
  final ValueChanged<String> onSelect;

  const _StatusActionsCard({
    required this.saving,
    required this.currentStatus,
    required this.onSelect,
  });

  static const _statuses = ['active', 'pending', 'inactive'];

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;

    return SellerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SellerIconBadge(
                icon: Icons.swap_horiz_rounded,
                tone: c.accentTone,
                size: 36,
                iconSize: 18,
                radius: AppRadius.sm,
              ),
              const Gap.h(AppSpace.sm),
              Expanded(
                child: Text('Update Status', style: text.titleSm),
              ),
              if (saving)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: c.accent,
                  ),
                ),
            ],
          ),
          const Gap.v(AppSpace.sm),
          Divider(color: c.divider, height: 1),
          const Gap.v(AppSpace.sm),
          Wrap(
            spacing: AppSpace.xs,
            runSpacing: AppSpace.xs,
            children: _statuses.map((status) {
              final isSelected =
                  currentStatus.toLowerCase().trim() ==
                  status.toLowerCase();
              final tone = SellerStatus.toneFor(status, c);
              if (isSelected) {
                return SellerStatusPill(label: status, tone: tone);
              }
              return SellerButton(
                label: status,
                size: SellerButtonSize.small,
                expand: false,
                variant: SellerButtonVariant.secondary,
                onPressed: saving ? null : () => onSelect(status),
              );
            }).toList(growable: false),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  DETAIL SCREEN — FULL DETAILS CARD
// ═══════════════════════════════════════════════════════════

class _DetailsCard extends StatelessWidget {
  final SellerInvestmentDetails details;

  const _DetailsCard({required this.details});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final fields = details.fields.entries.toList(growable: false);

    return SellerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SellerIconBadge(
                icon: Icons.info_outline_rounded,
                tone: c.infoTone,
                size: 36,
                iconSize: 18,
                radius: AppRadius.sm,
              ),
              const Gap.h(AppSpace.sm),
              Expanded(
                child: Text('Investment Data', style: text.titleSm),
              ),
            ],
          ),
          const Gap.v(AppSpace.sm),
          Divider(color: c.divider, height: 1),
          const Gap.v(AppSpace.xs),
          if (fields.isEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: AppSpace.lg),
              child: Text(
                'No additional fields returned.',
                style: text.bodySm,
              ),
            )
          else
            ...fields.map(
              (entry) =>
                  SellerDataRow(label: entry.key, value: entry.value),
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
    final c = context.sellerColors;

    return SellerCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm,
      ),
      elevated: false,
      child: Row(
        children: [
          SellerIconBadge(
            icon: Icons.receipt_long_rounded,
            tone: c.neutralTone,
            size: 32,
            iconSize: 16,
            radius: AppRadius.sm,
          ),
          const Gap.h(AppSpace.sm),
          Expanded(
            child: Text('Investment Records', style: text.titleSm),
          ),
          Text(
            total == 0
                ? '0 records'
                : '${from ?? 0}–${to ?? 0} of $total',
            style: text.labelSm,
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

    final text = context.sellerText;
    final c = context.sellerColors;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.sm),
      child: Row(
        children: [
          Expanded(
            child: SellerButton.secondary(
              label: 'Previous',
              icon: Icons.chevron_left_rounded,
              size: SellerButtonSize.small,
              onPressed: onPrevious,
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpace.md),
            child: Text(
              '${pagination.currentPage} / ${pagination.lastPage}',
              style: text.labelSm.copyWith(color: c.textSecondary),
            ),
          ),
          Expanded(
            child: SellerButton.secondary(
              label: 'Next',
              trailingIcon: Icons.chevron_right_rounded,
              size: SellerButtonSize.small,
              onPressed: onNext,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  STATUS-CHANGE CONFIRM DIALOG
// ═══════════════════════════════════════════════════════════

Future<bool?> _showStatusConfirmDialog(
  BuildContext context,
  String status,
) {
  final isDark = context.sellerIsDark;
  return showDialog<bool>(
    context: context,
    builder: (_) => Theme(
      data: isDark ? SellerTheme.dark : SellerTheme.light,
      child: Builder(
        builder: (context) {
          final c = context.sellerColors;
          final text = context.sellerText;
          final tone = SellerStatus.toneFor(status, c);
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
                    icon: Icons.swap_horiz_rounded,
                    tone: tone,
                    size: 52,
                    iconSize: 26,
                    radius: AppRadius.lg,
                  ),
                  const Gap.v(AppSpace.md),
                  Text('Update Status', style: text.titleMd),
                  const Gap.v(AppSpace.xs),
                  Text(
                    'Change investment status to "$status"?',
                    textAlign: TextAlign.center,
                    style: text.bodySm,
                  ),
                  const Gap.v(AppSpace.lg),
                  Row(
                    children: [
                      Expanded(
                        child: SellerButton.secondary(
                          label: 'Cancel',
                          onPressed: () =>
                              Navigator.of(context).pop(false),
                        ),
                      ),
                      const Gap.h(AppSpace.sm),
                      Expanded(
                        child: SellerButton(
                          label: 'Update',
                          onPressed: () =>
                              Navigator.of(context).pop(true),
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
}

// ═══════════════════════════════════════════════════════════
//  UTILITIES
// ═══════════════════════════════════════════════════════════

String _cleanError(Object error) {
  final msg = error.toString().replaceFirst('Exception: ', '').trim();
  return msg.isEmpty ? 'Something went wrong. Please try again.' : msg;
}
