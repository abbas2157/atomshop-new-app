import 'package:atompro/features/customer/notifications/model/app_notification_model.dart';
import 'package:atompro/features/seller/core/design/design.dart';
import 'package:atompro/features/seller/core/widgets/widgets.dart';
import 'package:atompro/features/seller/custom_orders/view/seller_custom_orders_screen.dart';
import 'package:atompro/features/seller/leads/view/seller_leads_screen.dart';
import 'package:atompro/features/seller/notifications/viewmodel/seller_notifications_notifier.dart';
import 'package:atompro/features/seller/profile/view/seller_profile_screen.dart';
import 'package:atompro/features/seller/subscription/view/seller_subscription_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SellerNotificationsScreen extends ConsumerStatefulWidget {
  const SellerNotificationsScreen({super.key});

  @override
  ConsumerState<SellerNotificationsScreen> createState() =>
      _SellerNotificationsScreenState();
}

class _SellerNotificationsScreenState
    extends ConsumerState<SellerNotificationsScreen> {
  final _scroll = ScrollController();
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sellerNotificationsProvider.notifier).load();
    });
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 250) {
      ref.read(sellerNotificationsProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  // ── Filtering ──────────────────────────────────────────────────────────────
  List<AppNotification> _applyFilter(List<AppNotification> items) {
    switch (_filter) {
      case 'Unread':
        return items.where((n) => !n.isRead).toList();
      case 'Leads':
        return items.where((n) => n.type == 'new_lead').toList();
      case 'Orders':
        return items.where((n) => n.type == 'new_custom_order').toList();
      case 'Payments':
        return items
            .where((n) => n.type == 'payment_confirmed')
            .toList();
      case 'Account':
        return items
            .where((n) =>
                n.type == 'account_verified' ||
                n.type == 'subscription_activated')
            .toList();
      case 'Promo':
        return items.where((n) => n.type == 'broadcast').toList();
      default:
        return items;
    }
  }

  // ── Group by date ──────────────────────────────────────────────────────────
  Map<String, List<AppNotification>> _grouped(List<AppNotification> items) {
    final map = <String, List<AppNotification>>{};
    for (final n in items) {
      final label = _dateLabel(n.createdAtDate);
      map.putIfAbsent(label, () => []).add(n);
    }
    return map;
  }

  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return 'This Week';
    return 'Older';
  }

  List<Widget> _buildFlatList(
      List<AppNotification> items, SellerColors c, SellerTextTheme text) {
    final grouped = _grouped(items);
    final widgets = <Widget>[];
    for (final key in grouped.keys) {
      widgets.add(_GroupHeader(label: key, c: c, text: text));
      for (final n in grouped[key]!) {
        widgets.add(_NotifCard(
          notification: n,
          onTap: () => _handleTap(n),
          c: c,
          text: text,
        ));
        widgets.add(const SizedBox(height: 10));
      }
    }
    return widgets;
  }

  void _handleTap(AppNotification n) {
    HapticFeedback.selectionClick();
    if (!n.isRead) {
      ref.read(sellerNotificationsProvider.notifier).markRead(n.id);
    }
    _navigate(n);
  }

  void _navigate(AppNotification n) {
    switch (n.screen) {
      case 'leads':
        context.pushSeller(const SellerLeadsScreen());
      case 'custom_orders':
        context.pushSeller(const SellerCustomOrdersScreen());
      case 'subscription':
        context.pushSeller(SellerSubscriptionScreen(locked: false));
      case 'profile':
        context.pushSeller(const SellerProfileScreen());
      default:
        break;
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final state = ref.watch(sellerNotificationsProvider);
    final filtered = _applyFilter(state.items);
    final flat = _buildFlatList(filtered, c, text);

    return Scaffold(
      backgroundColor: c.canvas,
      body: Column(
        children: [
          SellerGradientHeader(
            title: 'Notifications',
            subtitle: state.unreadCount > 0
                ? '${state.unreadCount} unread'
                : 'All caught up',
            actions: [
              if (state.unreadCount > 0)
                SellerHeaderPill(
                  icon: Icons.done_all_rounded,
                  label: 'Mark all read',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref
                        .read(sellerNotificationsProvider.notifier)
                        .markAllRead();
                  },
                ),
              const SellerHeaderProfileButton(),
            ],
          ),
          _FilterRow(
            selected: _filter,
            c: c,
            text: text,
            onSelect: (f) => setState(() => _filter = f),
          ),
          Expanded(
            child: state.isLoading
                ? const SellerListSkeleton()
                : state.error != null && state.items.isEmpty
                    ? _ErrorState(
                        message: state.error!,
                        c: c,
                        text: text,
                        onRetry: () => ref
                            .read(sellerNotificationsProvider.notifier)
                            .load(),
                      )
                    : filtered.isEmpty
                        ? _EmptyState(c: c, text: text)
                        : ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                            itemCount: flat.length +
                                (state.isLoadingMore ? 1 : 0),
                            itemBuilder: (ctx, i) {
                              if (i == flat.length) {
                                return Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: c.accent,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return flat[i];
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

// ── Filter row ─────────────────────────────────────────────────────────────
class _FilterRow extends StatelessWidget {
  final String selected;
  final SellerColors c;
  final SellerTextTheme text;
  final ValueChanged<String> onSelect;

  const _FilterRow({
    required this.selected,
    required this.c,
    required this.text,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final filters = ['All', 'Unread', 'Leads', 'Orders', 'Payments', 'Account', 'Promo'];
    return Container(
      color: c.canvas,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final active = selected == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelect(f);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: active ? c.accent : c.surface,
                    borderRadius: AppRadius.brPill,
                    border: Border.all(
                      color: active ? c.accent : c.border,
                    ),
                  ),
                  child: Text(
                    f,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: active ? c.onAccent : c.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Group header ────────────────────────────────────────────────────────────
class _GroupHeader extends StatelessWidget {
  final String label;
  final SellerColors c;
  final SellerTextTheme text;

  const _GroupHeader({
    required this.label,
    required this.c,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
          Text(label, style: text.labelSm.copyWith(color: c.textTertiary)),
          const SizedBox(width: 10),
          Expanded(child: Divider(color: c.border, thickness: 1)),
        ],
      ),
    );
  }
}

// ── Notification card ───────────────────────────────────────────────────────
class _NotifCard extends StatefulWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final SellerColors c;
  final SellerTextTheme text;

  const _NotifCard({
    required this.notification,
    required this.onTap,
    required this.c,
    required this.text,
  });

  @override
  State<_NotifCard> createState() => _NotifCardState();
}

class _NotifCardState extends State<_NotifCard> {
  bool _pressed = false;

  _NotifConfig _configForType(String type, SellerColors c) {
    return switch (type) {
      'new_lead' => _NotifConfig(
          icon: Icons.person_add_outlined,
          color: c.accent,
          label: 'Lead',
        ),
      'new_custom_order' => _NotifConfig(
          icon: Icons.receipt_long_rounded,
          color: c.accent,
          label: 'Order',
        ),
      'subscription_activated' => _NotifConfig(
          icon: Icons.verified_outlined,
          color: const Color(0xFF2ECC71),
          label: 'Subscription',
        ),
      'payment_confirmed' => _NotifConfig(
          icon: Icons.payments_outlined,
          color: const Color(0xFF2ECC71),
          label: 'Payment',
        ),
      'account_verified' => _NotifConfig(
          icon: Icons.verified_user_outlined,
          color: const Color(0xFF8E44AD),
          label: 'Account',
        ),
      'broadcast' => _NotifConfig(
          icon: Icons.campaign_outlined,
          color: const Color(0xFFE67E22),
          label: 'Broadcast',
        ),
      _ => _NotifConfig(
          icon: Icons.notifications_outlined,
          color: c.accent,
          label: 'Alert',
        ),
    };
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final text = widget.text;
    final n = widget.notification;
    final cfg = _configForType(n.type, c);
    final isUnread = !n.isRead;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isUnread ? c.surface : c.surface.withValues(alpha: 0.6),
            borderRadius: AppRadius.brMd,
            border: Border.all(
              color: isUnread
                  ? cfg.color.withValues(alpha: 0.2)
                  : c.border.withValues(alpha: 0.5),
              width: isUnread ? 1.5 : 1,
            ),
            boxShadow: isUnread ? c.floatingShadow : [],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Icon ──────────────────────────────────────────────
              n.image != null && n.image!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: AppRadius.brSm,
                      child: Image.network(
                        n.image!,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            _iconWidget(cfg, isUnread, c),
                      ),
                    )
                  : _iconWidget(cfg, isUnread, c),
              const Gap.h(AppSpace.sm),

              // ── Content ───────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: cfg.color.withValues(alpha: 0.1),
                            borderRadius: AppRadius.brSm,
                          ),
                          child: Text(
                            cfg.label,
                            style: text.labelSm.copyWith(color: cfg.color),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _timeAgo(n.createdAtDate),
                          style: text.bodySm.copyWith(color: c.textTertiary),
                        ),
                        if (isUnread) ...[
                          const Gap.h(AppSpace.xs),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: cfg.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Gap.v(AppSpace.xs),
                    Text(
                      n.title,
                      style: isUnread ? text.titleSm : text.bodySm,
                    ),
                    const Gap.v(2),
                    Text(
                      n.body,
                      style: text.bodySm.copyWith(color: c.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconWidget(_NotifConfig cfg, bool isUnread, SellerColors c) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: cfg.color.withValues(alpha: isUnread ? 0.12 : 0.07),
        borderRadius: AppRadius.brSm,
      ),
      child: Icon(
        cfg.icon,
        size: 21,
        color: cfg.color.withValues(alpha: isUnread ? 1.0 : 0.5),
      ),
    );
  }
}

class _NotifConfig {
  final IconData icon;
  final Color color;
  final String label;
  const _NotifConfig(
      {required this.icon, required this.color, required this.label});
}

// ── Empty state ─────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final SellerColors c;
  final SellerTextTheme text;
  const _EmptyState({required this.c, required this.text});

  @override
  Widget build(BuildContext context) {
    return SellerEmptyState(
      icon: Icons.notifications_none_rounded,
      title: 'All caught up!',
      message: 'No notifications here yet.',
    );
  }
}

// ── Error state ─────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  final SellerColors c;
  final SellerTextTheme text;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.c,
    required this.text,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return SellerErrorState(message: message, onRetry: onRetry);
  }
}
