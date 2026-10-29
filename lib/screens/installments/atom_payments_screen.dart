import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/atom_account.dart';
import '../../data/atom_http.dart';
import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../shell/atom_nav.dart';
import '../../state/atom_account_providers.dart';
import '../../utils/atom_format.dart';
import '../../widgets/atom_button.dart';
import '../../widgets/atom_page.dart';
import '../../widgets/atom_states.dart';
import '../../widgets/atom_surfaces.dart';
import 'atom_orders_widgets.dart';

/// Payment history (canvas: "Payment history"): totals, filter by order,
/// paid installments with receipts, and the split by payment method.
class AtomPaymentsScreen extends ConsumerStatefulWidget {
  const AtomPaymentsScreen({super.key, this.orderUuid = ''});

  /// Empty for all orders.
  final String orderUuid;

  @override
  ConsumerState<AtomPaymentsScreen> createState() => _AtomPaymentsScreenState();
}

class _AtomPaymentsScreenState extends ConsumerState<AtomPaymentsScreen> {
  late String _order = widget.orderUuid;
  final List<Payment> _more = [];
  int? _next;
  bool _loadingMore = false;

  /// Chips are kept from the "all orders" answer, so they don't vanish when
  /// one order is picked.
  List<(String, String)> _orderChips = const [];

  void _pick(String uuid) => setState(() {
        _order = uuid;
        _more.clear();
        _next = null;
      });

  Future<void> _loadMore(int page) async {
    setState(() => _loadingMore = true);
    try {
      final res = await ref.read(atomAccountApiProvider).payments(orderUuid: _order.isEmpty ? null : _order, page: page);
      if (!mounted) return;
      setState(() {
        _more.addAll(res.payments);
        _next = res.nextPage ?? -1;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(atomMessage(e))));
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(paymentsProvider(_order));
    final page = value.value;
    if (page != null && page.orders.length > _orderChips.length) _orderChips = page.orders;

    return AtomPage(
      title: 'Payment history',
      onRefresh: () async {
        _pick(_order);
        ref.invalidate(paymentsProvider(_order));
        await ref.read(paymentsProvider(_order).future).then<void>((_) {}, onError: (_) {});
      },
      bottom: AtomButton(
        label: 'A payment missing? Message us',
        icon: Icons.chat_bubble_outline_rounded,
        variant: AtomButtonVariant.secondary,
        expand: true,
        onPressed: () => AtomNav.contact(context),
      ),
      children: [
        AtomAsync<PaymentsPage>(
          value: value,
          onRetry: () => ref.invalidate(paymentsProvider(_order)),
          loading: const Column(children: [AtomSkeleton(height: 120, radius: AtomRadius.card), SizedBox(height: AtomSpace.md), AtomSkeleton(height: 200, radius: AtomRadius.card)]),
          data: (p) => _body(context, p),
        ),
      ],
    );
  }

  Widget _body(BuildContext context, PaymentsPage p) {
    final payments = [...p.payments, ..._more];
    final next = _next == null ? p.nextPage : (_next! < 0 ? null : _next);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DarkFigures(
          label: 'Total paid',
          amount: p.paid,
          items: [
            ('Advance', AtomFormat.rupees(p.advance), false),
            ('Monthly', AtomFormat.rupees(p.monthly), false),
            ('Still to pay', AtomFormat.rupees(p.outstanding), true),
          ],
        ),
        if (_orderChips.length > 1) ...[
          const SizedBox(height: AtomSpace.md),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                AtomChoiceChip(label: 'All orders', dark: true, selected: _order.isEmpty, onTap: () => _pick('')),
                for (final (uuid, label) in _orderChips) ...[
                  const SizedBox(width: AtomSpace.xs),
                  AtomChoiceChip(label: label, dark: true, selected: _order == uuid, onTap: () => _pick(uuid)),
                ],
              ],
            ),
          ),
        ],
        const AtomGroupLabel('Paid installments'),
        if (payments.isEmpty)
          const AtomEmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No payments yet',
            message: 'Payments your seller marks as received show up here with a receipt.',
          )
        else
          AtomCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < payments.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: AtomColors.line),
                  _PaymentRow(payment: payments[i]),
                ],
              ],
            ),
          ),
        if (next != null) ...[
          const SizedBox(height: AtomSpace.sm),
          Center(
            child: AtomButton(
              label: 'Load more',
              icon: Icons.expand_more_rounded,
              variant: AtomButtonVariant.secondary,
              size: AtomButtonSize.medium,
              loading: _loadingMore,
              onPressed: _loadingMore ? null : () => _loadMore(next),
            ),
          ),
        ],
        if (p.byMethod.isNotEmpty) ...[
          const AtomGroupLabel('By payment method'),
          Container(
            padding: const EdgeInsets.all(AtomSpace.md),
            decoration: BoxDecoration(color: AtomColors.surface, borderRadius: BorderRadius.circular(AtomRadius.card)),
            child: Column(
              children: [
                for (final (method, amount, percent) in p.byMethod)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(method.isEmpty ? 'Other' : method, style: AtomText.label)),
                            Text('${AtomFormat.rupees(amount)} · $percent%', style: AtomText.small),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AtomRadius.pill),
                          child: LinearProgressIndicator(
                            value: (percent / 100).clamp(0.0, 1.0),
                            minHeight: 6,
                            color: AtomColors.primary,
                            backgroundColor: AtomColors.line,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context) {
    final p = payment;
    return InkWell(
      onTap: () => AtomNav.receipt(context, p.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AtomSpace.md, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: AtomColors.greenSoft, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.check_rounded, size: 18, color: AtomColors.green),
            ),
            const SizedBox(width: AtomSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text([p.label, p.product].where((s) => s.isNotEmpty).join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, style: AtomText.label),
                  Text([if (p.paidAt != null) AtomFormat.date(p.paidAt), if (p.method.isNotEmpty) p.method].join(' · '), style: AtomText.small),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(AtomFormat.rupees(p.amount), style: AtomText.label),
                Text('Receipt', style: AtomText.small.copyWith(color: AtomColors.primary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
