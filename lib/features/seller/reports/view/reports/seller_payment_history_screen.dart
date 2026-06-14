import 'package:atompro/features/seller/core/design/design.dart';
import 'package:atompro/features/seller/core/widgets/widgets.dart';
import 'package:atompro/features/seller/reports/model/seller_reports_model.dart';
import 'package:atompro/features/seller/reports/viewmodel/seller_reports_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SellerPaymentHistoryScreen extends ConsumerStatefulWidget {
  const SellerPaymentHistoryScreen({super.key});

  @override
  ConsumerState<SellerPaymentHistoryScreen> createState() =>
      _SellerPaymentHistoryScreenState();
}

class _SellerPaymentHistoryScreenState
    extends ConsumerState<SellerPaymentHistoryScreen> {
  int? _customerId;
  bool _generated = false;

  PaymentHistoryQuery? get _query =>
      _customerId == null ? null : PaymentHistoryQuery(customerId: _customerId!);

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final customersState = ref.watch(sellerReportCustomersProvider);

    return Scaffold(
      backgroundColor: c.canvas,
      body: Column(
        children: [
          SellerGradientHeader(
            leading: const _Glyph(icon: Icons.history_rounded),
            title: 'Payment History',
            subtitle: 'Instalment & advance payments per customer',
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
                      Text('Customer', style: text.caption),
                      const Gap.v(AppSpace.xs),
                      customersState.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (_, _) => Text(
                          'Failed to load customers',
                          style: text.bodySm.copyWith(color: c.warning),
                        ),
                        data: (customers) => _CustomerPickerField(
                          customers: customers,
                          selectedId: _customerId,
                          onSelect: (cu) => setState(() {
                            _customerId = cu.id;
                            _generated = false;
                          }),
                        ),
                      ),
                      const Gap.v(AppSpace.sm),
                      SellerButton(
                        label: 'Generate',
                        icon: Icons.play_arrow_rounded,
                        onPressed: _customerId == null
                            ? null
                            : () {
                                final q = _query!;
                                ref.invalidate(
                                    sellerPaymentHistoryProvider(q));
                                setState(() => _generated = true);
                              },
                      ),
                    ],
                  ),
                ),
                if (_generated && _query != null) ...[
                  const Gap.v(AppSpace.md),
                  ref.watch(sellerPaymentHistoryProvider(_query!)).when(
                    loading: () => const SellerListSkeleton(),
                    error: (e, _) => SellerErrorState(
                      message: e.toString().replaceFirst('Exception: ', ''),
                      onRetry: () => ref.invalidate(
                          sellerPaymentHistoryProvider(_query!)),
                    ),
                    data: (data) => data.rows.isEmpty
                        ? const SellerEmptyState(
                            icon: Icons.history_rounded,
                            title: 'No payments',
                            message: 'No payment records found.',
                          )
                        : _PaymentBody(data: data),
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

class _PaymentBody extends StatelessWidget {
  final PaymentHistoryResponse data;
  const _PaymentBody({required this.data});

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SellerCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.customer.name, style: text.titleSm),
                    Text(data.customer.phone, style: text.bodySm),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${data.count} payments', style: text.caption),
                  Text(
                    _money(data.total),
                    style: text.titleSm.copyWith(
                        color: c.success, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Gap.v(AppSpace.md),
        const SellerSectionHeader(title: 'Payment log'),
        const Gap.v(AppSpace.sm),
        ...data.rows.map((row) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpace.sm),
          child: _PaymentCard(row: row),
        )),
      ],
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final PaymentRow row;
  const _PaymentCard({required this.row});

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

  SellerTone _typeTone(String type, SellerColors c) {
    final t = type.toLowerCase();
    if (t.contains('advance')) return c.infoTone;
    if (t.contains('instal')) return c.accentTone;
    if (t.contains('late')) return c.warningTone;
    return c.infoTone;
  }

  SellerTone _methodTone(String method, SellerColors c) {
    final m = method.toLowerCase();
    if (m.contains('cash')) return c.successTone;
    if (m.contains('bank') || m.contains('transfer')) return c.accentTone;
    if (m.contains('easypaisa') || m.contains('jazz')) return c.violetTone;
    return c.infoTone;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final typeTone = _typeTone(row.type, c);
    final methodTone = _methodTone(row.method, c);

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
              Text(
                _money(row.amount),
                style: text.titleSm.copyWith(
                    color: c.success, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const Gap.v(AppSpace.xxs),
          Text(row.productTitle,
              style: text.bodySm.copyWith(color: c.textSecondary),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const Gap.v(AppSpace.xs),
          Row(
            children: [
              _Chip(label: row.type, tone: typeTone),
              const Gap.h(AppSpace.xs),
              _Chip(label: row.method, tone: methodTone),
              if (row.month != null && row.month!.isNotEmpty) ...[
                const Gap.h(AppSpace.xs),
                _Chip(label: row.month!, tone: c.infoTone),
              ],
              const Spacer(),
              Text(row.date, style: text.caption),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final SellerTone tone;
  const _Chip({required this.label, required this.tone});

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
      child: Text(
        label,
        style: text.caption
            .copyWith(color: tone.fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _CustomerPickerField extends StatelessWidget {
  final List<ReportCustomer> customers;
  final int? selectedId;
  final ValueChanged<ReportCustomer> onSelect;

  const _CustomerPickerField({
    required this.customers,
    required this.onSelect,
    this.selectedId,
  });

  ReportCustomer? get _selected =>
      customers.where((c) => c.id == selectedId).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final sel = _selected;

    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.sm, vertical: AppSpace.sm + 2),
        decoration: BoxDecoration(
          color: c.canvas,
          borderRadius: AppRadius.brMd,
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                sel != null
                    ? '${sel.name} · ${sel.phone}'
                    : 'Select customer',
                style: text.bodySm.copyWith(
                    color: sel != null ? c.textPrimary : c.textTertiary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 18, color: c.textTertiary),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context) {
    final dark = context.sellerIsDark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Theme(
        data: dark ? SellerTheme.dark : SellerTheme.light,
        child: _CustomerPickerSheet(
          customers: customers,
          selectedId: selectedId,
          onSelect: (cu) {
            Navigator.pop(context);
            onSelect(cu);
          },
        ),
      ),
    );
  }
}

class _CustomerPickerSheet extends StatefulWidget {
  final List<ReportCustomer> customers;
  final int? selectedId;
  final ValueChanged<ReportCustomer> onSelect;

  const _CustomerPickerSheet({
    required this.customers,
    required this.onSelect,
    this.selectedId,
  });

  @override
  State<_CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<_CustomerPickerSheet> {
  final _ctrl = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<ReportCustomer> get _filtered {
    if (_q.isEmpty) return widget.customers;
    final q = _q.toLowerCase();
    return widget.customers
        .where((c) =>
            c.name.toLowerCase().contains(q) || c.phone.contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final filtered = _filtered;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl)),
      ),
      child: Column(
        children: [
          const Gap.v(AppSpace.sm),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: c.borderStrong, borderRadius: AppRadius.brPill),
            ),
          ),
          const Gap.v(AppSpace.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Select Customer', style: text.titleMd),
            ),
          ),
          const Gap.v(AppSpace.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              onChanged: (v) => setState(() => _q = v),
              style: text.bodySm.copyWith(color: c.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search name or phone…',
                hintStyle: text.bodySm.copyWith(color: c.textTertiary),
                prefixIcon: Icon(Icons.search_rounded,
                    size: 20, color: c.textTertiary),
                suffixIcon: _q.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _ctrl.clear();
                          setState(() => _q = '');
                        },
                        child: Icon(Icons.clear_rounded,
                            size: 18, color: c.textTertiary),
                      )
                    : null,
                filled: true,
                fillColor: c.canvas,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.sm, vertical: AppSpace.xs),
                border: OutlineInputBorder(
                  borderRadius: AppRadius.brMd,
                  borderSide: BorderSide(color: c.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.brMd,
                  borderSide: BorderSide(color: c.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.brMd,
                  borderSide: BorderSide(color: c.accent, width: 1.5),
                ),
              ),
            ),
          ),
          const Gap.v(AppSpace.sm),
          Divider(height: 1, color: c.divider),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text('No customers found',
                        style: text.bodySm
                            .copyWith(color: c.textSecondary)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpace.xs),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: c.divider,
                        indent: AppSpace.md),
                    itemBuilder: (_, i) {
                      final cu = filtered[i];
                      final active = cu.id == widget.selectedId;
                      return InkWell(
                        onTap: () => widget.onSelect(cu),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpace.md,
                              vertical: AppSpace.sm),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cu.name,
                                      style: text.titleSm.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: active
                                              ? c.accent
                                              : c.textPrimary),
                                    ),
                                    Text(cu.phone,
                                        style: text.bodySm.copyWith(
                                            color: c.textSecondary)),
                                  ],
                                ),
                              ),
                              if (active)
                                Icon(Icons.check_rounded,
                                    size: 18, color: c.accent),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SizedBox(
              height: MediaQuery.of(context).padding.bottom + AppSpace.sm),
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
