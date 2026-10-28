import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../design/atom_text.dart';
import '../design/atom_tokens.dart';
import '../responsive/atom_responsive.dart';
import '../core/services/fcm_service.dart';
import '../screens/account/atom_account_screen.dart';
import '../screens/account/atom_guest_account_screen.dart';
import '../screens/ask_atom/atom_ask_atom_screen.dart';
import '../screens/home/atom_home_screen.dart';
import '../screens/installments/atom_guest_plans_screen.dart';
import '../screens/installments/atom_plans_screen.dart';
import '../screens/shop/atom_shop_screen.dart';
import '../state/atom_session.dart';
import 'atom_nav.dart';

enum AtomTab { home, shop, askAtom, installments, account }

/// Selected tab, so any screen can switch tabs (e.g. Home → "View all" → Shop).
final atomTabProvider = NotifierProvider<AtomTabNotifier, AtomTab>(AtomTabNotifier.new);

class AtomTabNotifier extends Notifier<AtomTab> {
  @override
  AtomTab build() => AtomTab.home;

  void select(AtomTab tab) => state = tab;
}

/// Root of the app: five tabs, bottom bar on phones, navigation rail on
/// tablets.
///
/// Each tab has its own [Navigator], so lists opened from a tab (a category,
/// a brand) keep the bottom bar, and switching tabs keeps each tab's place.
/// Full-screen pages (product, order) go on the root navigator instead; see
/// `AtomNav`.
///
/// Memory: tabs are built the first time they are opened and then kept
/// (IndexedStack), so switching back is instant, but a tab the user never
/// opens costs nothing. Data inside tabs is held by autoDispose providers,
/// not by the widgets.
class AtomShell extends ConsumerStatefulWidget {
  const AtomShell({super.key});

  @override
  ConsumerState<AtomShell> createState() => _AtomShellState();
}

class _AtomShellState extends ConsumerState<AtomShell> {
  final Set<AtomTab> _opened = {AtomTab.home};

  /// One navigator per tab and session, so signing in or out starts the
  /// guest and signed-in versions of a tab afresh.
  final Map<String, GlobalKey<NavigatorState>> _navigators = {};

  GlobalKey<NavigatorState> _navigator(AtomTab tab, bool signedIn) =>
      _navigators.putIfAbsent('${tab.name}-$signedIn', GlobalKey<NavigatorState>.new);

  Widget _page(AtomTab tab, bool signedIn) => switch (tab) {
        AtomTab.home => const AtomHomeScreen(),
        AtomTab.shop => const AtomShopScreen(),
        AtomTab.askAtom => const AtomAskAtomScreen(),
        AtomTab.installments => signedIn ? const AtomPlansScreen() : const AtomGuestPlansScreen(),
        AtomTab.account => signedIn ? const AtomAccountScreen() : const AtomGuestAccountScreen(),
      };

  @override
  void initState() {
    super.initState();
    _welcomeOnce();
    // A tapped push opens Notifications (or sign in, for a guest's phone).
    FcmService.onNotificationTap = () {
      if (!mounted) return;
      ref.read(atomSignedInProvider) ? AtomNav.notifications(context) : AtomNav.signIn(context);
    };
  }

  @override
  void dispose() {
    FcmService.onNotificationTap = null;
    super.dispose();
  }

