// ============================================================
//  seller_dashboard_screen.dart  –  v2  (Compact + Tabbed)
//  Problem solved: users no longer scroll through a single
//  giant list. Content is split across 4 focused tabs so
//  every key metric is visible within the first screen.
//  Business logic: 100 % unchanged.
// ============================================================

import 'package:atompro/core/routes/app_navigator.dart';
import 'package:atompro/features/seller/auth/viewmodel/seller_auth_viewmodel.dart';
import 'package:atompro/features/seller/dashboard/model/seller_dashboard_model.dart';
import 'package:atompro/features/seller/dashboard/viewmodel/seller_dashboard_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Design Tokens ──────────────────────────────────────────
abstract final class _T {
  static const accent = Color(0xFF3B5BDB);
  static const accentSurf = Color(0xFFEBEFFE);
  static const emerald = Color(0xFF10B981);
  static const emeraldSurf = Color(0xFFD1FAE5);
  static const amber = Color(0xFFF59E0B);
  static const amberSurf = Color(0xFFFEF3C7);
  static const rose = Color(0xFFEF4444);
  static const roseSurf = Color(0xFFFEE2E2);
  static const violet = Color(0xFF8B5CF6);
  static const violetSurf = Color(0xFFEDE9FE);

  static const canvas = Color(0xFFF4F6FC);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE4E8F5);
  static const txt1 = Color(0xFF0A0F1E);
  static const txt2 = Color(0xFF6B7280);
  static const txt3 = Color(0xFF9CA3AF);

  static const dkCanvas = Color(0xFF0D1117);
  static const dkSurface = Color(0xFF161B27);
  static const dkSurface2 = Color(0xFF1E2537);
  static const dkBorder = Color(0xFF252D42);
  static const dkTxt1 = Color(0xFFF1F5FF);
  static const dkTxt2 = Color(0xFF8D9EC4);
}

// ─── Tab definitions ────────────────────────────────────────
enum _Tab { overview, analytics, records, settings }

extension _TabX on _Tab {
  String get label => switch (this) {
    _Tab.overview => 'Overview',
    _Tab.analytics => 'Analytics',
    _Tab.records => 'Records',
    _Tab.settings => 'Info',
  };
  IconData get icon => switch (this) {
    _Tab.overview => Icons.dashboard_rounded,
    _Tab.analytics => Icons.bar_chart_rounded,
    _Tab.records => Icons.list_alt_rounded,
    _Tab.settings => Icons.info_outline_rounded,
  };
}

