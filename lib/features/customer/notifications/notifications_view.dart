import 'package:atompro/core/routes/app_navigator.dart';
import 'package:atompro/core/routes/app_route_constants.dart';
import 'package:atompro/core/style/color_palette.dart';
import 'package:atompro/features/customer/notifications/model/app_notification_model.dart';
import 'package:atompro/features/customer/notifications/viewmodel/customer_notifications_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  SCREEN
// ══════════════════════════════════════════════════════════════════════════════
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  final _scroll = ScrollController();
  String _filter = 'All';

  late final AnimationController _entryCtrl;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeIn = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entryCtrl.forward();

    _scroll.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerNotificationsProvider.notifier).load();
    });
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 250) {
      ref.read(customerNotificationsProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ── Filtering ──────────────────────────────────────────────────────────────
  List<AppNotification> _applyFilter(List<AppNotification> items) {
    switch (_filter) {
      case 'Unread':
        return items.where((n) => !n.isRead).toList();
      case 'Orders':
        return items
            .where((n) => _filterForType(n.type) == 'Orders')
            .toList();
      case 'Payments':
        return items
            .where((n) => _filterForType(n.type) == 'Payments')
            .toList();
      case 'Account':
        return items
            .where((n) => _filterForType(n.type) == 'Account')
            .toList();
      case 'Promo':
        return items
            .where((n) => _filterForType(n.type) == 'Promo')
            .toList();
      default:
        return items;
    }
  }

  String _filterForType(String type) {
    return switch (type) {
      'order_status' || 'deal_closed' => 'Orders',
      'instalment_paid' => 'Payments',
      'account_verified' => 'Account',
      'broadcast' => 'Promo',
      _ => 'Other',
    };
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

  List<Widget> _buildFlatList(List<AppNotification> items) {
    final grouped = _grouped(items);
    final widgets = <Widget>[];
    for (final key in grouped.keys) {
      widgets.add(_GroupHeader(label: key));
      for (final n in grouped[key]!) {
        widgets.add(_NotifCard(
          notification: n,
          onTap: () => _handleTap(n),
        ));
        widgets.add(const SizedBox(height: 10));
      }
    }
    return widgets;
  }

  void _handleTap(AppNotification n) {
    HapticFeedback.selectionClick();
    if (!n.isRead) {
      ref.read(customerNotificationsProvider.notifier).markRead(n.id);
    }
    _navigate(n);
  }

  void _navigate(AppNotification n) {
    switch (n.screen) {
      case 'orders':
        AppNavigator.goToMyOrders();
      case 'instalments':
        AppNavigator.goToMyOrders();
      case 'profile':
        AppNavigator.pushNamed(AppRoutes.profile);
      default:
        break;
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerNotificationsProvider);
    final filtered = _applyFilter(state.items);
    final flat = _buildFlatList(filtered);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: ColorPalette.background,
        body: FadeTransition(
          opacity: _fadeIn,
          child: CustomScrollView(
            controller: _scroll,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(state, filtered),
              ),

              if (state.isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.error != null && state.items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildError(state.error!),
                )
              else if (filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmpty(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => flat[i],
                      childCount: flat.length,
                    ),
                  ),
                ),

              if (state.isLoadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(NotificationsState state, List<AppNotification> filtered) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => AppNavigator.getBack(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: ColorPalette.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 17,
                      color: ColorPalette.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: ColorPalette.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                if (state.unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: ColorPalette.secondaryGradient,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${state.unreadCount} Unread',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filtered.length} notification${filtered.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: ColorPalette.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (state.unreadCount > 0)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ref
                          .read(customerNotificationsProvider.notifier)
                          .markAllRead();
                    },
                    child: Row(
                      children: [
                        Icon(
                          Icons.done_all_rounded,
                          size: 15,
                          color: ColorPalette.secondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Mark all as read',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: ColorPalette.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Unread', 'Orders', 'Payments', 'Account', 'Promo']
                    .map((f) {
                  final active = _filter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _filter = f);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? ColorPalette.secondary
                              : ColorPalette.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: active
                                ? ColorPalette.secondary
                                : ColorPalette.border,
                          ),
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                    color: ColorPalette.secondary
                                        .withOpacity(0.25),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : [],
                        ),
                        child: Text(
                          f,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: active
                                ? Colors.white
                                : ColorPalette.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFECF0FF),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 34,
              color: ColorPalette.secondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'All caught up!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: ColorPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No notifications here yet.',
            style: TextStyle(fontSize: 13, color: ColorPalette.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 40, color: ColorPalette.textSecondary),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: ColorPalette.textSecondary),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () =>
                  ref.read(customerNotificationsProvider.notifier).load(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: ColorPalette.secondary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  GROUP HEADER
// ══════════════════════════════════════════════════════════════════════════════
class _GroupHeader extends StatelessWidget {
  final String label;
  const _GroupHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 10),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: ColorPalette.textSecondary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Divider(color: ColorPalette.border, thickness: 1)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  NOTIFICATION CARD
// ══════════════════════════════════════════════════════════════════════════════
class _NotifCard extends StatefulWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  const _NotifCard({required this.notification, required this.onTap});

  @override
  State<_NotifCard> createState() => _NotifCardState();
}

class _NotifCardState extends State<_NotifCard> {
  bool _pressed = false;

  _NotifConfig get _config {
    return switch (widget.notification.type) {
      'order_status' || 'deal_closed' => _NotifConfig(
          icon: Icons.local_shipping_outlined,
          color: ColorPalette.secondary,
          label: 'Order',
        ),
      'instalment_paid' => _NotifConfig(
          icon: Icons.receipt_outlined,
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
          label: 'Promo',
        ),
      _ => _NotifConfig(
          icon: Icons.notifications_outlined,
          color: ColorPalette.secondary,
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
    final cfg = _config;
    final n = widget.notification;
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
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: isUnread
                ? ColorPalette.surface
                : ColorPalette.surface.withOpacity(0.6),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isUnread
                  ? cfg.color.withOpacity(0.2)
                  : ColorPalette.border.withOpacity(0.5),
              width: isUnread ? 1.5 : 1,
            ),
            boxShadow: isUnread
                ? [
                    BoxShadow(
                      color: cfg.color.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Icon / Image ───────────────────────────────────
                n.image != null && n.image!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Image.network(
                          n.image!,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _iconWidget(cfg, isUnread),
                        ),
                      )
                    : _iconWidget(cfg, isUnread),
                const SizedBox(width: 12),

                // ── Content ───────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: cfg.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              cfg.label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: cfg.color,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _timeAgo(n.createdAtDate),
                            style: TextStyle(
                              fontSize: 11,
                              color: ColorPalette.textSecondary.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (isUnread) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: cfg.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        n.title,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight:
                              isUnread ? FontWeight.w700 : FontWeight.w600,
                          color: isUnread
                              ? ColorPalette.textPrimary
                              : ColorPalette.textSecondary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        n.body,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: ColorPalette.textSecondary.withOpacity(
                            isUnread ? 0.85 : 0.6,
                          ),
                          height: 1.5,
                        ),
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
      ),
    );
  }

  Widget _iconWidget(_NotifConfig cfg, bool isUnread) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: cfg.color.withOpacity(isUnread ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(
        cfg.icon,
        size: 21,
        color: cfg.color.withOpacity(isUnread ? 1.0 : 0.5),
      ),
    );
  }
}

class _NotifConfig {
  final IconData icon;
  final Color color;
  final String label;
  const _NotifConfig({
    required this.icon,
    required this.color,
    required this.label,
  });
}
