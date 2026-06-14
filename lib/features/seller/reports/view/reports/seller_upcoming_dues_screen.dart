import 'package:atompro/features/seller/core/design/design.dart';
import 'package:atompro/features/seller/core/widgets/widgets.dart';
import 'package:atompro/features/seller/reports/model/seller_reports_model.dart';
import 'package:atompro/features/seller/reports/viewmodel/seller_reports_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SellerUpcomingDuesScreen extends ConsumerStatefulWidget {
  const SellerUpcomingDuesScreen({super.key});

  @override
  ConsumerState<SellerUpcomingDuesScreen> createState() =>
      _SellerUpcomingDuesScreenState();
}

class _SellerUpcomingDuesScreenState
    extends ConsumerState<SellerUpcomingDuesScreen> {
  int _days = 7;

  UpcomingDuesQuery get _query => UpcomingDuesQuery(days: _days);

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final state = ref.watch(sellerUpcomingDuesProvider(_query));

    return Scaffold(
      backgroundColor: c.canvas,
      body: Column(
        children: [
          SellerGradientHeader(
            leading: const _Glyph(icon: Icons.event_available_outlined),
            title: 'Upcoming Dues',
            subtitle: 'Follow-up reminders',
            actions: const [SellerNotificationBell(), SellerHeaderProfileButton()],
          ),
          // Days selector
          Container(
            color: c.surface,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.md, vertical: AppSpace.sm),
            child: Row(
              children: [7, 15, 30].map((d) {
                final active = d == _days;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpace.xs),
                  child: GestureDetector(
                    onTap: () => setState(() => _days = d),
                    child: AnimatedContainer(
                      duration: AppMotion.base,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.sm + 2, vertical: 6),
                      decoration: BoxDecoration(
                        color: active ? c.accent : c.canvas,
                        borderRadius: AppRadius.brPill,
                        border: Border.all(
                            color: active ? c.accent : c.border),
                      ),
                      child: Text(
                        '$d days',
                        style: context.sellerText.labelSm.copyWith(
                          color: active ? c.onAccent : c.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: state.when(
              loading: () => const SellerListSkeleton(),
              error: (e, _) => SellerErrorState(
                message: e.toString().replaceFirst('Exception: ', ''),
                onRetry: () =>
                    ref.invalidate(sellerUpcomingDuesProvider(_query)),
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
                  ref.invalidate(sellerUpcomingDuesProvider(_query));
                  await ref.read(sellerUpcomingDuesProvider(_query).future);
                },
                child: data.rows.isEmpty
                    ? const SellerEmptyState(
                        icon: Icons.event_available_outlined,
                        title: 'No upcoming dues',
                        message: 'No instalments due in this window.',
                      )
                    : ListView(
                        padding: AppInsets.pageWithNav,
                        children: [
                          SellerGrid(
                            children: [
                              SellerKpiCard(
                                label: 'Due',
                                value: _money(data.total),
                                icon: Icons.payments_rounded,
                                tone: c.warningTone,
                                caption: '${data.count} instalments',
                              ),
                            ],
                          ),
                          const Gap.v(AppSpace.md),
                          const SellerSectionHeader(title: 'Due instalments'),
                          const Gap.v(AppSpace.sm),
                          ...data.rows.map((row) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpace.sm),
                            child: _DueCard(row: row),
                          )),
                        ],
                      ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

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
}

class _DueCard extends StatelessWidget {
  final UpcomingDueRow row;
  const _DueCard({required this.row});

  SellerTone _urgencyTone(String urgency, SellerColors c) {
    switch (urgency.toLowerCase()) {
      case 'today':  return c.warningTone;
      case 'urgent': return c.warningTone;
      case 'soon':   return c.infoTone;
      default:       return c.successTone;
    }
  }

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
    final tone = _urgencyTone(row.urgency, c);

    return SellerCard(
      accentEdge: tone.fg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SellerIconBadge(icon: Icons.event_rounded, tone: tone),
          const Gap.h(AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('${row.customerName} · ${row.customerPhone}',
                          style: text.titleSm,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.xs, vertical: 2),
                      decoration: BoxDecoration(
                        color: tone.bg,
                        borderRadius: AppRadius.brPill,
                        border: Border.all(color: tone.border),
                      ),
                      child: Text(
                        row.daysLeft == 0
                            ? 'Today'
                            : '${row.daysLeft}d left',
                        style: text.caption.copyWith(
                            color: tone.fg, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const Gap.v(AppSpace.xxs),
                Text(row.productTitle,
                    style: text.bodySm.copyWith(color: c.textSecondary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const Gap.v(AppSpace.xxs),
                Text('${row.orderNo} · Month ${row.month} · ${row.dueDate}',
                    style: text.caption),
              ],
            ),
          ),
          const Gap.h(AppSpace.sm),
          Text(_money(row.amount),
              style: text.titleSm.copyWith(
                  color: tone.fg, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
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
