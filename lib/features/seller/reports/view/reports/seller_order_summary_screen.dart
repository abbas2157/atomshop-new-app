import 'package:atompro/features/seller/core/design/design.dart';
import 'package:atompro/features/seller/core/widgets/widgets.dart';
import 'package:atompro/features/seller/reports/model/seller_reports_model.dart';
import 'package:atompro/features/seller/reports/viewmodel/seller_reports_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SellerOrderSummaryScreen extends ConsumerStatefulWidget {
  const SellerOrderSummaryScreen({super.key});

  @override
  ConsumerState<SellerOrderSummaryScreen> createState() =>
      _SellerOrderSummaryScreenState();
}

class _SellerOrderSummaryScreenState
    extends ConsumerState<SellerOrderSummaryScreen> {
  DateTime _from = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _to = DateTime.now();
  String _status = 'all';
  bool _generated = false;

  static const _statusOptions = [
    'all', 'Pending', 'Varification', 'Processing',
    'Delivered', 'Instalments', 'Completed', 'Cancelled',
  ];

  static String _apiDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  OrderSummaryQuery get _query => OrderSummaryQuery(
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
            leading: const _Glyph(icon: Icons.receipt_long_outlined),
            title: 'Order Summary',
            subtitle: 'Orders in a date range',
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
                              sellerOrderSummaryProvider(_query));
                          setState(() => _generated = true);
                        },
                      ),
                    ],
                  ),
                ),
                if (_generated) ...[
                  const Gap.v(AppSpace.md),
                  ref.watch(sellerOrderSummaryProvider(_query)).when(
                    loading: () => const SellerListSkeleton(),
                    error: (e, _) => SellerErrorState(
                      message: e.toString()
                          .replaceFirst('Exception: ', ''),
                      onRetry: () => ref.invalidate(
                          sellerOrderSummaryProvider(_query)),
                    ),
                    data: (data) {
                      if (data.rows.isEmpty) {
                        return const SellerEmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: 'No orders',
                          message: 'No orders found for this range.',
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Groups strip
                          SizedBox(
                            height: 60,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: data.groups.entries
                                  .where((e) => e.value.count > 0)
                                  .map((e) => Padding(
                                        padding: const EdgeInsets.only(
                                            right: AppSpace.xs),
                                        child: _GroupChip(
                                            label: e.key,
                                            count: e.value.count),
                                      ))
                                  .toList(),
                            ),
                          ),
                          const Gap.v(AppSpace.xs),
                          SellerGrid(
                            children: [
                              SellerKpiCard(
                                label: 'Total',
                                value: _money(data.total),
                                icon: Icons.payments_rounded,
                                tone: c.infoTone,
                                caption: '${data.count} orders',
                              ),
                            ],
                          ),
                          const Gap.v(AppSpace.md),
                          const SellerSectionHeader(title: 'Orders'),
                          const Gap.v(AppSpace.sm),
                          ...data.rows.map((row) => Padding(
                            padding: const EdgeInsets.only(
                                bottom: AppSpace.sm),
                            child: _OrderRowCard(row: row),
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

class _OrderRowCard extends StatelessWidget {
  final OrderSummaryRow row;
  const _OrderRowCard({required this.row});

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
                child: Text(row.orderNo,
                    style: text.titleSm
                        .copyWith(fontWeight: FontWeight.w700)),
              ),
              SellerStatusPill(label: row.status),
            ],
          ),
          const Gap.v(AppSpace.xxs),
          Text('${row.customerName} · ${row.customerPhone}',
              style: text.bodySm),
          const Gap.v(AppSpace.xxs),
          Text(row.productTitle,
              style: text.bodySm.copyWith(color: c.textSecondary),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const Gap.v(AppSpace.xs),
          Row(
            children: [
              Text(row.date, style: text.caption),
              const Spacer(),
              Text('${row.tenure} months', style: text.caption),
            ],
          ),
          const Gap.v(AppSpace.xs),
          Row(
            children: [
              _Amt('Total', _money(row.total), c.textPrimary, text),
              _Amt('Advance', _money(row.advance), c.success, text),
            ],
          ),
        ],
      ),
    );
  }
}

class _GroupChip extends StatelessWidget {
  final String label;
  final int count;
  const _GroupChip({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.sm, vertical: AppSpace.xs),
      decoration: BoxDecoration(
        color: c.accentSurface,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: c.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$count', style: text.titleSm.copyWith(color: c.accent)),
          Text(label, style: text.caption),
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
