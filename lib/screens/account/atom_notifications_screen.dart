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
import '../../widgets/atom_page.dart';
import '../../widgets/atom_states.dart';

/// Notifications (canvas: "Notifications"): the account's inbox, newest
/// first, loaded a page at a time.
class AtomNotificationsScreen extends ConsumerStatefulWidget {
  const AtomNotificationsScreen({super.key});

  @override
  ConsumerState<AtomNotificationsScreen> createState() => _AtomNotificationsScreenState();
}

class _AtomNotificationsScreenState extends ConsumerState<AtomNotificationsScreen> {
  final List<AppNotification> _items = [];
  int? _nextPage = 1;
  int _unread = 0;
  bool _loading = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading || (!reset && _nextPage == null)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await ref.read(atomAccountApiProvider).notifications(page: reset ? 1 : _nextPage!);
      if (!mounted) return;
      setState(() {
        if (reset) _items.clear();
        _items.addAll(page.items);
        _nextPage = page.nextPage;
        _unread = page.unread;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  void _refreshCounts() => ref
    ..invalidate(unreadNotificationsProvider)
    ..invalidate(accountSummaryProvider);

  Future<void> _markAll() async {
    try {
      await ref.read(atomAccountApiProvider).markAllNotificationsRead();
      if (!mounted) return;
      setState(() {
        for (var i = 0; i < _items.length; i++) {
          _items[i] = _items[i].markedRead();
        }
        _unread = 0;
      });
      _refreshCounts();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(atomMessage(e))));
    }
  }

  Future<void> _open(int index) async {
    final n = _items[index];
    if (!n.read) {
      setState(() {
        _items[index] = n.markedRead();
        _unread = (_unread - 1).clamp(0, 1 << 30);
      });
      // Marking is best effort; the inbox is right again on the next load.
      ref.read(atomAccountApiProvider).markNotificationRead(n.id).then((_) => _refreshCounts()).ignore();
    }
    if (!mounted) return;
    switch (n.screen.isNotEmpty ? n.screen : n.type) {
      case 'instalments' || 'installments' || 'instalment_paid':
        AtomNav.toTab(context, ref, AtomTab.installments);
      case 'profile' || 'account_verified':
        AtomNav.profile(context);
      case 'orders' || 'order_status' || 'deal_closed' || 'order':
        AtomNav.orders(context);
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gutter = context.atomGutter;
    final today = DateTime.now();
    bool isToday(DateTime? d) => d != null && d.year == today.year && d.month == today.month && d.day == today.day;
    final todays = _items.where((n) => isToday(n.createdAt?.toLocal())).length;

    Widget body;
    if (_items.isEmpty && _loading) {
      body = ListView(
        padding: EdgeInsets.symmetric(horizontal: gutter, vertical: AtomSpace.sm),
        children: [
          for (var i = 0; i < 5; i++)
            const Padding(padding: EdgeInsets.only(bottom: AtomSpace.sm), child: AtomSkeleton(height: 76, radius: AtomRadius.card)),
        ],
      );
    } else if (_items.isEmpty && _error != null) {
      body = Center(child: AtomErrorState(message: atomMessage(_error!), onRetry: () => _load(reset: true)));
    } else if (_items.isEmpty) {
      body = ListView(children: const [
        SizedBox(height: AtomSpace.xl),
        AtomEmptyState(
          icon: Icons.notifications_none_rounded,
          title: 'No notifications yet',
          message: 'Order updates, due dates and payment receipts show up here.',
        ),
      ]);
    } else {
      // Rows plus their group headings, built lazily.
      final rows = <Object>[
        if (todays > 0) 'Today',
        for (var i = 0; i < _items.length; i++) ...[
          if (i == todays) 'Earlier',
          i,
        ],
      ];
      body = NotificationListener<ScrollNotification>(
        onNotification: (s) {
          if (s.metrics.extentAfter < 400) _load();
          return false;
        },
        child: ListView.builder(
          padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AtomSpace.xl),
          itemCount: rows.length + (_nextPage != null ? 1 : 0),
          itemBuilder: (context, i) {
            if (i == rows.length) {
              return Padding(
                padding: const EdgeInsets.all(AtomSpace.md),
                child: Center(
                  child: _error != null
                      ? TextButton.icon(onPressed: _load, icon: const Icon(Icons.refresh_rounded), label: const Text('Load more'))
                      : const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              );
            }
            final row = rows[i];
            if (row is String) {
              return Padding(
                padding: const EdgeInsets.only(top: AtomSpace.md, bottom: AtomSpace.xs),
                child: Text(row, style: AtomText.subheading.copyWith(fontWeight: FontWeight.w800)),
              );
            }
            final index = row as int;
            return Padding(
              padding: const EdgeInsets.only(bottom: AtomSpace.xs),
              child: _NotificationTile(n: _items[index], onTap: () => _open(index)),
            );
          },
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: AtomPageWidth(
          child: Column(
            children: [
              AtomTopBar(
                title: 'Notifications',
                trailing: _unread > 0
                    ? TextButton.icon(
                        onPressed: _markAll,
                        icon: const Icon(Icons.done_all_rounded, size: 18),
                        label: Text('Mark all read', style: AtomText.label.copyWith(color: AtomColors.primary, fontSize: 13)),
                        style: TextButton.styleFrom(foregroundColor: AtomColors.primary, minimumSize: const Size(44, 44)),
                      )
                    : null,
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AtomColors.primary,
                  onRefresh: () => _load(reset: true),
                  child: body,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.n, required this.onTap});

  final AppNotification n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, bg, fg) = switch (n.type) {
      'instalment_paid' => (Icons.check_rounded, AtomColors.greenSoft, AtomColors.green),
      'order_status' => (Icons.inventory_2_outlined, AtomColors.primarySoft, AtomColors.primary),
      'deal_closed' => (Icons.handshake_outlined, AtomColors.violetSoft, AtomColors.violet),
      'account_verified' => (Icons.verified_user_outlined, AtomColors.greenSoft, AtomColors.green),
      'instalment_due' || 'installment_due' => (Icons.calendar_month_rounded, AtomColors.amberSoft, AtomColors.amberInk),
      _ => (Icons.notifications_none_rounded, AtomColors.surface, AtomColors.body),
    };
    final when = n.createdAt?.toLocal();
    final now = DateTime.now();
    final time = when == null
        ? ''
        : (when.year == now.year && when.month == now.month && when.day == now.day)
            ? TimeOfDay.fromDateTime(when).format(context)
            : AtomFormat.date(when);

    return Semantics(
      button: true,
      label: '${n.read ? '' : 'Unread. '}${n.title}. ${n.body}. $time',
      excludeSemantics: true,
      child: Material(
        color: n.read ? AtomColors.white : AtomColors.primarySoft.withValues(alpha: 0.55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AtomRadius.card), side: const BorderSide(color: AtomColors.line)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, size: 20, color: fg),
                ),
                const SizedBox(width: AtomSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n.title, style: AtomText.label),
                      if (n.body.isNotEmpty) Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: AtomText.body.copyWith(fontSize: 13)),
                      if (time.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(time, style: AtomText.small),
                      ],
                    ],
                  ),
                ),
                if (!n.read)
                  Container(
                    width: 9,
                    height: 9,
                    margin: const EdgeInsets.only(left: AtomSpace.xs, top: 4),
                    decoration: const BoxDecoration(color: AtomColors.primary, shape: BoxShape.circle),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
