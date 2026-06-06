import 'package:atompro/features/seller/core/design/design.dart';
import 'package:atompro/features/seller/core/widgets/widgets.dart';
import 'package:atompro/features/seller/dashboard/model/seller_dashboard_model.dart';
import 'package:atompro/features/seller/dashboard/viewmodel/seller_dashboard_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Insights — performance & analytics, split out of the dashboard so Home can
/// stay action-first. Owns the reporting-period selection.
class SellerInsightsScreen extends ConsumerStatefulWidget {
  const SellerInsightsScreen({super.key});

  @override
  ConsumerState<SellerInsightsScreen> createState() =>
      _SellerInsightsScreenState();
}

class _SellerInsightsScreenState extends ConsumerState<SellerInsightsScreen> {
  DateTimeRange? _range;

  SellerDashboardQuery get _query => SellerDashboardQuery(
    revenueFrom: _range == null ? null : _fmtApi(_range!.start),
    revenueTo: _range == null ? null : _fmtApi(_range!.end),
  );

  static String _fmtApi(DateTime v) =>
      '${v.year}-${v.month.toString().padLeft(2, '0')}-${v.day.toString().padLeft(2, '0')}';

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final dark = context.sellerIsDark;
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _range ??
          DateTimeRange(start: DateTime(now.year, now.month, 1), end: now),
      builder: (context, child) => Theme(
        data: dark ? SellerTheme.dark : SellerTheme.light,
        child: child!,
      ),
    );
    if (selected == null || !mounted) return;
    setState(() => _range = selected);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final query = _query;
    final bundle = ref.watch(sellerDashboardProvider(query));

    return Scaffold(
      backgroundColor: c.canvas,
      body: Column(
        children: [
          SellerGradientHeader(
            leading: const _HeaderGlyph(icon: Icons.insights_rounded),
            title: 'Insights',
            subtitle: 'Performance & analytics',
            actions: [
              SellerHeaderIconButton(
                icon: Icons.refresh_rounded,
                tooltip: 'Refresh',
                onTap: () => ref.invalidate(sellerDashboardProvider(query)),
              ),
            ],
          ),
          Expanded(
            child: bundle.when(
              loading: () => const SellerListSkeleton(),
              error: (e, _) => SellerErrorState(
                message: e.toString().replaceFirst('Exception: ', ''),
                onRetry: () => ref.invalidate(sellerDashboardProvider(query)),
              ),
              data: (data) => RefreshIndicator(
                color: c.accent,
                backgroundColor: c.surface,
                onRefresh: () async {
                  ref.invalidate(sellerDashboardProvider(query));
                  await ref.read(sellerDashboardProvider(query).future);
                },
                child: _Body(
                  data: data,
                  range: _range,
                  onPickRange: _pickRange,
                  onClearRange: () => setState(() => _range = null),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final SellerDashboardBundle data;
  final DateTimeRange? range;
  final VoidCallback onPickRange;
  final VoidCallback onClearRange;

  const _Body({
    required this.data,
    required this.range,
    required this.onPickRange,
    required this.onClearRange,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final r = data.revenue;
    final d = data.dashboard;
    final p = r.performanceMetrics;

    return ListView(
      padding: AppInsets.pageWithNav,
      children: [
        _RangeCard(
          range: range,
          fallback: '${r.from} → ${r.to}',
          onPick: onPickRange,
          onClear: onClearRange,
        ),
        const Gap.v(AppSpace.md),
        SellerGrid(
          children: [
            SellerKpiCard(
              label: 'Total sales',
              value: r.totalSales,
              icon: Icons.trending_up_rounded,
              tone: c.infoTone,
            ),
            SellerKpiCard(
              label: 'Recovered',
              value: r.totalRecovered,
              icon: Icons.savings_rounded,
              tone: c.successTone,
              caption: '${r.recoveryPercentage} recovered',
            ),
          ],
        ),
        const Gap.v(AppSpace.lg),
        const SellerSectionHeader(overline: 'Trend', title: 'Revenue timeline'),
        const Gap.v(AppSpace.sm),
        _RevenueChart(points: r.revenuePoints),
        const Gap.v(AppSpace.lg),
        const SellerSectionHeader(
          overline: 'Distribution',
          title: 'Lead status',
        ),
        const Gap.v(AppSpace.sm),
        _DistributionCard(data: d.leadStatusPercentages),
        const Gap.v(AppSpace.lg),
        const SellerSectionHeader(
          overline: 'Distribution',
          title: 'Order status',
        ),
        const Gap.v(AppSpace.sm),
        _DistributionCard(data: d.orderStatusPercentages),
        const Gap.v(AppSpace.lg),
        const SellerSectionHeader(
          overline: 'Performance',
          title: 'Key metrics',
        ),
        const Gap.v(AppSpace.sm),
        SellerGrid(
          columns: 3,
          children: [
            SellerStatTile(
              label: 'Avg order',
              value: p.averageOrderValue,
              icon: Icons.shopping_cart_rounded,
            ),
            SellerStatTile(
              label: 'Conversion',
              value: p.conversionRate,
              icon: Icons.swap_horiz_rounded,
            ),
            SellerStatTile(
              label: 'On-time',
              value: p.onTimeRecoveryRate,
              icon: Icons.schedule_rounded,
            ),
            SellerStatTile(
              label: 'Days to recover',
              value: '${p.averageDaysToRecover}',
              icon: Icons.event_repeat_rounded,
            ),
            SellerStatTile(
              label: 'Unique buyers',
              value: '${p.uniqueCustomers}',
              icon: Icons.person_rounded,
            ),
            SellerStatTile(
              label: 'Repeat rate',
              value: p.repeatCustomerRate,
              icon: Icons.autorenew_rounded,
            ),
          ],
        ),
      ],
    );
  }
}

class _RangeCard extends StatelessWidget {
  final DateTimeRange? range;
  final String fallback;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _RangeCard({
    required this.range,
    required this.fallback,
    required this.onPick,
    required this.onClear,
  });

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static String _fmt(DateTime d) => '${d.day} ${_months[d.month - 1]}';

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final label = range == null
        ? fallback
        : '${_fmt(range!.start)} → ${_fmt(range!.end)}';

    return SellerCard(
      onTap: onPick,
      child: Row(
        children: [
          SellerIconBadge(icon: Icons.calendar_month_rounded, tone: c.accentTone),
          const Gap.h(AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reporting period', style: text.caption),
                const Gap.v(2),
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.titleSm),
              ],
            ),
          ),
          if (range != null)
            IconButton(
              splashRadius: 18,
              icon: Icon(Icons.close_rounded, size: 18, color: c.textTertiary),
              onPressed: onClear,
            )
          else
            Icon(Icons.edit_calendar_rounded, size: 18, color: c.accent),
        ],
      ),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  final List<SellerRevenuePoint> points;
  const _RevenueChart({required this.points});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;

    if (points.isEmpty) {
      return SellerCard(
        child: SizedBox(
          height: 120,
          child: Center(
            child: Text('No revenue data for this period', style: text.bodySm),
          ),
        ),
      );
    }

    final maxVal = points
        .map((p) => p.sales > p.recovered ? p.sales : p.recovered)
        .fold<int>(1, (a, b) => a > b ? a : b);

    return SellerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _LegendDot(color: c.accent, label: 'Sales'),
              const Gap.h(AppSpace.md),
              _LegendDot(color: c.success, label: 'Recovered'),
            ],
          ),
          const Gap.v(AppSpace.md),
          SizedBox(
            height: 150,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final p in points)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpace.md),
                      child: _ChartColumn(
                        salesFraction: p.sales / maxVal,
                        recoveredFraction: p.recovered / maxVal,
                        label: p.period,
                        salesColor: c.accent,
                        recoveredColor: c.success,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartColumn extends StatelessWidget {
  final double salesFraction;
  final double recoveredFraction;
  final String label;
  final Color salesColor;
  final Color recoveredColor;

  const _ChartColumn({
    required this.salesFraction,
    required this.recoveredFraction,
    required this.label,
    required this.salesColor,
    required this.recoveredColor,
  });

  @override
  Widget build(BuildContext context) {
    final text = context.sellerText;
    const maxH = 110.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _Bar(height: (salesFraction * maxH).clamp(3, maxH), color: salesColor),
            const Gap.h(4),
            _Bar(height: (recoveredFraction * maxH).clamp(3, maxH), color: recoveredColor),
          ],
        ),
        const Gap.v(AppSpace.xs),
        SizedBox(
          width: 44,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: text.caption,
          ),
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  final double height;
  final Color color;
  const _Bar({required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.slow,
      curve: AppMotion.standard,
      width: 14,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final text = context.sellerText;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const Gap.h(AppSpace.xs - 2),
        Text(label, style: text.bodySm),
      ],
    );
  }
}

class _DistributionCard extends StatelessWidget {
  final Map<String, int> data;
  const _DistributionCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;

    if (data.isEmpty) {
      return SellerCard(child: Text('No data available', style: text.bodySm));
    }

    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SellerCard(
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const Gap.v(AppSpace.md),
            Builder(
              builder: (context) {
                final e = entries[i];
                final tone = SellerStatus.toneFor(e.key, c);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            e.key,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodySm.copyWith(
                              color: c.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${e.value}%',
                          style: text.labelSm.copyWith(
                            color: tone.fg,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const Gap.v(AppSpace.xs),
                    SellerProgressBar(value: e.value / 100, color: tone.fg),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderGlyph extends StatelessWidget {
  final IconData icon;
  const _HeaderGlyph({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: AppRadius.brMd,
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}