// ═══════════════════════════════════════════════════════════
//  ROOT SCREEN
// ═══════════════════════════════════════════════════════════
class SellerDashboardScreen extends ConsumerStatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  ConsumerState<SellerDashboardScreen> createState() =>
      _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends ConsumerState<SellerDashboardScreen>
    with TickerProviderStateMixin {
  late final TabController _tabCtrl;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;
  _Tab _activeTab = _Tab.overview;
  DateTimeRange? _revenueRange;

  SellerDashboardQuery get _dashboardQuery => SellerDashboardQuery(
    revenueFrom: _revenueRange == null
        ? null
        : _formatApiDate(_revenueRange!.start),
    revenueTo: _revenueRange == null
        ? null
        : _formatApiDate(_revenueRange!.end),
  );

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _Tab.values.length, vsync: this)
      ..addListener(() {
        if (!_tabCtrl.indexIsChanging) {
          setState(() => _activeTab = _Tab.values[_tabCtrl.index]);
        }
      });
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    )..forward();
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _switchMode() => AppNavigator.goToCustomerMode();

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const _LogoutDialog(),
    );
    if (ok == true && mounted) {
      await ref.read(sellerAuthViewModelProvider.notifier).logout();
    }
  }

  static String _formatApiDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  Future<void> _pickRevenueRange() async {
    final now = DateTime.now();
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange:
          _revenueRange ??
          DateTimeRange(start: DateTime(now.year, now.month, 1), end: now),
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: _T.accent,
              secondary: _T.emerald,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selected == null || !mounted) return;
    setState(() => _revenueRange = selected);
  }

  void _clearRevenueRange() {
    setState(() => _revenueRange = null);
  }

  void _refresh() {
    ref.invalidate(sellerDashboardProvider(_dashboardQuery));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final query = _dashboardQuery;
    final bundle = ref.watch(sellerDashboardProvider(query));

    return Scaffold(
      backgroundColor: isDark ? _T.dkCanvas : _T.canvas,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: bundle.when(
            loading: () => const _Shimmer(),
            error: (e, _) => _ErrorView(
              message: e.toString().replaceFirst('Exception: ', ''),
              onRetry: _refresh,
              onSwitch: _switchMode,
            ),
            data: (data) => _Shell(
              data: data,
              tabCtrl: _tabCtrl,
              activeTab: _activeTab,
              isDark: isDark,
              onSwitchMode: _switchMode,
              onLogout: _confirmLogout,
              revenueRange: _revenueRange,
              onPickRevenueRange: _pickRevenueRange,
              onClearRevenueRange: _clearRevenueRange,
              onRefresh: () async {
                _refresh();
                await ref.read(sellerDashboardProvider(query).future);
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  SHELL — compact header + tab bar + tab views
// ═══════════════════════════════════════════════════════════
class _Shell extends StatelessWidget {
  final SellerDashboardBundle data;
  final TabController tabCtrl;
  final _Tab activeTab;
  final bool isDark;
  final VoidCallback onSwitchMode;
  final VoidCallback onLogout;
  final DateTimeRange? revenueRange;
  final VoidCallback onPickRevenueRange;
  final VoidCallback onClearRevenueRange;
  final Future<void> Function() onRefresh;

  const _Shell({
    required this.data,
    required this.tabCtrl,
    required this.activeTab,
    required this.isDark,
    required this.onSwitchMode,
    required this.onLogout,
    required this.revenueRange,
    required this.onPickRevenueRange,
    required this.onClearRevenueRange,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Compact Header (always visible) ───────────────
        _CompactHeader(
          data: data.dashboard,
          isDark: isDark,
          onSwitchMode: onSwitchMode,
          onLogout: onLogout,
        ),

        // ── Tab Bar ────────────────────────────────────────
        _TabRow(tabCtrl: tabCtrl, isDark: isDark),

        // ── Tab Content (fills remaining space) ───────────
        Expanded(
          child: TabBarView(
            controller: tabCtrl,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _OverviewTab(
                data: data,
                isDark: isDark,
                revenueRange: revenueRange,
                onPickRevenueRange: onPickRevenueRange,
                onClearRevenueRange: onClearRevenueRange,
                onRefresh: onRefresh,
              ),
              _AnalyticsTab(
                data: data,
                isDark: isDark,
                revenueRange: revenueRange,
                onPickRevenueRange: onPickRevenueRange,
                onClearRevenueRange: onClearRevenueRange,
                onRefresh: onRefresh,
              ),
              _RecordsTab(data: data, isDark: isDark, onRefresh: onRefresh),
              _InfoTab(data: data, isDark: isDark, onRefresh: onRefresh),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  COMPACT HEADER  (was tall hero; now ~100 px)
// ═══════════════════════════════════════════════════════════
class _CompactHeader extends StatelessWidget {
  final SellerDashboardModel data;
  final bool isDark;
  final VoidCallback onSwitchMode;
  final VoidCallback onLogout;

  const _CompactHeader({
    required this.data,
    required this.isDark,
    required this.onSwitchMode,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2980), Color(0xFF3B5BDB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B5BDB).withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          _Avatar(name: data.businessName),
          const SizedBox(width: 12),

          // Business + user name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.businessName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  data.userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // Switch mode pill
          _PillBtn(
            icon: Icons.shopping_bag_outlined,
            label: 'Customer',
            onTap: onSwitchMode,
          ),
          const SizedBox(width: 8),

          // Logout
          _CircleBtn(icon: Icons.logout_rounded, onTap: onLogout),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final ch = name.trim().isEmpty ? 'S' : name.trim()[0].toUpperCase();
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Center(
        child: Text(
          ch,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _PillBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PillBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  TAB ROW
// ═══════════════════════════════════════════════════════════
class _TabRow extends StatelessWidget {
  final TabController tabCtrl;
  final bool isDark;
  const _TabRow({required this.tabCtrl, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? _T.dkSurface : _T.surface,
      child: TabBar(
        controller: tabCtrl,
        labelColor: _T.accent,
        unselectedLabelColor: isDark ? _T.dkTxt2 : _T.txt2,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        indicatorColor: _T.accent,
        indicatorWeight: 2.5,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: isDark ? _T.dkBorder : _T.border,
        tabs: _Tab.values
            .map(
              (t) => Tab(
                height: 46,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(t.icon, size: 18),
                    const SizedBox(height: 2),
                    Text(t.label),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  TAB 1 — OVERVIEW  (above-the-fold KPIs + mini lead bar)
// ═══════════════════════════════════════════════════════════
class _OverviewTab extends StatelessWidget {
  final SellerDashboardBundle data;
  final bool isDark;
  final DateTimeRange? revenueRange;
  final VoidCallback onPickRevenueRange;
  final VoidCallback onClearRevenueRange;
  final Future<void> Function() onRefresh;

  const _OverviewTab({
    required this.data,
    required this.isDark,
    required this.revenueRange,
    required this.onPickRevenueRange,
    required this.onClearRevenueRange,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final d = data.dashboard;
    final r = data.revenue;

    return RefreshIndicator(
      color: _T.accent,
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 80),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: [
          // ── 8-metric grid (2×4, compact cards) ──────────
          _GridOf8(
            isDark: isDark,
            items: [
              _G8Item(
                Icons.account_balance_wallet_outlined,
                d.outstandingBalance,
                'Outstanding',
                _T.rose,
                _T.roseSurf,
              ),
              _G8Item(
                Icons.pending_actions_rounded,
                d.pendingRecoverySum,
                'Pending Rcvry',
                _T.amber,
                _T.amberSurf,
              ),
              _G8Item(
                Icons.people_alt_outlined,
                d.totalCustomers.toString(),
                'Customers',
                _T.accent,
                _T.accentSurf,
              ),
              _G8Item(
                Icons.bolt_rounded,
                d.salesVelocityWeek.toString(),
                'Velocity/Wk',
                _T.violet,
                _T.violetSurf,
              ),
              _G8Item(
                Icons.shopping_cart_checkout_rounded,
                r.totalSales,
                'Total Sales',
                _T.accent,
                _T.accentSurf,
              ),
              _G8Item(
                Icons.task_alt_rounded,
                r.totalRecovered,
                'Recovered',
                _T.emerald,
                _T.emeraldSurf,
              ),
              _G8Item(
                Icons.hourglass_empty_rounded,
                r.outstanding,
                'Outstanding',
                _T.rose,
                _T.roseSurf,
              ),
              _G8Item(
                Icons.percent_rounded,
                r.recoveryPercentage,
                'Rcvry Rate',
                _T.violet,
                _T.violetSurf,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Lead mini-card ───────────────────────────────
          _LeadMiniCard(
            total: d.monthlyLeads,
            won: d.monthlyWonLeads,
            lost: d.monthlyLostLeads,
            isDark: isDark,
          ),

          const SizedBox(height: 16),

          // ── Revenue date range ───────────────────────────
          _TwoColCard(
            isDark: isDark,
            title: 'Revenue Period',
            icon: Icons.calendar_today_outlined,
            iconColor: _T.accent,
            left: _ColStat('From', r.from),
            right: _ColStat('To', r.to),
            footer: '${r.days} days covered',
            trailing: _RangeAction(
              isDark: isDark,
              hasRange: revenueRange != null,
              onPick: onPickRevenueRange,
              onClear: onClearRevenueRange,
            ),
          ),

          const SizedBox(height: 16),

          // ── Performance quick stats (horizontal scroll) ──
          _PerfQuickRow(metrics: r.performanceMetrics, isDark: isDark),
        ],
      ),
    );
  }
}

// ─── 8-item compact grid ────────────────────────────────────
class _G8Item {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color surf;
  const _G8Item(this.icon, this.value, this.label, this.color, this.surf);
}

class _GridOf8 extends StatelessWidget {
  final List<_G8Item> items;
  final bool isDark;
  const _GridOf8({required this.items, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final w = (MediaQuery.sizeOf(context).width - 16 * 2 - 10) / 2;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items
          .map((i) => _G8Card(item: i, width: w, isDark: isDark))
          .toList(),
    );
  }
}

class _G8Card extends StatefulWidget {
  final _G8Item item;
  final double width;
  final bool isDark;
  const _G8Card({
    required this.item,
    required this.width,
    required this.isDark,
  });

  @override
  State<_G8Card> createState() => _G8CardState();
}

class _G8CardState extends State<_G8Card> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      lowerBound: 0.95,
      upperBound: 1.0,
    )..value = 1.0;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i = widget.item;
    return ScaleTransition(
      scale: _c,
      child: GestureDetector(
        onTapDown: (_) => _c.reverse(),
        onTapUp: (_) => _c.forward(),
        onTapCancel: () => _c.forward(),
        child: Container(
          width: widget.width,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: widget.isDark ? _T.dkSurface : _T.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: widget.isDark ? _T.dkBorder : _T.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: widget.isDark ? 0.18 : 0.04,
                ),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: i.surf,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(i.icon, color: i.color, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        i.value,
                        style: TextStyle(
                          color: widget.isDark ? _T.dkTxt1 : _T.txt1,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      i.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _T.txt2,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
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
}

// ─── Lead mini card ─────────────────────────────────────────
class _LeadMiniCard extends StatelessWidget {
  final int total, won, lost;
  final bool isDark;
  const _LeadMiniCard({
    required this.total,
    required this.won,
    required this.lost,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final winRate = total == 0 ? 0.0 : won / total;
    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.leaderboard_rounded, size: 16, color: _T.accent),
              const SizedBox(width: 6),
              Text(
                'Monthly Leads',
                style: TextStyle(
                  color: isDark ? _T.dkTxt1 : _T.txt1,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              _Tag(
                '${(winRate * 100).toStringAsFixed(0)}% win rate',
                _T.emerald,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Win bar
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: _AnimBar(fraction: winRate, color: _T.emerald, bg: isDark),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MiniStat('Total', total.toString(), _T.accent, isDark),
              const SizedBox(width: 20),
              _MiniStat('Won', won.toString(), _T.emerald, isDark),
              const SizedBox(width: 20),
              _MiniStat('Lost', lost.toString(), _T.rose, isDark),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool isDark;
  const _MiniStat(this.label, this.value, this.color, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: isDark ? _T.dkTxt1 : _T.txt1,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Two-col card ────────────────────────────────────────────
class _ColStat {
  final String label, value;
  const _ColStat(this.label, this.value);
}

class _TwoColCard extends StatelessWidget {
  final bool isDark;
  final String title;
  final IconData icon;
  final Color iconColor;
  final _ColStat left, right;
  final String? footer;
  final Widget? trailing;
  const _TwoColCard({
    required this.isDark,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.left,
    required this.right,
    this.footer,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isDark ? _T.dkTxt1 : _T.txt1,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatBlock(left, isDark)),
              Container(
                width: 1,
                height: 36,
                color: isDark ? _T.dkBorder : _T.border,
              ),
              Expanded(child: _StatBlock(right, isDark, center: true)),
            ],
          ),
          if (footer != null) ...[
            const SizedBox(height: 10),
            Text(footer!, style: const TextStyle(color: _T.txt3, fontSize: 11)),
          ],
        ],
      ),
    );
  }
}

class _RevenueRangeCard extends StatelessWidget {
  final String from;
  final String to;
  final int days;
  final bool isDark;
  final bool hasRange;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _RevenueRangeCard({
    required this.from,
    required this.to,
    required this.days,
    required this.isDark,
    required this.hasRange,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 15,
                color: _T.accent,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Revenue Period',
                  style: TextStyle(
                    color: isDark ? _T.dkTxt1 : _T.txt1,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _RangeAction(
                isDark: isDark,
                hasRange: hasRange,
                onPick: onPick,
                onClear: onClear,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatBlock(_ColStat('From', from), isDark)),
              Container(
                width: 1,
                height: 36,
                color: isDark ? _T.dkBorder : _T.border,
              ),
              Expanded(
                child: _StatBlock(_ColStat('To', to), isDark, center: true),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$days days covered',
            style: const TextStyle(color: _T.txt3, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _RangeAction extends StatelessWidget {
  final bool isDark;
  final bool hasRange;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _RangeAction({
    required this.isDark,
    required this.hasRange,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final border = isDark ? _T.dkBorder : _T.border;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasRange) ...[
          Tooltip(
            message: 'Clear revenue range',
            child: InkWell(
              onTap: onClear,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isDark ? _T.dkSurface2 : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: border),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: _T.txt2,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
        Tooltip(
          message: 'Change revenue range',
          child: InkWell(
            onTap: onPick,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: _T.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _T.accent.withValues(alpha: 0.2)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.date_range_rounded, size: 15, color: _T.accent),
                  SizedBox(width: 5),
                  Text(
                    'Range',
                    style: TextStyle(
                      color: _T.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatBlock extends StatelessWidget {
  final _ColStat data;
  final bool isDark;
  final bool center;
  const _StatBlock(this.data, this.isDark, {this.center = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: center
          ? const EdgeInsets.only(left: 16)
          : const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.label,
            style: const TextStyle(
              color: _T.txt2,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.value,
            style: TextStyle(
              color: isDark ? _T.dkTxt1 : _T.txt1,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Perf quick row (horizontal scroll) ─────────────────────
class _PerfQuickRow extends StatelessWidget {
  final SellerPerformanceMetrics metrics;
  final bool isDark;
  const _PerfQuickRow({required this.metrics, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final items = [
      _PQItem(
        Icons.shopping_cart_outlined,
        metrics.averageOrderValue,
        'Avg Order',
        _T.accent,
      ),
      _PQItem(
        Icons.swap_horiz_rounded,
        metrics.conversionRate,
        'Conversion',
        _T.emerald,
      ),
      _PQItem(
        Icons.schedule_rounded,
        '${metrics.averageDaysToRecover}d',
        'Days to Rcvr',
        _T.amber,
      ),
      _PQItem(
        Icons.verified_rounded,
        metrics.onTimeRecoveryRate,
        'On-Time Rcvr',
        _T.violet,
      ),
      _PQItem(
        Icons.people_outline,
        metrics.uniqueCustomers.toString(),
        'Unique Cust.',
        _T.accent,
      ),
      _PQItem(
        Icons.repeat_rounded,
        metrics.repeatCustomerRate,
        'Repeat Rate',
        _T.rose,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance',
          style: TextStyle(
            color: isDark ? _T.dkTxt1 : _T.txt1,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: MediaQuery.sizeOf(context).width * 0.28,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _PQCard(item: items[i], isDark: isDark),
          ),
        ),
      ],
    );
  }
}

class _PQItem {
  final IconData icon;
  final String value, label;
  final Color color;
  const _PQItem(this.icon, this.value, this.label, this.color);
}

class _PQCard extends StatelessWidget {
  final _PQItem item;
  final bool isDark;
  const _PQCard({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? _T.dkSurface : _T.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? _T.dkBorder : _T.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, color: item.color, size: 14),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              item.value,
              style: TextStyle(
                color: isDark ? _T.dkTxt1 : _T.txt1,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _T.txt2,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  TAB 2 — ANALYTICS (distribution + timeline)
// ═══════════════════════════════════════════════════════════
class _AnalyticsTab extends StatelessWidget {
  final SellerDashboardBundle data;
  final bool isDark;
  final DateTimeRange? revenueRange;
  final VoidCallback onPickRevenueRange;
  final VoidCallback onClearRevenueRange;
  final Future<void> Function() onRefresh;

  const _AnalyticsTab({
    required this.data,
    required this.isDark,
    required this.revenueRange,
    required this.onPickRevenueRange,
    required this.onClearRevenueRange,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final d = data.dashboard;
    final r = data.revenue;
    return RefreshIndicator(
      color: _T.accent,
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 80),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: [
          // ── Status distributions side-by-side ───────────
          _RevenueRangeCard(
            from: r.from,
            to: r.to,
            days: r.days,
            isDark: isDark,
            hasRange: revenueRange != null,
            onPick: onPickRevenueRange,
            onClear: onClearRevenueRange,
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DistCard(
                  title: 'Lead Status',
                  values: d.leadStatusPercentages,
                  baseColor: _T.accent,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DistCard(
                  title: 'Order Status',
                  values: d.orderStatusPercentages,
                  baseColor: _T.emerald,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Revenue timeline ─────────────────────────────
          _TimelineCard(points: r.revenuePoints, isDark: isDark),

          const SizedBox(height: 16),

          // ── Custom order sales ───────────────────────────
          _SectionCard(
            isDark: isDark,
            icon: Icons.receipt_long_rounded,
            iconColor: _T.violet,
            title: 'Custom Order Sales & Recovery',
            rows: {
              'Current Custom Sales': d.totalCustomSales,
              'Current Custom Recovery': d.totalCustomRecovery,
              'All-Time Custom Sales': d.totalCustomSalesAll,
              'All-Time Custom Recovery': d.totalCustomRecoveryAll,
              'Current Recovery %': d.totalCustomRecoveryPercentage,
              'All-Time Recovery %': d.totalCustomRecoveryPercentageAll,
              'Pending Recovery Count': d.pendingRecoveryCount.toString(),
            },
          ),
        ],
      ),
    );
  }
}

// ─── Distribution card (compact, stacked bars) ───────────────
class _DistCard extends StatelessWidget {
  final String title;
  final Map<String, int> values;
  final Color baseColor;
  final bool isDark;
  const _DistCard({
    required this.title,
    required this.values,
    required this.baseColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [baseColor, _T.violet, _T.amber, _T.emerald, _T.rose];
    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isDark ? _T.dkTxt1 : _T.txt1,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (values.isEmpty)
            const Text(
              'No data.',
              style: TextStyle(color: _T.txt3, fontSize: 11),
            )
          else
            ...values.entries.toList().asMap().entries.map((e) {
              final color = colors[e.key % colors.length];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _CompactDistRow(
                  label: e.value.key,
                  pct: e.value.value,
                  color: color,
                  isDark: isDark,
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _CompactDistRow extends StatefulWidget {
  final String label;
  final int pct;
  final Color color;
  final bool isDark;
  const _CompactDistRow({
    required this.label,
    required this.pct,
    required this.color,
    required this.isDark,
  });

  @override
  State<_CompactDistRow> createState() => _CompactDistRowState();
}

class _CompactDistRowState extends State<_CompactDistRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _a = Tween<double>(
      begin: 0,
      end: (widget.pct / 100).clamp(0.0, 1.0),
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: widget.isDark ? _T.dkTxt2 : _T.txt2,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${widget.pct}%',
              style: TextStyle(
                color: widget.color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        AnimatedBuilder(
          animation: _a,
          builder: (_, _) => ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: _a.value,
              minHeight: 5,
              backgroundColor: widget.isDark
                  ? _T.dkSurface2
                  : const Color(0xFFE7EAF2),
              valueColor: AlwaysStoppedAnimation<Color>(widget.color),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Timeline card ───────────────────────────────────────────
class _TimelineCard extends StatelessWidget {
  final List<SellerRevenuePoint> points;
  final bool isDark;
  const _TimelineCard({required this.points, required this.isDark});

  String _fmt(int v) {
    if (v >= 1000000) return 'Rs ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'Rs ${(v / 1000).toStringAsFixed(0)}K';
    return 'Rs $v';
  }

  @override
  Widget build(BuildContext context) {
    final maxVal = points.fold<int>(
      1,
      (mx, p) => [mx, p.sales, p.recovered].reduce((a, b) => a > b ? a : b),
    );

    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline_rounded, size: 15, color: _T.accent),
              const SizedBox(width: 6),
              Text(
                'Revenue Timeline',
                style: TextStyle(
                  color: isDark ? _T.dkTxt1 : _T.txt1,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              _Dot(_T.accent),
              const SizedBox(width: 4),
              const Text(
                'Sales',
                style: TextStyle(color: _T.txt2, fontSize: 10),
              ),
              const SizedBox(width: 10),
              _Dot(_T.emerald),
              const SizedBox(width: 4),
              const Text(
                'Rcvrd',
                style: TextStyle(color: _T.txt2, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (points.isEmpty)
            const Text(
              'No data.',
              style: TextStyle(color: _T.txt3, fontSize: 11),
            )
          else
            ...points.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.period,
                      style: TextStyle(
                        color: isDark ? _T.dkTxt1 : _T.txt1,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    _AnimBar(
                      fraction: maxVal == 0
                          ? 0
                          : (p.sales / maxVal).clamp(0.0, 1.0),
                      color: _T.accent,
                      bg: isDark,
                      label: _fmt(p.sales),
                    ),
                    const SizedBox(height: 4),
                    _AnimBar(
                      fraction: maxVal == 0
                          ? 0
                          : (p.recovered / maxVal).clamp(0.0, 1.0),
                      color: _T.emerald,
                      bg: isDark,
                      label: _fmt(p.recovered),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  TAB 3 — RECORDS (expandable tiles per category)
// ═══════════════════════════════════════════════════════════
class _RecordsTab extends StatelessWidget {
  final SellerDashboardBundle data;
  final bool isDark;
  final Future<void> Function() onRefresh;

  const _RecordsTab({
    required this.data,
    required this.isDark,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final d = data.dashboard;
    final r = data.revenue;

    return RefreshIndicator(
      color: _T.accent,
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 80),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: [
          _RecordGroup(
            icon: Icons.people_alt_rounded,
            label: 'Customers',
            color: _T.accent,
            records: d.customers,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _RecordGroup(
            icon: Icons.assignment_rounded,
            label: 'Latest Custom Orders',
            color: _T.emerald,
            records: d.customOrders,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _RecordGroup(
            icon: Icons.star_rounded,
            label: 'Top Products',
            color: _T.amber,
            records: d.topProducts,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _RecordGroup(
            icon: Icons.location_on_rounded,
            label: 'Top Areas',
            color: _T.rose,
            records: r.performanceMetrics.topAreas,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _RecordGroup(
            icon: Icons.inventory_2_rounded,
            label: 'Top Revenue Products',
            color: _T.violet,
            records: r.performanceMetrics.topProducts,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

// ─── Record group (collapsible section) ─────────────────────
class _RecordGroup extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final List<SellerDashboardRecord> records;
  final bool isDark;

  const _RecordGroup({
    required this.icon,
    required this.label,
    required this.color,
    required this.records,
    required this.isDark,
  });

  @override
  State<_RecordGroup> createState() => _RecordGroupState();
}

class _RecordGroupState extends State<_RecordGroup> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return _Card(
      isDark: widget.isDark,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Group header (tappable)
          InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        color: widget.isDark ? _T.dkTxt1 : _T.txt1,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _Tag('${widget.records.length}', widget.color),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(
                      Icons.expand_more_rounded,
                      color: widget.isDark ? _T.dkTxt2 : _T.txt2,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expandable list
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 240),
            crossFadeState: _open
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: widget.records.isEmpty
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Text(
                      'No records.',
                      style: TextStyle(
                        color: widget.isDark ? _T.dkTxt2 : _T.txt2,
                        fontSize: 12,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      Divider(
                        height: 1,
                        color: widget.isDark ? _T.dkBorder : _T.border,
                      ),
                      ...widget.records.asMap().entries.map(
                        (e) => _RecordTile(
                          record: e.value,
                          index: e.key,
                          color: widget.color,
                          isDark: widget.isDark,
                          isLast: e.key == widget.records.length - 1,
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

class _RecordTile extends StatelessWidget {
  final SellerDashboardRecord record;
  final int index;
  final Color color;
  final bool isDark;
  final bool isLast;

  const _RecordTile({
    required this.record,
    required this.index,
    required this.color,
    required this.isDark,
    required this.isLast,
  });

  // Determines badge color from status text
  ({Color fg, Color bg}) _statusColor(String badge) {
    final s = badge.toLowerCase();
    if (s.contains('active') || s.contains('paid') || s.contains('complet') || s.contains('deliver')) {
      return (fg: _T.emerald, bg: _T.emeraldSurf);
    }
    if (s.contains('pending') || s.contains('instalment') || s.contains('verif')) {
      return (fg: _T.amber, bg: _T.amberSurf);
    }
    if (s.contains('cancel') || s.contains('lost') || s.contains('inactive')) {
      return (fg: _T.rose, bg: _T.roseSurf);
    }
    if (s.contains('process')) {
      return (fg: _T.violet, bg: _T.violetSurf);
    }
    return (fg: color, bg: color.withValues(alpha: 0.10));
  }

  @override
  Widget build(BuildContext context) {
    final sc = _statusColor(record.badge);
    // Split details into two groups: before and after the financial divider
    final entries = record.details.entries.toList();
    // Find where financial section starts (first key containing financial keywords)
    final splitIdx = entries.indexWhere((e) {
      final k = e.key.toLowerCase();
      return k.contains('price') || k.contains('deal') || k.contains('advance') ||
          k.contains('tenure') || k.contains('settlement') || k.contains('monthly') ||
          k.contains('financial');
    });
    final personalEntries = splitIdx > 0 ? entries.sublist(0, splitIdx) : entries;
    final financialEntries = splitIdx > 0 ? entries.sublist(splitIdx) : <MapEntry<String, String>>[];

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
        leading: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        title: Text(
          record.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isDark ? _T.dkTxt1 : _T.txt1,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            record.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? _T.dkTxt2 : _T.txt2,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        // Status badge — color-coded
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: sc.bg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            record.badge,
            style: TextStyle(
              color: sc.fg,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        children: [
          Divider(height: 1, color: isDark ? _T.dkBorder : _T.border),
          const SizedBox(height: 10),

          // Personal info rows
          ...personalEntries.map(
            (e) => _KVRow(label: e.key, value: e.value, isDark: isDark),
          ),

          // Financial section (only when present)
          if (financialEntries.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _T.emerald.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                children: [
                  Icon(Icons.account_balance_wallet_outlined,
                      size: 12, color: _T.emerald),
                  SizedBox(width: 5),
                  Text(
                    'FINANCIAL DETAILS',
                    style: TextStyle(
                      color: _T.emerald,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            ...financialEntries.map(
              (e) => _KVRow(label: e.key, value: e.value, isDark: isDark),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  TAB 4 — INFO (reporting window + period details)
// ═══════════════════════════════════════════════════════════
class _InfoTab extends StatelessWidget {
  final SellerDashboardBundle data;
  final bool isDark;
  final Future<void> Function() onRefresh;

  const _InfoTab({
    required this.data,
    required this.isDark,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final d = data.dashboard;
    final r = data.revenue;

    return RefreshIndicator(
      color: _T.accent,
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 80),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: [
          _SectionCard(
            isDark: isDark,
            icon: Icons.badge_outlined,
            iconColor: _T.accent,
            title: 'Reporting Window',
            rows: {
              'Seller ID': d.sellerId.toString(),
              'Current Date': d.todayDate,
              'Previous Comparison Date': d.previous30Date,
              'Dashboard Range': '${d.days} days',
            },
          ),
          const SizedBox(height: 14),
          _SectionCard(
            isDark: isDark,
            icon: Icons.calendar_today_outlined,
            iconColor: _T.emerald,
            title: 'Revenue Date Range',
            rows: {
              'From': r.from,
              'To': r.to,
              'Days Covered': '${r.days} days',
            },
          ),
          const SizedBox(height: 14),
          _SectionCard(
            isDark: isDark,
            icon: Icons.track_changes_rounded,
            iconColor: _T.violet,
            title: 'Monthly Lead Stats',
            rows: {
              'Total Leads': d.monthlyLeads.toString(),
              'Won Leads': d.monthlyWonLeads.toString(),
              'Lost Leads': d.monthlyLostLeads.toString(),
              'Pending Recovery Count': d.pendingRecoveryCount.toString(),
            },
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  SHARED COMPONENTS
// ═══════════════════════════════════════════════════════════

// Generic card container
class _Card extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final EdgeInsets padding;

  const _Card({
    required this.child,
    required this.isDark,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? _T.dkSurface : _T.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? _T.dkBorder : _T.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

// Section card (icon header + key-value rows)
class _SectionCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String title;
  final Map<String, String> rows;

  const _SectionCard({
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final entries = rows.entries.toList();
    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: iconColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: isDark ? _T.dkTxt1 : _T.txt1,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...entries.asMap().entries.map(
            (e) => Column(
              children: [
                _KVRow(
                  label: e.value.key,
                  value: e.value.value,
                  isDark: isDark,
                ),
                if (e.key < entries.length - 1)
                  Divider(height: 12, color: isDark ? _T.dkBorder : _T.border),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Key-value row
class _KVRow extends StatelessWidget {
  final String label, value;
  final bool isDark;
  const _KVRow({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: TextStyle(
              color: isDark ? _T.dkTxt2 : _T.txt2,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: isDark ? _T.dkTxt1 : _T.txt1,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// Animated progress bar (shared by multiple sections)
class _AnimBar extends StatefulWidget {
  final double fraction;
  final Color color;
  final bool bg;
  final String? label;
  const _AnimBar({
    required this.fraction,
    required this.color,
    required this.bg,
    this.label,
  });

  @override
  State<_AnimBar> createState() => _AnimBarState();
}

class _AnimBarState extends State<_AnimBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _a = Tween<double>(
      begin: 0,
      end: widget.fraction,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AnimatedBuilder(
            animation: _a,
            builder: (_, _) => ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: _a.value,
                minHeight: 7,
                backgroundColor: widget.bg
                    ? _T.dkSurface2
                    : const Color(0xFFE7EAF2),
                valueColor: AlwaysStoppedAnimation<Color>(widget.color),
              ),
            ),
          ),
        ),
        if (widget.label != null) ...[
          const SizedBox(width: 8),
          SizedBox(
            width: 76,
            child: Text(
              widget.label!,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: widget.bg ? _T.dkTxt2 : _T.txt2,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot(this.color);
  @override
  Widget build(BuildContext context) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}


// ═══════════════════════════════════════════════════════════
//  SHIMMER LOADING
// ═══════════════════════════════════════════════════════════
class _Shimmer extends StatefulWidget {
  const _Shimmer();
  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _a = Tween<double>(
      begin: -2,
      end: 2,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _a,
      builder: (_, _) => Column(
        children: [
          // Compact header placeholder
          _SBox(height: 70, radius: 0, isDark: isDark, shimmer: _a.value),
          // Tab bar placeholder
          _SBox(height: 48, radius: 0, isDark: isDark, shimmer: _a.value),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 2-col grid placeholder
                  Row(
                    children: [
                      Expanded(
                        child: _SBox(
                          height: 72,
                          radius: 14,
                          isDark: isDark,
                          shimmer: _a.value,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SBox(
                          height: 72,
                          radius: 14,
                          isDark: isDark,
                          shimmer: _a.value,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _SBox(
                          height: 72,
                          radius: 14,
                          isDark: isDark,
                          shimmer: _a.value,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SBox(
                          height: 72,
                          radius: 14,
                          isDark: isDark,
                          shimmer: _a.value,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SBox(
                    height: 100,
                    radius: 14,
                    isDark: isDark,
                    shimmer: _a.value,
                  ),
                  const SizedBox(height: 10),
                  _SBox(
                    height: 80,
                    radius: 14,
                    isDark: isDark,
                    shimmer: _a.value,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SBox extends StatelessWidget {
  final double height;
  final double radius;
  final bool isDark;
  final double shimmer;
  const _SBox({
    required this.height,
    required this.radius,
    required this.isDark,
    required this.shimmer,
  });

  @override
  Widget build(BuildContext context) {
    final base = isDark ? const Color(0xFF1E2537) : const Color(0xFFE8EBF5);
    final hi = isDark ? const Color(0xFF252D42) : const Color(0xFFF4F6FF);
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment(shimmer - 1, 0),
          end: Alignment(shimmer, 0),
          colors: [base, hi, base],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  ERROR VIEW
// ═══════════════════════════════════════════════════════════
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onSwitch;

  const _ErrorView({
    required this.message,
    required this.onRetry,
    required this.onSwitch,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _T.roseSurf,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: _T.rose,
                size: 28,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Dashboard unavailable',
              style: TextStyle(
                color: isDark ? _T.dkTxt1 : _T.txt1,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _T.txt2, height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 17),
                label: const Text('Try again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _T.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: onSwitch,
              child: const Text(
                'Switch to Customer Mode',
                style: TextStyle(color: _T.txt2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  LOGOUT DIALOG
// ═══════════════════════════════════════════════════════════
class _LogoutDialog extends StatelessWidget {
  const _LogoutDialog();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      backgroundColor: isDark ? _T.dkSurface : _T.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _T.roseSurf,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.logout_rounded, color: _T.rose, size: 24),
            ),
            const SizedBox(height: 14),
            Text(
              'Logout?',
              style: TextStyle(
                color: isDark ? _T.dkTxt1 : _T.txt1,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your seller session will end on the server and this device.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _T.txt2, height: 1.4, fontSize: 13),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _T.txt2,
                      side: BorderSide(color: isDark ? _T.dkBorder : _T.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      minimumSize: const Size.fromHeight(42),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _T.rose,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      minimumSize: const Size.fromHeight(42),
                    ),
                    child: const Text('Logout'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
