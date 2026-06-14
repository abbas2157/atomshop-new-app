import 'package:atompro/features/seller/core/design/design.dart';
import 'package:atompro/features/seller/core/widgets/widgets.dart';
import 'package:atompro/features/seller/reports/model/seller_reports_model.dart';
import 'package:atompro/features/seller/reports/viewmodel/seller_reports_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SellerRecoverySheetScreen extends ConsumerStatefulWidget {
  const SellerRecoverySheetScreen({super.key});

  @override
  ConsumerState<SellerRecoverySheetScreen> createState() =>
      _SellerRecoverySheetScreenState();
}

class _SellerRecoverySheetScreenState
    extends ConsumerState<SellerRecoverySheetScreen> {
  String _status = 'active';
  final _searchCtrl = TextEditingController();
  String _q = '';
  bool _generated = false;

  static const _statusOptions = ['active', 'overdue', 'completed', 'all'];

  RecoverySheetQuery get _query =>
      RecoverySheetQuery(status: _status, q: _q);

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;

    return Scaffold(
      backgroundColor: c.canvas,
      body: Column(
        children: [
          SellerGradientHeader(
            leading: const _Glyph(icon: Icons.shield_outlined),
            title: 'Recovery Sheet',
            subtitle: 'Instalment plan recovery',
            actions: const [SellerNotificationBell(), SellerHeaderProfileButton()],
          ),
          Expanded(
            child: ListView(
              padding: AppInsets.pageWithNav,
              children: [
                // ── Filters ──────────────────────────────────────────────
                SellerCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status', style: text.caption),
                      const Gap.v(AppSpace.xs),
                      _StatusChips(
                        options: _statusOptions,
                        selected: _status,
                        onSelect: (v) => setState(() {
                          _status = v;
                          _generated = false;
                        }),
                      ),
                      const Gap.v(AppSpace.sm),
                      SellerSearchField(
                        controller: _searchCtrl,
                        hint: 'Customer name or phone…',
                        onChanged: (v) => setState(() {
                          _q = v;
                          _generated = false;
                        }),
                      ),
                      const Gap.v(AppSpace.sm),
                      SellerButton(
                        label: 'Generate',
                        icon: Icons.play_arrow_rounded,
                        onPressed: () {
                          ref.invalidate(sellerRecoverySheetProvider(_query));
                          setState(() => _generated = true);
                        },
                      ),
                    ],
                  ),
                ),
                // ── Results ───────────────────────────────────────────────
                if (_generated) ...[
                  const Gap.v(AppSpace.md),
                  ref.watch(sellerRecoverySheetProvider(_query)).when(
                    loading: () => const SellerListSkeleton(),
                    error: (e, _) => SellerErrorState(
                      message: e.toString().replaceFirst('Exception: ', ''),
                      onRetry: () {
                        ref.invalidate(sellerRecoverySheetProvider(_query));
                      },
                    ),
                    data: (data) {
                      if (data.rows.isEmpty) {
                        return const SellerEmptyState(
                          icon: Icons.shield_outlined,
                          title: 'No records found',
                          message: 'Try changing the status filter.',
                        );
                      }
                      final t = data.totals;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Totals strip
                          SellerGrid(
                            children: [
                              SellerKpiCard(
                                label: 'Total',
                                value: t.formattedTotal,
                                icon: Icons.payments_rounded,
                                tone: c.infoTone,
                                caption: '${t.count} orders',
                              ),
                              SellerKpiCard(
                                label: 'Paid',
                                value: t.formattedPaid,
                                icon: Icons.savings_rounded,
                                tone: c.successTone,
                              ),
                              SellerKpiCard(
                                label: 'Remaining',
                                value: t.formattedRemaining,
                                icon: Icons.account_balance_wallet_rounded,
                                tone: c.warningTone,
                              ),
                              SellerKpiCard(
                                label: 'Overdue',
                                value: t.formattedOverdue,
                                icon: Icons.warning_amber_rounded,
                                tone: c.warningTone,
                              ),
                            ],
                          ),
                          const Gap.v(AppSpace.md),
                          const SellerSectionHeader(title: 'Orders'),
                          const Gap.v(AppSpace.sm),
                          ...data.rows.map((row) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpace.sm),
                            child: _RecoveryRowCard(row: row),
                          )),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecoveryRowCard extends StatelessWidget {
  final RecoverySheetRow row;
  const _RecoveryRowCard({required this.row});

  SellerTone _statusTone(String status, SellerColors c) {
    switch (status.toLowerCase()) {
      case 'on-time':   return c.successTone;
      case 'completed': return c.successTone;
      case 'overdue':   return c.warningTone;
      default:          return c.warningTone;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final paidFraction = row.totalAmount > 0
        ? (row.amountPaid / row.totalAmount).clamp(0.0, 1.0)
        : 0.0;

    return SellerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(row.orderNo,
                    style: text.titleSm.copyWith(fontWeight: FontWeight.w700)),
              ),
              SellerStatusPill(
                label: row.recoveryStatus,
                tone: _statusTone(row.recoveryStatus, c),
              ),
            ],
          ),
          const Gap.v(AppSpace.xs),
          Text('${row.customerName} · ${row.customerPhone}',
              style: text.bodySm),
          const Gap.v(AppSpace.xxs),
          Text(row.productTitle,
              style: text.bodySm.copyWith(color: c.textSecondary)),
          const Gap.v(AppSpace.sm),
          SellerProgressBar(value: paidFraction, color: c.success),
          const Gap.v(AppSpace.xs),
          Row(
            children: [
              _Amount('Total', row.formattedTotalAmount, c.textPrimary, text),
              _Amount('Paid', row.formattedAmountPaid, c.success, text),
              _Amount('Remaining', row.formattedAmountRemaining, c.warning, text),
            ],
          ),
          if (row.overdueAmount > 0) ...[
            const Gap.v(AppSpace.xs),
            Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 13, color: c.warning),
                const Gap.h(AppSpace.xxs),
                Expanded(
                  child: Text(
                    'Overdue: ${row.formattedOverdueAmount}',
                    style: text.caption.copyWith(color: c.warning),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Gap.h(AppSpace.xs),
                Flexible(
                  child: Text(
                    'Next: ${row.nextDueDate} · ${row.formattedNextDueAmount}',
                    style: text.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Amount extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final SellerTextTheme text;

  const _Amount(this.label, this.value, this.color, this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.caption),
          Text(value,
              style: text.labelSm.copyWith(
                  color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _StatusChips extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;

  const _StatusChips({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    return Wrap(
      spacing: AppSpace.xs,
      children: options.map((opt) {
        final active = opt == selected;
        return GestureDetector(
          onTap: () => onSelect(opt),
          child: AnimatedContainer(
            duration: AppMotion.base,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.sm, vertical: AppSpace.xs),
            decoration: BoxDecoration(
              color: active ? c.accent : c.canvas,
              borderRadius: AppRadius.brPill,
              border: Border.all(color: active ? c.accent : c.border),
            ),
            child: Text(
              opt[0].toUpperCase() + opt.substring(1),
              style: text.caption.copyWith(
                color: active ? c.onAccent : c.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Glyph extends StatelessWidget {
  final IconData icon;
  const _Glyph({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42, height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: AppRadius.brMd,
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}