  /// The welcome screen (create account / sign in / continue as guest) shows
  /// once, on the first launch of a guest.
  Future<void> _welcomeOnce() async {
    const storage = FlutterSecureStorage();
    const key = 'welcome_seen';
    if (await storage.read(key: key) == '1') return;
    await storage.write(key: key, value: '1');
    final session = await ref.read(atomSessionProvider.future);
    if (!mounted || session.signedIn) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AtomNav.welcome(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Signed out (or the session was revoked): close every full-screen page
    // that belonged to the account, so nothing of it stays on screen.
    ref.listen(atomSignedInProvider, (previous, next) {
      if (previous == true && next == false) {
        Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
      }
    });
    final tab = ref.watch(atomTabProvider);
    final signedIn = ref.watch(atomSignedInProvider);
    _opened.add(tab);

    final body = IndexedStack(
      index: tab.index,
      children: [
        for (final t in AtomTab.values)
          _opened.contains(t)
              ? KeyedSubtree(
                  key: ValueKey('${t.name}-$signedIn'),
                  child: _TabNavigator(
                    navigatorKey: _navigator(t, signedIn),
                    active: t == tab,
                    isHome: t == AtomTab.home,
                    onLeaveTab: () => ref.read(atomTabProvider.notifier).select(AtomTab.home),
                    child: _page(t, signedIn),
                  ),
                )
              : const SizedBox.shrink(),
      ],
    );

    void select(AtomTab t) {
      // Tapping the open tab again goes back to its first screen.
      if (t == tab) _navigator(t, signedIn).currentState?.popUntil((route) => route.isFirst);
      ref.read(atomTabProvider.notifier).select(t);
    }


    if (context.isCompact) {
      return Scaffold(
        body: body,
        bottomNavigationBar: _AtomBottomBar(current: tab, onSelect: select),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              selectedIndex: tab.index,
              onDestinationSelected: (i) => select(AtomTab.values[i]),
              labelType: NavigationRailLabelType.all,
              backgroundColor: AtomColors.white,
              indicatorColor: AtomColors.primarySoft,
              selectedIconTheme: const IconThemeData(color: AtomColors.primary),
              unselectedIconTheme: const IconThemeData(color: AtomColors.muted),
              selectedLabelTextStyle: AtomText.small.copyWith(color: AtomColors.primary, fontWeight: FontWeight.w800),
              unselectedLabelTextStyle: AtomText.small,
              destinations: [
                for (final item in _navItems) NavigationRailDestination(icon: Icon(item.icon), label: Text(item.label)),
              ],
            ),
            const VerticalDivider(width: 1, color: AtomColors.line),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

/// A tab's own navigator. System back pops inside the open tab first; on a
/// tab's first screen it goes to Home ([onLeaveTab]); only Home lets the
/// app close.
class _TabNavigator extends StatefulWidget {
  const _TabNavigator({required this.navigatorKey, required this.active, required this.isHome, required this.onLeaveTab, required this.child});

  final GlobalKey<NavigatorState> navigatorKey;
  final bool active;
  final bool isHome;
  final VoidCallback onLeaveTab;
  final Widget child;

  @override
  State<_TabNavigator> createState() => _TabNavigatorState();
}

class _TabNavigatorState extends State<_TabNavigator> {
  /// Whether this tab's navigator has a screen to go back from.
  bool _innerCanPop = false;

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: !widget.active || (widget.isHome && !_innerCanPop),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || !widget.active) return;
        if (_innerCanPop) {
          widget.navigatorKey.currentState?.maybePop();
        } else if (!widget.isHome) {
          widget.onLeaveTab();
        }
      },
      child: NotificationListener<NavigationNotification>(
        onNotification: (notification) {
          if (notification.canHandlePop != _innerCanPop) setState(() => _innerCanPop = notification.canHandlePop);
          return false;
        },
        child: Navigator(
          key: widget.navigatorKey,
          onGenerateRoute: (settings) => MaterialPageRoute(settings: settings, builder: (_) => widget.child),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon);

  final String label;
  final IconData icon;
}

const _navItems = [
  _NavItem('Home', Icons.home_rounded),
  _NavItem('Shop', Icons.grid_view_rounded),
  _NavItem('Ask Atom', Icons.auto_awesome_rounded),
  _NavItem('Installments', Icons.calendar_month_rounded),
  _NavItem('Account', Icons.person_rounded),
];

/// Phone bottom bar with the raised Ask Atom button in the middle.
class _AtomBottomBar extends StatelessWidget {
  const _AtomBottomBar({required this.current, required this.onSelect});

  final AtomTab current;
  final ValueChanged<AtomTab> onSelect;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AtomColors.white, border: Border(top: BorderSide(color: AtomColors.line))),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              for (final tab in AtomTab.values)
                Expanded(
                  child: tab == AtomTab.askAtom
                      ? _AtomCentreButton(onTap: () => onSelect(tab), selected: current == tab)
                      : _BarItem(item: _navItems[tab.index], selected: current == tab, onTap: () => onSelect(tab)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  const _BarItem({required this.item, required this.selected, required this.onTap});

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AtomColors.primary : AtomColors.muted;
    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 32,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(item.label, maxLines: 1, overflow: TextOverflow.fade, softWrap: false, style: AtomText.small.copyWith(fontSize: 11, color: color, fontWeight: selected ? FontWeight.w800 : FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _AtomCentreButton extends StatelessWidget {
  const _AtomCentreButton({required this.onTap, required this.selected});

  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Ask Atom',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Transform.translate(
              offset: const Offset(0, -10),
              child: Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: AtomColors.ink,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Color(0x4014213D), blurRadius: 18, offset: Offset(0, 8))],
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: AtomColors.amber, size: 24),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -6),
              child: Text('Ask Atom', style: AtomText.small.copyWith(fontSize: 11, color: AtomColors.ink, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
