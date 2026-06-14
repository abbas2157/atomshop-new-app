import 'package:atompro/features/seller/core/design/design.dart';
import 'package:atompro/features/seller/core/widgets/widgets.dart';
import 'package:atompro/features/seller/reports/model/seller_reports_model.dart';
import 'package:atompro/features/seller/reports/viewmodel/seller_reports_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SellerCollectionReportScreen extends ConsumerStatefulWidget {
  const SellerCollectionReportScreen({super.key});

  @override
  ConsumerState<SellerCollectionReportScreen> createState() =>
      _SellerCollectionReportScreenState();
}

class _SellerCollectionReportScreenState
    extends ConsumerState<SellerCollectionReportScreen> {
  String _mode = 'daily';
  DateTime _from = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _to = DateTime.now();
  bool _generated = false;

  CollectionQuery get _query => CollectionQuery(
        mode: _mode,
        from: _apiDate(_from),
        to: _apiDate(_to),
      );

  static String _apiDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;

    return Scaffold(
      backgroundColor: c.canvas,
      body: Column(
        children: [
          SellerGradientHeader(
            leading: const _Glyph(icon: Icons.payments_outlined),
            title: 'Collection Report',
            subtitle: 'Payments received by period',
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
                      Text('Mode', style: text.caption),
                      const Gap.v(AppSpace.xs),
                      Row(
                        children: ['daily', 'monthly'].map((m) {
                          final active = m == _mode;
                          return Padding(
                            padding:
                                const EdgeInsets.only(right: AppSpace.xs),
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _mode = m),
                              child: AnimatedContainer(
                                duration: AppMotion.base,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpace.sm,
                                    vertical: AppSpace.xs),
                                decoration: BoxDecoration(
                                  color:
                                      active ? c.accent : c.canvas,
                                  borderRadius: AppRadius.brPill,
                                  border: Border.all(
                                      color: active
                                          ? c.accent
                                          : c.border),
                                ),
                                child: Text(
                                  m[0].toUpperCase() + m.substring(1),
                                  style: text.caption.copyWith(
                                    color: active
                                        ? c.onAccent
                                        : c.textSecondary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const Gap.v(AppSpace.sm),
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
                                  onChanged: (d) => setState(() {
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
                                  onChanged: (d) => setState(() {
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
                              sellerCollectionProvider(_query));
                          setState(() => _generated = true);
                        },
                      ),
                    ],
                  ),
                ),
                if (_generated) ...[
                  const Gap.v(AppSpace.md),
                  ref.watch(sellerCollectionProvider(_query)).when(
                    loading: () => const SellerListSkeleton(),
                    error: (e, _) => SellerErrorState(
                      message: e.toString()
                          .replaceFirst('Exception: ', ''),
                      onRetry: () => ref.invalidate(
                          sellerCollectionProvider(_query)),
                    ),
                    data: (g) {
                      if (g.isGated) {
                        return SellerPlanGateState(exception: g.gate!);
                      }
                      final data = g.value!;
                      if (data.rows.isEmpty) {
                        return const SellerEmptyState(
                          icon: Icons.payments_outlined,
                          title: 'No collections',
                          message:
                              'No payments received in this range.',
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SellerGrid(
                            children: [
                              SellerKpiCard(
                                label: 'Total Collected',
                                value: _money(data.total),
                                icon: Icons.payments_rounded,
                                tone: c.successTone,
                                caption: '${data.count} payments',
                              ),
                              if (data.methods['cash'] != null)
                                SellerKpiCard(
                                  label: 'Cash',
                                  value: _money(
                                      data.methods['cash']!.total),
                                  icon: Icons.money_rounded,
                                  tone: c.infoTone,
                                ),
                              if (data.methods['online'] != null)
                                SellerKpiCard(
                                  label: 'Online',
                                  value: _money(
                                      data.methods['online']!.total),
                                  icon: Icons.phone_android_rounded,
                                  tone: c.accentTone,
                                ),
                            ],
                          ),
                          const Gap.v(AppSpace.md),
                          const SellerSectionHeader(title: 'Periods'),
                          const Gap.v(AppSpace.sm),
                          ...data.rows.map((row) => Padding(
                            padding: const EdgeInsets.only(
                                bottom: AppSpace.sm),
                            child: _CollectionRowCard(row: row),
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

class _CollectionRowCard extends StatelessWidget {
  final CollectionRow row;
  const _CollectionRowCard({required this.row});

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

    return SellerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(row.period,
                    style: text.titleSm.copyWith(
                        fontWeight: FontWeight.w700)),
              ),
              Text('${row.count} payments', style: text.caption),
            ],
          ),
          const Gap.v(AppSpace.xs),
          Text(_money(row.total),
              style: text.titleMd.copyWith(
                  color: c.success, fontWeight: FontWeight.w700)),
          const Gap.v(AppSpace.xs),
          Row(
            children: [
              if (row.cash > 0)
                _MethodChip(
                    label: 'Cash ${_money(row.cash)}',
                    tone: c.infoTone),
              if (row.cash > 0) const Gap.h(AppSpace.xs),
              if (row.online > 0)
                _MethodChip(
                    label: 'Online ${_money(row.online)}',
                    tone: c.accentTone),
              if (row.online > 0) const Gap.h(AppSpace.xs),
              if (row.other > 0)
                _MethodChip(
                    label: 'Other ${_money(row.other)}',
                    tone: c.violetTone),
            ],
          ),
        ],
      ),
    );
  }
}

class _MethodChip extends StatelessWidget {
  final String label;
  final SellerTone tone;
  const _MethodChip({required this.label, required this.tone});

  @override
  Widget build(BuildContext context) {
    final text = context.sellerText;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.xs, vertical: 2),
      decoration: BoxDecoration(
        color: tone.bg,
        borderRadius: AppRadius.brPill,
        border: Border.all(color: tone.border),
      ),
      child: Text(label,
          style: text.caption
              .copyWith(color: tone.fg, fontWeight: FontWeight.w700)),
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
