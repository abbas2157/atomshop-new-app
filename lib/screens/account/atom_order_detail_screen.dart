import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

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
import '../installments/atom_orders_widgets.dart';

/// Order detail (canvas: "Order detail"): status timeline, plan figures,
/// delivery and seller, and the installment schedule. Works for product
/// orders and custom orders alike.
class AtomOrderDetailScreen extends ConsumerWidget {
  const AtomOrderDetailScreen({super.key, required this.uuid});

  final String uuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(orderDetailProvider(uuid));
    final d = value.value;
    final o = d?.card;

    return AtomPage(
      title: o == null || o.orderId.isEmpty ? 'Order' : 'Order #${o.orderId}',
      subtitle: o?.createdAt == null ? null : 'Placed ${AtomFormat.date(o!.createdAt)}',
      onRefresh: () async {
        ref.invalidate(orderDetailProvider(uuid));
        await ref.read(orderDetailProvider(uuid).future).then<void>((_) {}, onError: (_) {});
      },
      children: [
        AtomAsync<OrderDetail>(
          value: value,
          onRetry: () => ref.invalidate(orderDetailProvider(uuid)),
          loading: const Column(children: [AtomSkeleton(height: 72, radius: AtomRadius.card), SizedBox(height: AtomSpace.md), AtomSkeleton(height: 260, radius: AtomRadius.card)]),
          data: (d) => _Body(detail: d),
        ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.detail});

  final OrderDetail detail;

  @override
  Widget build(BuildContext context) {
    final o = detail.card;
    final seller = o.seller;
    final plan = o.monthly == null ? 'Paid in full' : '${o.months} months';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AtomColors.surface, borderRadius: BorderRadius.circular(AtomRadius.card)),
          child: Row(
            children: [
              OrderThumb(pictureUrl: o.pictureUrl, size: 52),
              const SizedBox(width: AtomSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o.title, style: AtomText.label),
                    Text([plan, if (o.colour.isNotEmpty) o.colour, if (o.isAtompay) 'AtomPay', if (o.isCustom) 'Custom order'].join(' · '), style: AtomText.small),
                  ],
                ),
              ),
              AtomBadge.orderStatus(o.status),
            ],
          ),
        ),
        if (detail.timeline.isNotEmpty) ...[
          const AtomGroupLabel('Order status'),
          _Timeline(steps: detail.timeline),
        ],
        const AtomGroupLabel('Plan'),
        AtomCard(
          child: Column(
            children: [
              if (detail.cashPrice != null) AtomInfoRow('Cash price', AtomFormat.rupees(detail.cashPrice)),
              if (o.monthly != null) AtomInfoRow('Advance', AtomFormat.rupees(o.advance)),
              if (o.monthly != null) AtomInfoRow('Monthly · ${o.months} months', AtomFormat.rupees(o.monthly)),
              AtomInfoRow('Total payable', AtomFormat.rupees(o.total), strong: true),
              AtomInfoRow('Paid', AtomFormat.rupees(o.paid), valueColor: AtomColors.green),
              AtomInfoRow('Still to pay', AtomFormat.rupees(o.outstanding)),
            ],
          ),
        ),
        if (o.isAtompay && detail.atompayUrl.isNotEmpty) ...[
          const SizedBox(height: AtomSpace.sm),
          AtomButton(
            label: 'Complete AtomPay profile',
            icon: Icons.open_in_new_rounded,
            variant: AtomButtonVariant.dark,
            expand: true,
            onPressed: () => launchUrl(Uri.parse(detail.atompayUrl), mode: LaunchMode.externalApplication),
          ),
        ],
        const AtomGroupLabel('Delivery'),
        AtomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined, size: 20, color: AtomColors.primary),
                  const SizedBox(width: AtomSpace.xs),
                  Expanded(child: Text(detail.deliveryLine.isEmpty ? 'Address confirmed by the seller' : detail.deliveryLine, style: AtomText.body)),
                ],
              ),
              if (seller != null) ...[
                const SizedBox(height: AtomSpace.xs),
                Text.rich(TextSpan(children: [
                  TextSpan(text: 'Seller: ', style: AtomText.body),
                  TextSpan(text: seller.display, style: AtomText.label),
                ])),
              ],
            ],
          ),
        ),
        if (o.schedule.isNotEmpty) ...[
          const AtomGroupLabel('Installment schedule'),
          ScheduleList(rows: o.schedule, onOpenReceipt: (id) => AtomNav.receipt(context, id)),
          const SizedBox(height: AtomSpace.xs),
          Text('Tap a paid month to open its receipt.', style: AtomText.small),
        ],
        const SizedBox(height: AtomSpace.lg),
        Row(
          children: [
            if (seller != null && seller.phone.isNotEmpty) ...[
              Expanded(
                child: AtomButton(label: 'Call seller', icon: Icons.call_outlined, size: AtomButtonSize.medium, expand: true, onPressed: () => atomCall(seller.phone)),
              ),
              const SizedBox(width: AtomSpace.sm),
            ],
            Expanded(
              child: AtomButton(
                label: 'Get help',
                icon: Icons.help_outline_rounded,
                variant: AtomButtonVariant.secondary,
                size: AtomButtonSize.medium,
                expand: true,
                onPressed: () => AtomNav.faqs(context),
              ),
            ),
          ],
        ),
        if (o.schedule.isNotEmpty) ...[
          const SizedBox(height: AtomSpace.sm),
          AtomButton(
            label: 'View payment history',
            icon: Icons.calendar_month_rounded,
            variant: AtomButtonVariant.secondary,
            size: AtomButtonSize.medium,
            expand: true,
            onPressed: () => AtomNav.payments(context, orderUuid: o.uuid),
          ),
        ],
      ],
    );
  }
}

/// Vertical status timeline: done steps green, the first open step blue,
/// later steps grey.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.steps});

  final List<TimelineStep> steps;

  @override
  Widget build(BuildContext context) {
    final current = steps.indexWhere((s) => !s.done);
    return AtomCard(
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 22,
                    child: Column(
                      children: [
                        _Dot(done: steps[i].done, current: i == current),
                        if (i < steps.length - 1)
                          Expanded(child: Container(width: 2, color: steps[i].done ? AtomColors.green : AtomColors.line)),
                      ],
                    ),
                  ),
                  const SizedBox(width: AtomSpace.sm),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: i < steps.length - 1 ? AtomSpace.md : 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            steps[i].label.isEmpty ? steps[i].status : steps[i].label,
                            style: AtomText.label.copyWith(
                              color: i == current ? AtomColors.primary : (steps[i].done ? AtomColors.ink : AtomColors.muted),
                              fontWeight: i == current ? FontWeight.w800 : FontWeight.w700,
                            ),
                          ),
                          if (steps[i].at != null) Text(AtomFormat.date(steps[i].at), style: AtomText.small),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.done, required this.current});

  final bool done;
  final bool current;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? AtomColors.green : AtomColors.white,
        border: done ? null : Border.all(color: current ? AtomColors.primary : AtomColors.line2, width: current ? 3 : 2),
      ),
      child: done ? const Icon(Icons.check_rounded, size: 12, color: AtomColors.white) : null,
    );
  }
}
