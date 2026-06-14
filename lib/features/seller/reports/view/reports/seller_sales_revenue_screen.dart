import 'package:atompro/features/seller/core/design/design.dart';
import 'package:atompro/features/seller/core/widgets/widgets.dart';
import 'package:atompro/features/seller/reports/model/seller_reports_model.dart';
import 'package:atompro/features/seller/reports/viewmodel/seller_reports_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SellerSalesRevenueScreen extends ConsumerStatefulWidget {
  const SellerSalesRevenueScreen({super.key});

  @override
  ConsumerState<SellerSalesRevenueScreen> createState() =>
      _SellerSalesRevenueScreenState();
}

class _SellerSalesRevenueScreenState
    extends ConsumerState<SellerSalesRevenueScreen> {
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;
  bool _generated = false;

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  SalesRevenueQuery get _query =>
      SalesRevenueQuery(month: _month, year: _year);

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;

    return Scaffold(
      backgroundColor: c.canvas,
      body: Column(
        children: [
          SellerGradientHeader(
            leading: const _Glyph(icon: Icons.trending_up_rounded),
            title: 'Sales & Revenue',
            subtitle: 'Monthly breakdown with commission',
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Month', style: text.caption),
                                const Gap.v(AppSpace.xs),
                                _DropdownField<int>(
                                  value: _month,
                                  items: List.generate(12, (i) =>
                                      DropdownMenuItem(
                                          value: i + 1,
                                          child: Text(_months[i]))),
                                  onChanged: (v) => setState(
                                      () => _month = v ?? _month),
                                ),
                              ],
                            ),
                          ),
                          const Gap.h(AppSpace.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Year', style: text.caption),
                                const Gap.v(AppSpace.xs),
                                _DropdownField<int>(
                                  value: _year,
                                  items: List.generate(5, (i) {
                                    final y =
                                        DateTime.now().year - 2 + i;
                                    return DropdownMenuItem(
                                        value: y,
                                        child: Text('$y'));
                                  }),
                                  onChanged: (v) => setState(
                                      () => _year = v ?? _year),
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
                              sellerSalesRevenueProvider(_query));
                          setState(() => _generated = true);
                        },
                      ),
                    ],
                  ),
                ),
                if (_generated) ...[
                  const Gap.v(AppSpace.md),
                  ref.watch(sellerSalesRevenueProvider(_query)).when(
                    loading: () => const SellerListSkeleton(),
                    error: (e, _) => SellerErrorState(
                      message: e.toString()
                          .replaceFirst('Exception: ', ''),
                      onRetry: () => ref.invalidate(
                          sellerSalesRevenueProvider(_query)),
                    ),
                    data: (g) {
                      if (g.isGated) {
                        return SellerPlanGateState(exception: g.gate!);
                      }
                      final data = g.value!;
                      if (data.rows.isEmpty) {
                        return SellerEmptyState(
                          icon: Icons.trending_up_rounded,
                          title: 'No sales',
                          message:
                              'No orders found for ${data.period}.',
                        );
                      }
                      final t = data.totals;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SellerGrid(
                            children: [
                              SellerKpiCard(
                                label: 'Total Sale',
                                value: _money(t.totalSale),
                                icon: Icons.payments_rounded,
                                tone: c.infoTone,
                                caption: '${t.count} orders',
                              ),
                              SellerKpiCard(
                                label: 'Commission',
                                value: _money(t.commission),
                                icon: Icons.percent_rounded,
                                tone: c.warningTone,
                              ),
                              SellerKpiCard(
                                label: 'Net Revenue',
                                value: _money(t.net),
                                icon: Icons.savings_rounded,
                                tone: c.successTone,
                              ),
                            ],
                          ),
                          const Gap.v(AppSpace.md),
                          SellerSectionHeader(
                              title: 'Orders', overline: data.period),
                          const Gap.v(AppSpace.sm),
                          ...data.rows.map((row) => Padding(
                            padding: const EdgeInsets.only(
                                bottom: AppSpace.sm),
                            child: _SalesRowCard(row: row),
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

class _SalesRowCard extends StatelessWidget {
  final SalesRevenueRow row;
  const _SalesRowCard({required this.row});

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
                    style:
                        text.titleSm.copyWith(fontWeight: FontWeight.w700)),
              ),
              Text(row.date, style: text.caption),
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
              Text('${row.qty} × ${_money(row.unitPrice)}',
                  style: text.caption),
              const Spacer(),
              if (row.prNumber.isNotEmpty &&
                  row.prNumber != 'Not available')
                Text('PR: ${row.prNumber}', style: text.caption),
            ],
          ),
          const Gap.v(AppSpace.xs),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total', style: text.caption),
                    Text(_money(row.totalSale),
                        style: text.titleSm.copyWith(
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Commission', style: text.caption),
                    Text(_money(row.commission),
                        style: text.titleSm.copyWith(
                            color: c.warning,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Net', style: text.caption),
                    Text(_money(row.net),
                        style: text.titleSm.copyWith(
                            color: c.success,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final T? value;
  final Iterable<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DropdownField({
    required this.items,
    required this.onChanged,
    this.value,
  });

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
