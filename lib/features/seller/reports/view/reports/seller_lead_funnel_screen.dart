import 'package:atompro/features/seller/core/design/design.dart';
import 'package:atompro/features/seller/core/widgets/widgets.dart';
import 'package:atompro/features/seller/reports/model/seller_reports_model.dart';
import 'package:atompro/features/seller/reports/viewmodel/seller_reports_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SellerLeadFunnelScreen extends ConsumerStatefulWidget {
  const SellerLeadFunnelScreen({super.key});

  @override
  ConsumerState<SellerLeadFunnelScreen> createState() =>
      _SellerLeadFunnelScreenState();
}

class _SellerLeadFunnelScreenState
    extends ConsumerState<SellerLeadFunnelScreen> {
  static DateTime _threeMonthsAgo() {
    final d = DateTime.now();
    final m = d.month - 3;
    return m <= 0
        ? DateTime(d.year - 1, m + 12, d.day)
        : DateTime(d.year, m, d.day);
  }

  DateTime _from = _threeMonthsAgo();
  DateTime _to = DateTime.now();
  bool _generated = false;

  static String _apiDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  LeadFunnelQuery get _query =>
      LeadFunnelQuery(from: _apiDate(_from), to: _apiDate(_to));

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;

    return Scaffold(
      backgroundColor: c.canvas,
      body: Column(
        children: [
          SellerGradientHeader(
            leading: const _Glyph(icon: Icons.filter_alt_outlined),
            title: 'Lead Funnel',
            subtitle: 'Conversion stages for a date range',
            actions: const [SellerNotificationBell(), SellerHeaderProfileButton()],
          ),
          Expanded(
            child: ListView(
              padding: AppInsets.pageWithNav,
              children: [
                SellerCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text('From', style: text.caption),
                                const Gap.v(AppSpace.xs),
                                _DatePickerField(
                                  value: _from,
                                  label: 'From',
                                  onChanged: (d) =>
                                      setState(() {
                                        _from = d;
                                        _generated = false;
                                      }),
                                ),
                              ],
                            ),
                          ),
                          const Gap.h(AppSpace.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text('To', style: text.caption),
                                const Gap.v(AppSpace.xs),
                                _DatePickerField(
                                  value: _to,
                                  label: 'To',
                                  onChanged: (d) =>
                                      setState(() {
                                        _to = d;
                                        _generated = false;
                                      }),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Gap.v(AppSpace.sm),
                      SellerButton(
                        label: 'Generate',
                        icon: Icons.play_arrow_rounded,
                        onPressed: () {
                          ref.invalidate(
                              sellerLeadFunnelProvider(_query));
                          setState(() => _generated = true);
                        },
                      ),
                    ],
                  ),
                ),
                if (_generated) ...[
                  const Gap.v(AppSpace.md),
                  ref.watch(sellerLeadFunnelProvider(_query)).when(
                    loading: () => const SellerListSkeleton(),
                    error: (e, _) => SellerErrorState(
                      message: e.toString()
                          .replaceFirst('Exception: ', ''),
                      onRetry: () => ref.invalidate(
                          sellerLeadFunnelProvider(_query)),
                    ),
                    data: (data) => _FunnelBody(data: data),
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

class _FunnelBody extends StatelessWidget {
  final LeadFunnelResponse data;
  const _FunnelBody({required this.data});

  SellerTone _stageTone(String status, SellerColors c) {
    final s = status.toLowerCase();
    if (s == 'won') return c.successTone;
    if (s == 'lost') return c.warningTone;
    return c.infoTone;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SellerGrid(
          children: [
            SellerKpiCard(
              label: 'Total Leads',
              value: '${data.total}',
              icon: Icons.people_outline_rounded,
              tone: c.infoTone,
            ),
            SellerKpiCard(
              label: 'Won',
              value: '${data.won}',
              icon: Icons.check_circle_outline_rounded,
              tone: c.successTone,
            ),
            SellerKpiCard(
              label: 'Lost',
              value: '${data.lost}',
              icon: Icons.cancel_outlined,
              tone: c.warningTone,
            ),
            SellerKpiCard(
              label: 'Conversion',
              value: '${data.conversionRate.toStringAsFixed(1)}%',
              icon: Icons.swap_horiz_rounded,
              tone: c.accentTone,
            ),
          ],
        ),
        const Gap.v(AppSpace.md),
        const SellerSectionHeader(overline: 'Pipeline', title: 'Funnel stages'),
        const Gap.v(AppSpace.sm),
        SellerCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: data.funnel.asMap().entries.map((e) {
              final stage = e.value;
              final tone = _stageTone(stage.status, c);
              return Column(
                children: [
                  if (e.key > 0) Divider(height: 1, color: c.divider),
                  Padding(
                    padding: const EdgeInsets.all(AppSpace.md),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 36,
                          decoration: BoxDecoration(
                            color: tone.fg,
                            borderRadius: AppRadius.brPill,
                          ),
                        ),
                        const Gap.h(AppSpace.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(stage.status, style: text.titleSm),
                              const Gap.v(AppSpace.xxs),
                              SellerProgressBar(
                                value: (stage.pct / 100).clamp(0.0, 1.0),
                                color: tone.fg,
                              ),
                            ],
                          ),
                        ),
                        const Gap.h(AppSpace.sm),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${stage.count}',
                                style: text.titleSm.copyWith(
                                    color: tone.fg,
                                    fontWeight: FontWeight.w700)),
                            Text(
                                '${stage.pct.toStringAsFixed(1)}%',
                                style: text.caption),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final DateTime value;
  final String label;
  final ValueChanged<DateTime> onChanged;

  const _DatePickerField({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  static const _months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec',
  ];

  static String _display(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}';

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    return GestureDetector(
      onTap: () async {
        final dark = context.sellerIsDark;
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(now.year - 5),
          lastDate: DateTime(now.year + 1),
          builder: (ctx, child) => Theme(
            data: dark ? SellerTheme.dark : SellerTheme.light,
            child: child!,
          ),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.sm, vertical: AppSpace.sm),
        decoration: BoxDecoration(
          color: c.canvas,
          borderRadius: AppRadius.brMd,
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 15, color: c.accent),
            const Gap.h(AppSpace.xs),
            Expanded(
              child: Text(
                _display(value),
                style: text.bodySm.copyWith(color: c.textPrimary),
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 16, color: c.textTertiary),
          ],
        ),
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
