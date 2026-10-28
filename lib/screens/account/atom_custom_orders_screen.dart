import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/atom_account.dart';
import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../shell/atom_nav.dart';
import '../../state/atom_account_providers.dart';
import '../../utils/atom_format.dart';
import '../../widgets/atom_button.dart';
import '../../widgets/atom_page.dart';
import '../../widgets/atom_states.dart';
import '../../widgets/atom_surfaces.dart';

/// Custom orders and offers (canvas: "Custom orders and offers").
class AtomCustomOrdersScreen extends ConsumerStatefulWidget {
  const AtomCustomOrdersScreen({super.key, this.showOffers = false});

  final bool showOffers;

  @override
  ConsumerState<AtomCustomOrdersScreen> createState() => _AtomCustomOrdersScreenState();
}

class _AtomCustomOrdersScreenState extends ConsumerState<AtomCustomOrdersScreen> {
  late bool _offers = widget.showOffers;

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(customOrdersProvider);
    final offers = ref.watch(offersProvider);
    String count(AsyncValue<List<Object>> v) => v.hasValue ? ' · ${v.value!.length}' : '';

    return AtomPage(
      title: 'Custom orders and offers',
      onRefresh: () async {
        ref
          ..invalidate(customOrdersProvider)
          ..invalidate(offersProvider);
        await Future.wait([
          ref.read(customOrdersProvider.future).then<void>((_) {}, onError: (_) {}),
          ref.read(offersProvider.future).then<void>((_) {}, onError: (_) {}),
        ]);
      },
      children: [
        AtomSegmented<bool>(
          items: {false: 'Custom orders${count(orders)}', true: 'My offers${count(offers)}'},
          value: _offers,
          onChanged: (v) => setState(() => _offers = v),
        ),
        const SizedBox(height: AtomSpace.md),
        if (!_offers)
          AtomAsync<List<CustomOrderRow>>(
            value: orders,
            onRetry: () => ref.invalidate(customOrdersProvider),
            loading: const AtomSkeleton(height: 130, radius: AtomRadius.card),
            data: (rows) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (rows.isEmpty)
                  const AtomEmptyState(
                    icon: Icons.calculate_outlined,
                    title: 'No custom orders yet',
                    message: 'Know the price? Order anything from any shop and plan it in months.',
                  ),
                for (final r in rows) ...[_CustomOrderCard(row: r), const SizedBox(height: AtomSpace.sm)],
                Align(
                  alignment: Alignment.centerLeft,
                  child: AtomButton(
                    label: 'New custom order',
                    icon: Icons.add_rounded,
                    variant: AtomButtonVariant.text,
                    size: AtomButtonSize.medium,
                    onPressed: () => AtomNav.customOrder(context),
                  ),
                ),
              ],
            ),
          )
        else
          AtomAsync<List<OfferRow>>(
            value: offers,
            onRetry: () => ref.invalidate(offersProvider),
            loading: const AtomSkeleton(height: 130, radius: AtomRadius.card),
            data: (rows) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Offers you sent with Make an offer. Sellers in your area reply and call you.', style: AtomText.body.copyWith(fontSize: 13)),
                const SizedBox(height: AtomSpace.sm),
                if (rows.isEmpty)
                  const AtomEmptyState(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'No offers yet',
                    message: 'Not sure of the price? Tell us what you want and a seller calls you.',
                  ),
                for (final r in rows) ...[_OfferCard(row: r), const SizedBox(height: AtomSpace.sm)],
                Align(
                  alignment: Alignment.centerLeft,
                  child: AtomButton(
                    label: 'Make a new offer',
                    icon: Icons.chat_bubble_outline_rounded,
                    variant: AtomButtonVariant.text,
                    size: AtomButtonSize.medium,
                    onPressed: () => AtomNav.makeOffer(context),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CustomOrderCard extends StatelessWidget {
  const _CustomOrderCard({required this.row});

  final CustomOrderRow row;

  @override
  Widget build(BuildContext context) {
    Widget stat(String label, String value) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AtomColors.surface, borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text(label, style: AtomText.small), Text(value, style: AtomText.label)],
            ),
          ),
        );

    return AtomCard(
      onTap: () => AtomNav.orderDetail(context, row.uuid),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(row.product, style: AtomText.label),
                    Text(
                      [if (row.orderId.isNotEmpty) '#${row.orderId}', if (row.createdAt != null) AtomFormat.date(row.createdAt)].join(' · '),
                      style: AtomText.small,
                    ),
                  ],
                ),
              ),
              AtomBadge.orderStatus(row.status),
            ],
          ),
          const SizedBox(height: AtomSpace.sm),
          Row(
            children: [
              stat('Price', AtomFormat.rupees(row.price)),
              const SizedBox(width: AtomSpace.xs),
              stat('Monthly', AtomFormat.rupees(row.monthly)),
              const SizedBox(width: AtomSpace.xs),
              stat('Months', '${row.months}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.row});

  final OfferRow row;

  @override
  Widget build(BuildContext context) {
    final tone = switch (row.statusLabel.toLowerCase()) {
      'new' => AtomTone.blue,
      'contacted' => AtomTone.violet,
      'ordered' => AtomTone.green,
      'closed' => AtomTone.rose,
      _ => AtomTone.neutral,
    };
    return AtomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(row.product, style: AtomText.label),
                    Text(
                      ['Sent ${row.createdAt == null ? '' : AtomFormat.date(row.createdAt)}'.trim(), if (row.area.isNotEmpty) row.area].join(' · '),
                      style: AtomText.small,
                    ),
                  ],
                ),
              ),
              AtomBadge(row.statusLabel, tone: tone),
            ],
          ),
          if (row.note.isNotEmpty) ...[
            const SizedBox(height: AtomSpace.sm),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AtomColors.surface, borderRadius: BorderRadius.circular(14)),
              child: Text(row.note, style: AtomText.body.copyWith(fontSize: 13)),
            ),
          ],
        ],
      ),
    );
  }
}
