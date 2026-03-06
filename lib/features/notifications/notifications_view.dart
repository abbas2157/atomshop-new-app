import 'package:atompro/core/routes/app_navigator.dart';
import 'package:atompro/core/style/color_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Notification type ──────────────────────────────────────────────────────
enum NotifType { order, payment, promo, system }

// ── Model ──────────────────────────────────────────────────────────────────
class NotificationItem {
  final String id;
  final NotifType type;
  final String title;
  final String body;
  final DateTime time;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.time,
    this.isRead = false,
  });
}

// ── Dummy data ─────────────────────────────────────────────────────────────
final _dummyNotifications = <NotificationItem>[
  NotificationItem(
    id: '1',
    type: NotifType.order,
    title: 'Order Approved!',
    body:
        'Your order #36E77B for "Samsung Galaxy S24" has been approved. Supplier details are now available.',
    time: DateTime.now().subtract(const Duration(minutes: 12)),
    isRead: false,
  ),
  NotificationItem(
    id: '2',
    type: NotifType.payment,
    title: 'Installment Due Tomorrow',
    body:
        'Your 3rd installment of PKR 18,708 for order #36E77B is due tomorrow. Please ensure timely payment.',
    time: DateTime.now().subtract(const Duration(hours: 2)),
    isRead: false,
  ),
  NotificationItem(
    id: '3',
    type: NotifType.promo,
    title: 'Exclusive Deal — Up to 20% Off!',
    body:
        'This week only: save big on electronics and home appliances. Browse our latest offers now.',
    time: DateTime.now().subtract(const Duration(hours: 5)),
    isRead: true,
  ),
  NotificationItem(
    id: '4',
    type: NotifType.system,
    title: 'Profile Verification Pending',
    body:
        'Your account verification is still incomplete. Submit your CNIC to unlock all features.',
    time: DateTime.now().subtract(const Duration(hours: 11)),
    isRead: false,
  ),
  NotificationItem(
    id: '5',
    type: NotifType.payment,
    title: 'Payment Received',
    body:
        'We\'ve received your installment payment of PKR 18,708 for order #36E77B. Thank you!',
    time: DateTime.now().subtract(const Duration(days: 1)),
    isRead: true,
  ),
  NotificationItem(
    id: '6',
    type: NotifType.order,
    title: 'Order Submitted',
    body:
        'Your custom order for "HP Laptop Core i7" has been submitted and is under review.',
    time: DateTime.now().subtract(const Duration(days: 2)),
    isRead: true,
  ),
  NotificationItem(
    id: '7',
    type: NotifType.promo,
    title: 'New Arrivals This Week',
    body:
        'Fresh products just added to our catalogue. Check out the latest smartphones and appliances.',
    time: DateTime.now().subtract(const Duration(days: 3)),
    isRead: true,
  ),
  NotificationItem(
    id: '8',
    type: NotifType.system,
    title: 'Password Changed Successfully',
    body:
        'Your account password was updated. If you did not make this change, contact support immediately.',
    time: DateTime.now().subtract(const Duration(days: 5)),
    isRead: true,
  ),
];

