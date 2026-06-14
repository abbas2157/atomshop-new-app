import 'package:atompro/features/seller/core/design/design.dart';
import 'package:atompro/features/seller/core/widgets/widgets.dart';
import 'package:atompro/features/seller/reports/model/seller_reports_model.dart';
import 'package:atompro/features/seller/reports/viewmodel/seller_reports_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SellerOffersReportScreen extends ConsumerStatefulWidget {
  const SellerOffersReportScreen({super.key});

  @override
  ConsumerState<SellerOffersReportScreen> createState() =>
      _SellerOffersReportScreenState();
}

class _SellerOffersReportScreenState
    extends ConsumerState<SellerOffersReportScreen> {
  DateTime _from = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _to = DateTime.now();
  String _status = 'all';
  bool _generated = false;

  static const _statusOptions = [
    'all', 'NewLead', 'Contacted', 'Follow-up',
    'NoResponse', 'Won', 'Lost', 'custom ordered',
  ];

  static String _apiDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  OffersReportQuery get _query => OffersReportQuery(
        from: _apiDate(_from),
        to: _apiDate(_to),
        status: _status,
      );

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;

    return Scaffold(
      backgroundColor: c.canvas,
      body: Column(
        children: [
          SellerGradientHeader(
            leading: const _Glyph(icon: Icons.local_offer_outlined),
            title: 'Offers Report',
            subtitle: 'Leads with status and reason',
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
                      Text('Status', style: text.caption),
                      const Gap.v(AppSpace.xs),
                      _DropdownField<String>(
                        value: _status,
                        items: _statusOptions.map((s) =>
                            DropdownMenuItem(value: s, child: Text(s))),
                        onChanged: (v) =>
                            setState(() => _status = v ?? _status),
                      ),
                      const Gap.v(AppSpace.sm),
                      SellerButton(
                        label: 'Generate',
                        icon: Icons.play_arrow_rounded,
                        onPressed: () {
                          ref.invalidate(
                              sellerOffersReportProvider(_query));
                          setState(() => _generated = true);
                        },
                      ),
                    ],
                  ),
                ),
                if (_generated) ...[
                  const Gap.v(AppSpace.md),
                  ref.watch(sellerOffersReportProvider(_query)).when(
                    loading: () => const SellerListSkeleton(),
                    error: (e, _) => SellerErrorState(
                      message: e.toString()
                          .replaceFirst('Exception: ', ''),
                      onRetry: () => ref.invalidate(
                          sellerOffersReportProvider(_query)),
                    ),
                    data: (g) {
                      if (g.isGated) {
                        return SellerPlanGateState(exception: g.gate!);
                      }
                      final data = g.value!;
                      if (data.rows.isEmpty) {
                        return const SellerEmptyState(
                          icon: Icons.local_offer_outlined,
                          title: 'No offers',
                          message: 'No leads found for this range.',
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SellerGrid(
                            children: [
                              SellerKpiCard(
                                label: 'Total',
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
                                label: 'In Progress',
                                value: '${data.inProgress}',
                                icon: Icons.pending_outlined,
                                tone: c.accentTone,
                              ),
                              SellerKpiCard(
                                label: 'Conversion',
                                value:
                                    '${data.conversionRate.toStringAsFixed(1)}%',
                                icon: Icons.swap_horiz_rounded,
                                tone: c.violetTone,
                              ),
                            ],
                          ),
                          const Gap.v(AppSpace.md),
                          const SellerSectionHeader(title: 'Offers'),
                          const Gap.v(AppSpace.sm),
                          ...data.rows.map((row) => Padding(
                            padding: const EdgeInsets.only(
                                bottom: AppSpace.sm),
                            child: _OfferCard(row: row),
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

class _OfferCard extends StatelessWidget {
  final OfferRow row;
  const _OfferCard({required this.row});

  SellerTone _statusTone(String status, SellerColors c) {
    final s = status.toLowerCase();
    if (s == 'won') return c.successTone;
    if (s == 'lost') return c.warningTone;
    if (s == 'noresponse') return c.infoTone;
    return c.infoTone;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final tone = _statusTone(row.status, c);

    return SellerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('${row.customer} · ${row.phone}',
                    style: text.titleSm),
              ),
              SellerStatusPill(label: row.status, tone: tone),
            ],
          ),
          const Gap.v(AppSpace.xxs),
          Text(row.product,
              style: text.bodySm.copyWith(color: c.textSecondary),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const Gap.v(AppSpace.xxs),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 12, color: c.textTertiary),
              const Gap.h(AppSpace.xxs),
              Text('${row.area}, ${row.city}', style: text.caption),
              const Spacer(),
              Icon(Icons.language_outlined, size: 12, color: c.textTertiary),
              const Gap.h(AppSpace.xxs),
              Text(row.portal, style: text.caption),
              const Gap.h(AppSpace.sm),
              Text(row.date, style: text.caption),
            ],
          ),
          if (row.reason != null && row.reason!.isNotEmpty) ...[
            const Gap.v(AppSpace.xs),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.xs, vertical: AppSpace.xxs),
              decoration: BoxDecoration(
                color: c.warningTone.bg,
                borderRadius: AppRadius.brMd,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 12, color: c.warningTone.fg),
                  const Gap.h(AppSpace.xxs),
                  Flexible(
                    child: Text(row.reason!,
                        style: text.caption.copyWith(
                            color: c.warningTone.fg),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
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

class _DropdownField<T> extends StatelessWidget {
  final T? value;
  final Iterable<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  const _DropdownField({required this.items, required this.onChanged, this.value});
  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.sm, vertical: AppSpace.xs),
      decoration: BoxDecoration(
        color: c.canvas,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: c.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: c.surface,
          style: text.bodySm.copyWith(color: c.textPrimary),
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              size: 18, color: c.textTertiary),
          items: items.toList(),
          onChanged: onChanged,
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
