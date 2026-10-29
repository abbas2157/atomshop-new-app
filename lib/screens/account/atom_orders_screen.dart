import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/atom_account.dart';
import '../../data/atom_http.dart';
import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../responsive/atom_responsive.dart';
import '../../shell/atom_nav.dart';
import '../../shell/atom_shell.dart';
import '../../state/atom_account_providers.dart';
import '../../utils/atom_format.dart';
import '../../widgets/atom_button.dart';
import '../../widgets/atom_page.dart';
import '../../widgets/atom_states.dart';
import '../../widgets/atom_surfaces.dart';
import '../installments/atom_orders_widgets.dart';

enum _Filter { all, active, completed, cancelled }

/// My orders (canvas: "My orders"): product and custom orders, newest first.
class AtomOrdersScreen extends ConsumerStatefulWidget {
  const AtomOrdersScreen({super.key});

  @override
  ConsumerState<AtomOrdersScreen> createState() => _AtomOrdersScreenState();
}

class _AtomOrdersScreenState extends ConsumerState<AtomOrdersScreen> {
  _Filter _filter = _Filter.all;

  /// Pages after the first, loaded with "Load more".
  final List<OrderCard> _more = [];
  int? _next;
  bool _loadingMore = false;

  /// Cancelled has no server filter; it is picked out of "all".
  String get _status => switch (_filter) {
        _Filter.active => 'active',
        _Filter.completed => 'completed',
        _ => 'all',
      };

  void _pick(_Filter f) => setState(() {
        _filter = f;
        _more.clear();
        _next = null;
      });

  Future<void> _loadMore(int page) async {
    setState(() => _loadingMore = true);
    try {
      final res = await ref.read(atomAccountApiProvider).orders(status: _status, page: page);
      if (!mounted) return;
      setState(() {
        _more.addAll(res.orders);
        _next = res.nextPage ?? -1;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(atomMessage(e))));
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _refresh() async {
    _pick(_filter);
    ref.invalidate(ordersProvider(_status));
    await ref.read(ordersProvider(_status).future).catchError((_) => const OrdersPage([], null));
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(ordersProvider(_status));
    final gutter = context.atomGutter;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: AtomPageWidth(
          child: Column(
            children: [
              const AtomTopBar(title: 'My orders'),
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  children: [
                    for (final f in _Filter.values) ...[
                      AtomChoiceChip(
                        label: switch (f) {
                          _Filter.all => 'All',
                          _Filter.active => 'Active',
                          _Filter.completed => 'Completed',
                          _Filter.cancelled => 'Cancelled',
                        },
                        dark: true,
                        selected: f == _filter,
                        onTap: () => _pick(f),
                      ),
                      const SizedBox(width: AtomSpace.xs),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AtomSpace.sm),
              Expanded(
                child: RefreshIndicator(
                  color: AtomColors.primary,
                  onRefresh: _refresh,
                  child: AtomAsync<OrdersPage>(
                    value: value,
                    onRetry: () => ref.invalidate(ordersProvider(_status)),
                    loading: ListView(
                      padding: EdgeInsets.symmetric(horizontal: gutter),
                      children: const [AtomSkeleton(height: 110, radius: AtomRadius.card), SizedBox(height: AtomSpace.sm), AtomSkeleton(height: 110, radius: AtomRadius.card)],
                    ),
                    data: (page) {
                      var orders = [...page.orders, ..._more];
                      if (_filter == _Filter.cancelled) orders = orders.where((o) => o.status == 'Cancelled').toList();
                      final next = _next == null ? page.nextPage : (_next! < 0 ? null : _next);

                      if (orders.isEmpty && next == null) {
                        return ListView(
                          children: [
                            AtomEmptyState(
                              icon: Icons.inventory_2_outlined,
                              title: _filter == _Filter.all ? 'No orders yet' : 'Nothing here',
                              message: 'Orders you place in the app or on atomshop.pk show up here.',
                              actionLabel: 'Browse products',
                              actionIcon: Icons.shopping_bag_outlined,
                              onAction: () => AtomNav.toTab(context, ref, AtomTab.shop),
                            ),
                          ],
                        );
                      }

                      return ListView.separated(
                        padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AtomSpace.xl),
                        itemCount: orders.length + (next == null ? 0 : 1),
                        separatorBuilder: (_, _) => const SizedBox(height: AtomSpace.sm),
                        itemBuilder: (context, i) {
                          if (i == orders.length) {
                            return Center(
                              child: AtomButton(
                                label: 'Load more',
                                icon: Icons.expand_more_rounded,
                                variant: AtomButtonVariant.secondary,
                                size: AtomButtonSize.medium,
                                loading: _loadingMore,
                                onPressed: _loadingMore ? null : () => _loadMore(next!),
                              ),
                            );
                          }
                          return _OrderTile(order: orders[i]);
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});

  final OrderCard order;

  @override
  Widget build(BuildContext context) {
    final o = order;
    final plan = switch (o.status) {
      'Cancelled' => 'Cancelled before delivery',
      _ when o.monthly == null => 'Paid in full',
      _ => '${o.months} months · ${AtomFormat.rupees(o.monthly)}/mo',
    };
    final id = o.orderId.isEmpty ? '' : '#${o.orderId}';
    return AtomCard(
      onTap: () => AtomNav.orderDetail(context, o.uuid),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OrderThumb(pictureUrl: o.pictureUrl),
              const SizedBox(width: AtomSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: AtomText.label),
                    Text([id, if (o.createdAt != null) AtomFormat.date(o.createdAt)].where((s) => s.isNotEmpty).join(' · '), style: AtomText.small),
                  ],
                ),
              ),
              const SizedBox(width: AtomSpace.xs),
              AtomBadge.orderStatus(o.status),
            ],
          ),
          const SizedBox(height: AtomSpace.sm),
          Row(
            children: [
              Expanded(child: Text(plan, style: AtomText.body.copyWith(fontSize: 13))),
              Text(AtomFormat.rupees(o.status == 'Cancelled' ? 0 : o.total), style: AtomText.label),
            ],
          ),
          if (o.isCustom || o.isAtompay) ...[
            const SizedBox(height: AtomSpace.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: AtomBadge(o.isAtompay ? 'AtomPay' : 'Custom order', tone: o.isAtompay ? AtomTone.green : AtomTone.violet),
            ),
          ],
        ],
      ),
    );
  }
}