// ══════════════════════════════════════════════════════════════════════════════
//  SCREEN
// ══════════════════════════════════════════════════════════════════════════════
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late final List<NotificationItem> _notifications;
  String _filter = 'All'; // All | Unread | Order | Payment | Promo | System

  late final AnimationController _entryCtrl;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _notifications = List.from(_dummyNotifications);
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeIn = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  // ── Filtering ──────────────────────────────────────────────────────────────
  List<NotificationItem> get _filtered {
    switch (_filter) {
      case 'Unread':
        return _notifications.where((n) => !n.isRead).toList();
      case 'Order':
        return _notifications.where((n) => n.type == NotifType.order).toList();
      case 'Payment':
        return _notifications
            .where((n) => n.type == NotifType.payment)
            .toList();
      case 'Promo':
        return _notifications.where((n) => n.type == NotifType.promo).toList();
      case 'System':
        return _notifications.where((n) => n.type == NotifType.system).toList();
      default:
        return _notifications;
    }
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  void _markAllRead() {
    HapticFeedback.lightImpact();
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });
  }

  void _toggleRead(NotificationItem item) {
    HapticFeedback.selectionClick();
    setState(() => item.isRead = !item.isRead);
  }

  // ── Group by date ──────────────────────────────────────────────────────────
  Map<String, List<NotificationItem>> get _grouped {
    final map = <String, List<NotificationItem>>{};
    for (final n in _filtered) {
      final label = _dateLabel(n.time);
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

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final grouped = _grouped;
    final groupKeys = grouped.keys.toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F5FB),
        body: FadeTransition(
          opacity: _fadeIn,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),

              if (_filtered.isEmpty)
                SliverFillRemaining(hasScrollBody: false, child: _buildEmpty())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((ctx, i) {
                      // Build group headers + cards
                      final items = <Widget>[];
                      for (final key in groupKeys) {
                        items.add(_GroupHeader(label: key));
                        for (final n in grouped[key]!) {
                          items.add(
                            _NotifCard(item: n, onTap: () => _toggleRead(n)),
                          );
                          items.add(const SizedBox(height: 10));
                        }
                      }
                      return i < items.length
                          ? items[i]
                          : const SizedBox.shrink();
                    }, childCount: _buildFlatList().length),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Flatten grouped items into a single list for SliverChildBuilderDelegate
  List<Widget> _buildFlatList() {
    final grouped = _grouped;
    final items = <Widget>[];
    for (final key in grouped.keys) {
      items.add(_GroupHeader(label: key));
      for (final n in grouped[key]!) {
        items.add(_NotifCard(item: n, onTap: () => _toggleRead(n)));
        items.add(const SizedBox(height: 10));
      }
    }
    return items;
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              children: [
                GestureDetector(
                  onTap: () => AppNavigator.getBack(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 17,
                      color: ColorPalette.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: ColorPalette.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                // Unread badge
                if (_unreadCount > 0)
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
                      '$_unreadCount Unread',
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

            // Mark all read row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filtered.length} notification${_filtered.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: ColorPalette.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_unreadCount > 0)
                  GestureDetector(
                    onTap: _markAllRead,
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

            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    [
                      'All',
                      'Unread',
                      'Order',
                      'Payment',
                      'Promo',
                      'System',
                    ].map((f) {
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
                                  : Colors.white,
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
          const Text(
            'All caught up!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: ColorPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'No notifications here yet.',
            style: TextStyle(fontSize: 13, color: ColorPalette.textSecondary),
          ),
        ],
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
            style: const TextStyle(
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
  final NotificationItem item;
  final VoidCallback onTap;
  const _NotifCard({required this.item, required this.onTap});

  @override
  State<_NotifCard> createState() => _NotifCardState();
}

class _NotifCardState extends State<_NotifCard> {
  bool _pressed = false;

  // ── Type config ────────────────────────────────────────────────────────────
  _NotifConfig get _config {
    switch (widget.item.type) {
      case NotifType.order:
        return _NotifConfig(
          icon: Icons.inventory_2_outlined,
          color: ColorPalette.secondary,
          label: 'Order',
        );
      case NotifType.payment:
        return _NotifConfig(
          icon: Icons.payments_outlined,
          color: const Color(0xFF2ECC71),
          label: 'Payment',
        );
      case NotifType.promo:
        return _NotifConfig(
          icon: Icons.local_offer_outlined,
          color: const Color(0xFFE67E22),
          label: 'Offer',
        );
      case NotifType.system:
        return _NotifConfig(
          icon: Icons.info_outline_rounded,
          color: const Color(0xFF8E44AD),
          label: 'System',
        );
    }
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
    final item = widget.item;
    final isUnread = !item.isRead;

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
            color: isUnread ? Colors.white : Colors.white.withOpacity(0.6),
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
                // ── Icon ──────────────────────────────────────────────
                Container(
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
                ),
                const SizedBox(width: 12),

                // ── Content ───────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type label + time
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
                            _timeAgo(item.time),
                            style: TextStyle(
                              fontSize: 11,
                              color: ColorPalette.textSecondary.withOpacity(
                                0.7,
                              ),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          // Unread dot
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
                      // Title
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: isUnread
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: isUnread
                              ? ColorPalette.textPrimary
                              : ColorPalette.textSecondary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Body
                      Text(
                        item.body,
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
}

// ── Simple config helper ───────────────────────────────────────────────────
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
