import 'package:atompro/features/seller/core/design/design.dart';
import 'package:atompro/features/seller/core/widgets/widgets.dart';
import 'package:atompro/features/seller/reports/model/seller_reports_model.dart';
import 'package:atompro/features/seller/reports/viewmodel/seller_reports_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SellerDefaultersScreen extends ConsumerStatefulWidget {
  const SellerDefaultersScreen({super.key});

  @override
  ConsumerState<SellerDefaultersScreen> createState() =>
      _SellerDefaultersScreenState();
}

class _SellerDefaultersScreenState
    extends ConsumerState<SellerDefaultersScreen> {
  int _missed = 2;

  DefaultersQuery get _query => DefaultersQuery(missed: _missed);

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final state = ref.watch(sellerDefaultersProvider(_query));

    return Scaffold(
      backgroundColor: c.canvas,
      body: Column(
        children: [
          SellerGradientHeader(
            leading: const _Glyph(icon: Icons.warning_amber_rounded),
            title: 'Defaulter List',
            subtitle: 'Customers with missed instalments',
            actions: const [SellerNotificationBell(), SellerHeaderProfileButton()],
          ),
          // Min missed selector
          Container(
            color: c.surface,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.md, vertical: AppSpace.sm),
            child: Row(
              children: [
                Text('Min missed:', style: text.bodySm),
                const Gap.h(AppSpace.sm),
                ...List.generate(5, (i) {
                  final n = i + 1;
                  final active = n == _missed;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpace.xs),
                    child: GestureDetector(
                      onTap: () => setState(() => _missed = n),
                      child: AnimatedContainer(
                        duration: AppMotion.base,
                        width: 36, height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: active ? c.accent : c.canvas,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: active ? c.accent : c.border),
                        ),
                        child: Text('$n',
                            style: text.labelSm.copyWith(
                              color: active ? c.onAccent : c.textSecondary,
                              fontWeight: FontWeight.w700,
                            )),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          Expanded(
            child: state.when(
              loading: () => const SellerListSkeleton(),
              error: (e, _) => SellerErrorState(
                message: e.toString().replaceFirst('Exception: ', ''),
                onRetry: () =>
                    ref.invalidate(sellerDefaultersProvider(_query)),
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
                  ref.invalidate(sellerDefaultersProvider(_query));
                  await ref.read(sellerDefaultersProvider(_query).future);
                },
                child: data.rows.isEmpty
                    ? const SellerEmptyState(
                        icon: Icons.verified_user_outlined,
                        title: 'No defaulters',
                        message: 'No customers meet this threshold.',
                      )
                    : ListView(
                        padding: AppInsets.pageWithNav,
                        children: [
                          SellerGrid(
                            children: [
                              SellerKpiCard(
                                label: 'Defaulters',
                                value: '${data.count}',
                                icon: Icons.group_outlined,
                                tone: c.warningTone,
                              ),
                              SellerKpiCard(
                                label: 'Total Overdue',
                                value: _money(data.totalOverdue),
                                icon: Icons.warning_amber_rounded,
                                tone: c.warningTone,
                              ),
                            ],
                          ),
                          const Gap.v(AppSpace.md),
                          const SellerSectionHeader(title: 'Defaulters'),
                          const Gap.v(AppSpace.sm),
                          ...data.rows.map((row) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpace.sm),
                            child: _DefaulterCard(row: row),
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

class _DefaulterCard extends StatelessWidget {
  final DefaulterRow row;
  const _DefaulterCard({required this.row});

  SellerTone _severityTone(String severity, SellerColors c) {
    switch (severity.toLowerCase()) {
      case 'critical': return c.warningTone;
      case 'high':     return c.warningTone;
      default:         return c.infoTone;
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
    final tone = _severityTone(row.severity, c);
    final paidFraction = row.totalDeal > 0
        ? (row.totalPaid / row.totalDeal).clamp(0.0, 1.0)
        : 0.0;

    return SellerCard(
      accentEdge: tone.fg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('${row.customerName} · ${row.customerPhone}',
                    style: text.titleSm),
              ),
              SellerStatusPill(
                label: row.severity,
                tone: tone,
              ),
            ],
          ),
          const Gap.v(AppSpace.xxs),
          Text(row.productTitle,
              style: text.bodySm.copyWith(color: c.textSecondary),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const Gap.v(AppSpace.xxs),
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 13, color: c.warning),
              const Gap.h(AppSpace.xxs),
              Text(
                '${row.missedCount} missed · ${row.daysSince} days overdue',
                style: text.caption.copyWith(color: c.warning),
              ),
              const Spacer(),
              Text('Since ${row.oldestDue}', style: text.caption),
            ],
          ),
          const Gap.v(AppSpace.sm),
          SellerProgressBar(value: paidFraction, color: c.success),
          const Gap.v(AppSpace.xs),
          Row(
            children: [
              _Amt('Deal', _money(row.totalDeal), c.textPrimary, text),
              _Amt('Paid', _money(row.totalPaid), c.success, text),
              _Amt('Overdue', _money(row.overdueAmount), c.warning, text),
            ],
          ),
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
