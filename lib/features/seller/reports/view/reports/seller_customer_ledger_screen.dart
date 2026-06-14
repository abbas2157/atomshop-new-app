import 'package:atompro/features/seller/core/design/design.dart';
import 'package:atompro/features/seller/core/widgets/widgets.dart';
import 'package:atompro/features/seller/reports/model/seller_reports_model.dart';
import 'package:atompro/features/seller/reports/viewmodel/seller_reports_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SellerCustomerLedgerScreen extends ConsumerStatefulWidget {
  const SellerCustomerLedgerScreen({super.key});

  @override
  ConsumerState<SellerCustomerLedgerScreen> createState() =>
      _SellerCustomerLedgerScreenState();
}

class _SellerCustomerLedgerScreenState
    extends ConsumerState<SellerCustomerLedgerScreen> {
  int? _customerId;
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;
  bool _generated = false;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  CustomerLedgerQuery get _query => CustomerLedgerQuery(
        customerId: _customerId ?? 0,
        month: _month,
        year: _year,
      );

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final customers = ref.watch(sellerReportCustomersProvider);

    return Scaffold(
      backgroundColor: c.canvas,
      body: Column(
        children: [
          SellerGradientHeader(
            leading: const _Glyph(icon: Icons.account_balance_outlined),
            title: 'Customer Ledger',
            subtitle: 'Debit/credit with running balance',
            actions: const [SellerNotificationBell(), SellerHeaderProfileButton()],
          ),
          Expanded(
            child: ListView(
              padding: AppInsets.pageWithNav,
              children: [
                // ── Filters ──────────────────────────────────────────────
                SellerCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Customer', style: text.caption),
                      const Gap.v(AppSpace.xs),
                      customers.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (_, _) => Text('Failed to load customers',
                            style: text.bodySm),
                        data: (list) => _CustomerPickerField(
                          customers: list,
                          selectedId: _customerId,
                          onSelect: (cu) =>
                              setState(() => _customerId = cu.id),
                        ),
                      ),
                      const Gap.v(AppSpace.sm),
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
                                      DropdownMenuItem(value: i + 1,
                                          child: Text(_months[i]))),
                                  onChanged: (v) =>
                                      setState(() => _month = v ?? _month),
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
                                    final y = DateTime.now().year - 2 + i;
                                    return DropdownMenuItem(
                                        value: y, child: Text('$y'));
                                  }),
                                  onChanged: (v) =>
                                      setState(() => _year = v ?? _year),
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
                        onPressed: _customerId == null
                            ? null
                            : () {
                                ref.invalidate(
                                    sellerCustomerLedgerProvider(_query));
                                setState(() => _generated = true);
                              },
                      ),
                    ],
                  ),
                ),
                // ── Results ───────────────────────────────────────────────
                if (_generated && _customerId != null) ...[
                  const Gap.v(AppSpace.md),
                  ref.watch(sellerCustomerLedgerProvider(_query)).when(
                    loading: () => const SellerListSkeleton(),
                    error: (e, _) => SellerErrorState(
                      message: e.toString().replaceFirst('Exception: ', ''),
                      onRetry: () =>
                          ref.invalidate(sellerCustomerLedgerProvider(_query)),
                    ),
                    data: (data) => _LedgerBody(data: data),
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

class _LedgerBody extends StatelessWidget {
  final CustomerLedgerResponse data;
  const _LedgerBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Customer + period
        SellerCard(
          child: Row(
            children: [
              SellerIconBadge(icon: Icons.person_rounded, tone: c.violetTone),
              const Gap.h(AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.customer.name, style: text.titleSm),
                    Text('${data.customer.phone} · ${data.period}',
                        style: text.bodySm),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Gap.v(AppSpace.sm),
        // Opening / closing / totals
        SellerGrid(
          children: [
            SellerKpiCard(
              label: 'Opening',
              value: _money(data.openingBalance),
              icon: Icons.account_balance_outlined,
              tone: c.infoTone,
            ),
            SellerKpiCard(
              label: 'Closing',
              value: _money(data.closingBalance),
              icon: Icons.account_balance_rounded,
              tone: c.accentTone,
            ),
            SellerKpiCard(
              label: 'Total Debit',
              value: _money(data.totalDebit),
              icon: Icons.arrow_upward_rounded,
              tone: c.warningTone,
            ),
            SellerKpiCard(
              label: 'Total Credit',
              value: _money(data.totalCredit),
              icon: Icons.arrow_downward_rounded,
              tone: c.successTone,
            ),
          ],
        ),
        const Gap.v(AppSpace.md),
        const SellerSectionHeader(title: 'Entries'),
        const Gap.v(AppSpace.sm),
        if (data.entries.isEmpty)
          const SellerEmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No entries',
            message: 'No transactions found for this period.',
          )
        else
          SellerCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                // Header row
                _TableHeader(),
                Divider(height: 1, color: c.divider),
                ...data.entries.asMap().entries.map((e) => Column(
                  children: [
                    if (e.key > 0) Divider(height: 1, color: c.divider),
                    _EntryRow(entry: e.value),
                  ],
                )),
              ],
            ),
          ),
      ],
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

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final style = text.caption.copyWith(
      color: c.textSecondary, fontWeight: FontWeight.w700);
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md, vertical: AppSpace.xs),
      child: Row(
        children: [
          SizedBox(width: 72, child: Text('Date', style: style)),
          Expanded(child: Text('Narration', style: style)),
          SizedBox(width: 72,
              child: Text('Debit', style: style, textAlign: TextAlign.right)),
          SizedBox(width: 72,
              child: Text('Credit', style: style, textAlign: TextAlign.right)),
          SizedBox(width: 80,
              child: Text('Balance', style: style, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  final LedgerEntry entry;
  const _EntryRow({required this.entry});

  static String _fmt(int v) => v == 0 ? '—' : 'Rs ${_c(v)}';
  static String _c(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final rem = s.length - i;
      buf.write(s[i]);
      if (rem > 1 && rem % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md, vertical: AppSpace.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(entry.date, style: text.caption),
          ),
          Expanded(
            child: Text(entry.narration,
                style: text.bodySm, maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
          SizedBox(
            width: 72,
            child: Text(
              _fmt(entry.debit),
              textAlign: TextAlign.right,
              style: text.labelSm.copyWith(
                color: entry.debit > 0 ? c.warning : c.textTertiary,
              ),
            ),
          ),
          SizedBox(
            width: 72,
            child: Text(
              _fmt(entry.credit),
              textAlign: TextAlign.right,
              style: text.labelSm.copyWith(
                color: entry.credit > 0 ? c.success : c.textTertiary,
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              _fmt(entry.balance),
              textAlign: TextAlign.right,
              style: text.labelSm.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
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

class _DropdownField<T> extends StatelessWidget {
  final T? value;
  final String? hint;
  final Iterable<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DropdownField({
    required this.items,
    required this.onChanged,
    this.value,
    this.hint,
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
          hint: hint != null
              ? Text(hint!, style: text.bodySm.copyWith(color: c.textTertiary))
              : null,
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
  Widget build(BuildContext context) {
    return Container(
      width: 42, height: 42, alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: AppRadius.brMd,
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}
