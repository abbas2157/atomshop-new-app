import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/atom_account.dart';
import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../responsive/atom_responsive.dart';
import '../../shell/atom_nav.dart';
import '../../shell/atom_shell.dart';
import '../../state/atom_account_providers.dart';
import '../../utils/atom_format.dart';
import '../../widgets/atom_button.dart';
import '../../widgets/atom_states.dart';
import '../../widgets/atom_surfaces.dart';
import 'atom_orders_widgets.dart';

enum _Tab { active, pending, completed }

/// Installments tab, signed in (canvas: "Installments"). Every figure is
/// the server's.
class AtomPlansScreen extends ConsumerStatefulWidget {
  const AtomPlansScreen({super.key});

  @override
  ConsumerState<AtomPlansScreen> createState() => _AtomPlansScreenState();
}

class _AtomPlansScreenState extends ConsumerState<AtomPlansScreen> {
  _Tab _tab = _Tab.active;

  @override
  Widget build(BuildContext context) {
    final gutter = context.atomGutter;
    final provider = installmentsProvider(_tab.name);
    final value = ref.watch(provider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: AtomPageWidth(
          child: RefreshIndicator(
            color: AtomColors.primary,
            onRefresh: () async {
              ref.invalidate(provider);
              await ref.read(provider.future).then<void>((_) {}, onError: (_) {});
            },
            child: ListView(
              padding: EdgeInsets.fromLTRB(gutter, AtomSpace.md, gutter, AtomSpace.xl),
              children: [
                Row(
                  children: [
                    Expanded(child: Semantics(header: true, child: Text('Installments', style: AtomText.title))),
                    AtomButton(
                      label: 'History',
                      icon: Icons.credit_card_rounded,
                      variant: AtomButtonVariant.secondary,
                      size: AtomButtonSize.small,
                      onPressed: () => AtomNav.payments(context),
                    ),
                  ],
                ),
                const SizedBox(height: AtomSpace.md),
                AtomSegmented<_Tab>(
                  items: const {_Tab.active: 'Active', _Tab.pending: 'Pending', _Tab.completed: 'Completed'},
                  value: _tab,
                  onChanged: (t) => setState(() => _tab = t),
                ),
                const SizedBox(height: AtomSpace.md),
                AtomAsync<InstallmentsOverview>(
                  value: value,
                  onRetry: () => ref.invalidate(provider),
                  loading: const Column(children: [AtomSkeleton(height: 220, radius: AtomRadius.card), SizedBox(height: AtomSpace.md), AtomSkeleton(height: 160, radius: AtomRadius.card)]),
                  data: (o) => o.plans.isEmpty ? _empty(context) : _plans(context, o.plans),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _empty(BuildContext context) {
    final (title, message) = switch (_tab) {
      _Tab.active => ('No active plans', 'When a seller delivers your order, its monthly plan shows up here.'),
      _Tab.pending => ('Nothing waiting', 'Orders being verified or prepared show up here until delivery.'),
      _Tab.completed => ('No completed plans yet', 'Plans you have fully paid show up here.'),
    };
    return AtomEmptyState(
      icon: Icons.calendar_month_rounded,
      title: title,
      message: message,
      actionLabel: 'Browse products',
      actionIcon: Icons.shopping_bag_outlined,
      onAction: () => AtomNav.toTab(context, ref, AtomTab.shop),
    );
  }

  Widget _plans(BuildContext context, List<OrderCard> plans) {
    if (_tab != _Tab.active) {
      return Column(
        children: [
          for (final p in plans) ...[
            AtomCard(
              onTap: () => AtomNav.orderDetail(context, p.uuid),
              child: Row(
                children: [
                  OrderThumb(pictureUrl: p.pictureUrl),
                  const SizedBox(width: AtomSpace.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.title, style: AtomText.label),
                        Text(
                          _tab == _Tab.pending
                              ? 'Starts after delivery · ${p.months} months'
                              : 'Paid ${AtomFormat.rupees(p.paid)} · ${p.months} months',
                          style: AtomText.small,
                        ),
                      ],
                    ),
                  ),
                  AtomBadge.orderStatus(p.status),
                ],
              ),
            ),
            const SizedBox(height: AtomSpace.sm),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final p in plans) ...[
          _ActivePlanCard(plan: p),
          if (p.schedule.isNotEmpty) ...[
            const SizedBox(height: AtomSpace.md),
            Text('Payment schedule', style: AtomText.subheading.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: AtomSpace.xs),
            ScheduleList(
              rows: p.schedule,
              onOpenReceipt: (id) => AtomNav.receipt(context, id),
              onOpenOther: () => AtomNav.orderDetail(context, p.uuid),
            ),
            const SizedBox(height: AtomSpace.xs),
            Text('Tap a paid month to open its receipt.', style: AtomText.small),
          ],
          const SizedBox(height: AtomSpace.lg),
        ],
      ],
    );
  }
}

class _ActivePlanCard extends StatelessWidget {
  const _ActivePlanCard({required this.plan});

  final OrderCard plan;

  @override
  Widget build(BuildContext context) {
    final p = plan;
    final seller = p.seller;
    final next = p.nextDue;
    final progress = p.total > 0 ? (p.paid / p.total).clamp(0.0, 1.0) : 0.0;
    final muted = AtomText.small.copyWith(color: AtomColors.onDark);

    return Container(
      padding: const EdgeInsets.all(AtomSpace.md),
      decoration: BoxDecoration(color: AtomColors.ink, borderRadius: BorderRadius.circular(AtomRadius.hero)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => AtomNav.orderDetail(context, p.uuid),
            child: Row(
              children: [
                OrderThumb(pictureUrl: p.pictureUrl, dark: true),
                const SizedBox(width: AtomSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.title, style: AtomText.label.copyWith(color: AtomColors.white)),
                      Text([if (p.orderId.isNotEmpty) 'Order #${p.orderId}', '${p.months} months'].join(' · '), style: muted),
                    ],
                  ),
                ),
                AtomBadge(p.statusLabel, tone: AtomTone.dark),
              ],
            ),
          ),
          const SizedBox(height: AtomSpace.md),
          Row(
            children: [
              Expanded(child: Text('${p.paidMonths} of ${p.months} months paid', style: AtomText.label.copyWith(color: AtomColors.white))),
              Text('${AtomFormat.rupees(p.paid)} of ${AtomFormat.rupees(p.total)}', style: muted),
            ],
          ),
          const SizedBox(height: AtomSpace.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AtomRadius.pill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              color: AtomColors.amber,
              backgroundColor: AtomColors.white.withValues(alpha: 0.14),
              semanticsLabel: 'Paid',
              semanticsValue: '${(progress * 100).round()} percent',
            ),
          ),
          if (next != null) ...[
            const SizedBox(height: AtomSpace.md),
            Text(next.date == null ? 'Next due' : 'Next due · ${AtomFormat.date(next.date)}', style: muted),
            Text(AtomFormat.rupees(next.amount), style: AtomText.title.copyWith(color: AtomColors.white, fontSize: 28)),
          ],
          if (seller != null) Text('Pay your seller, ${seller.display}', style: muted),
          const SizedBox(height: AtomSpace.md),
          Row(
            children: [
              if (seller != null && seller.phone.isNotEmpty) ...[
                Expanded(
                  child: AtomButton(
                    label: 'Call seller',
                    icon: Icons.call_outlined,
                    variant: AtomButtonVariant.light,
                    size: AtomButtonSize.medium,
                    expand: true,
                    onPressed: () => atomCall(seller.phone),
                  ),
                ),
                const SizedBox(width: AtomSpace.xs),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => AtomNav.orderDetail(context, p.uuid),
                  icon: const Icon(Icons.inventory_2_outlined, size: 17),
                  label: Text('Order details', style: AtomText.button.copyWith(fontSize: 14)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AtomColors.white,
                    minimumSize: const Size.fromHeight(AtomSize.button),
                    side: BorderSide(color: AtomColors.white.withValues(alpha: 0.3)),
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
