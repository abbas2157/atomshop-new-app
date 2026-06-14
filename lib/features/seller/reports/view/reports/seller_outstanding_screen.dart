import 'package:atompro/features/seller/core/design/design.dart';
import 'package:atompro/features/seller/core/widgets/widgets.dart';
import 'package:atompro/features/seller/reports/model/seller_reports_model.dart';
import 'package:atompro/features/seller/reports/viewmodel/seller_reports_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SellerOutstandingScreen extends ConsumerWidget {
  const SellerOutstandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.sellerColors;
    final state = ref.watch(sellerOutstandingProvider);

    return Scaffold(
      backgroundColor: c.canvas,
      body: Column(
        children: [
          SellerGradientHeader(
            leading: const _Glyph(icon: Icons.account_balance_wallet_outlined),
            title: 'Customer Outstanding',
            subtitle: 'Active order balances',
            actions: const [SellerNotificationBell(), SellerHeaderProfileButton()],
          ),
          Expanded(
            child: state.when(
              loading: () => const SellerListSkeleton(),
              error: (e, _) => SellerErrorState(
                message: e.toString().replaceFirst('Exception: ', ''),
                onRetry: () => ref.invalidate(sellerOutstandingProvider),
              ),
              data: (g) {
                if (g.isGated) {
                  return SellerPlanGateState(exception: g.gate!);
                }
                final data = g.value!;
                return RefreshIndicator(
                color: c.accent,
                backgroundColor: c.surface,
                onRefresh: () async {
                  ref.invalidate(sellerOutstandingProvider);
                  await ref.read(sellerOutstandingProvider.future);
                },
                child: data.rows.isEmpty
                    ? const SellerEmptyState(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'No outstanding balances',
                        message: 'All accounts are settled.',
                      )
                    : _OutstandingBody(data: data),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OutstandingBody extends StatelessWidget {
  final OutstandingResponse data;
  const _OutstandingBody({required this.data});

  static String _money(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final rem = s.length - i;
      buf.write(s[i]);
      if (rem > 1 && rem % 3 == 1) buf.write(',');
    }
    return 'Rs $buf';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;

    return ListView(
      padding: AppInsets.pageWithNav,
      children: [
        SellerGrid(
          children: [
            SellerKpiCard(
              label: 'Outstanding',
              value: _money(data.totalOutstanding),
              icon: Icons.account_balance_wallet_rounded,
              tone: c.warningTone,
              caption: '${data.count} customers',
            ),
            SellerKpiCard(
              label: 'Overdue',
              value: _money(data.totalOverdue),
              icon: Icons.warning_amber_rounded,
              tone: c.warningTone,
            ),
          ],
        ),
        const Gap.v(AppSpace.md),
        const SellerSectionHeader(title: 'Customers'),
        const Gap.v(AppSpace.sm),
        ...data.rows.map((row) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpace.sm),
          child: _OutstandingCard(row: row),
        )),
      ],
    );
  }
}

class _OutstandingCard extends StatelessWidget {
  final OutstandingRow row;
  const _OutstandingCard({required this.row});

  static String _money(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final rem = s.length - i;
      buf.write(s[i]);
      if (rem > 1 && rem % 3 == 1) buf.write(',');
    }
    return 'Rs $buf';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final paidFraction = row.totalDeal > 0
        ? (row.totalPaid / row.totalDeal).clamp(0.0, 1.0)
        : 0.0;

    return SellerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(row.customerName, style: text.titleSm),
                    Text(row.customerPhone, style: text.bodySm),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.xs, vertical: 2),
                decoration: BoxDecoration(
                  color: c.infoTone.bg,
                  borderRadius: AppRadius.brPill,
                  border: Border.all(color: c.infoTone.border),
                ),
                child: Text(
                  '${row.ordersCount} order${row.ordersCount == 1 ? '' : 's'}',
                  style: text.caption.copyWith(
                      color: c.infoTone.fg, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const Gap.v(AppSpace.sm),
          SellerProgressBar(value: paidFraction, color: c.success),
          const Gap.v(AppSpace.xs),
          Row(
            children: [
              _Amt('Deal', _money(row.totalDeal), c.textPrimary, text),
              _Amt('Paid', _money(row.totalPaid), c.success, text),
              _Amt('Outstanding', _money(row.outstanding), c.warning, text),
            ],
          ),
          if (row.overdue > 0) ...[
            const Gap.v(AppSpace.xs),
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 13, color: c.warning),
                const Gap.h(AppSpace.xxs),
                Expanded(
                  child: Text(
                    'Overdue: ${_money(row.overdue)}',
                    style: text.caption.copyWith(color: c.warning),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (row.nextDueDate.isNotEmpty &&
                    row.nextDueDate != 'Not available') ...[
                  const Gap.h(AppSpace.xs),
                  Flexible(
                    child: Text(
                      'Next: ${row.nextDueDate} · ${_money(row.nextAmount)}',
                      style: text.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Amt extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final SellerTextTheme text;
  const _Amt(this.label, this.value, this.color, this.text);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: text.caption),
      Text(value, style: text.labelSm.copyWith(
          color: color, fontWeight: FontWeight.w700)),
    ]),
  );
}

class _Glyph extends StatelessWidget {
  final IconData icon;
  const _Glyph({required this.icon});
  @override
  Widget build(BuildContext context) => Container(
    width: 42, height: 42, alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: AppRadius.brMd,
    ),
    child: Icon(icon, color: Colors.white, size: 22),
  );
}
