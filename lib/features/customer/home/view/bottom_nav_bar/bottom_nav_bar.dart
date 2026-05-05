import 'package:atompro/core/common/widgets/app_bar.dart';
import 'package:atompro/core/style/color_palette.dart';
import 'package:atompro/features/customer/custom_order/view/custom_order_view.dart';
import 'package:atompro/features/customer/drawer/view/drawer.dart';
import 'package:atompro/features/customer/home/view/home_page.dart';
import 'package:atompro/features/customer/make_offer/view/make_offer_view.dart';
import 'package:atompro/features/customer/profile/view/profile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BottomBarPage extends StatefulWidget {
  const BottomBarPage({super.key});

  @override
  State<BottomBarPage> createState() => _BottomBarPageState();
}

class _BottomBarPageState extends State<BottomBarPage> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final List<Widget> _pages;

  // Home — house shape
  static const String _homeSvg =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 -960 960 960"><path d="M240-200h120v-200q0-17 11.5-28.5T400-440h160q17 0 28.5 11.5T600-400v200h120v-360L480-740 240-560v360Zm-80 0v-360q0-19 8.5-36t23.5-28l240-180q21-16 48-16t48 16l240 180q15 11 23.5 28t8.5 36v360q0 33-23.5 56.5T720-120H560q-17 0-28.5-11.5T520-160v-200h-80v200q0 17-11.5 28.5T400-120H240q-33 0-56.5-23.5T160-200Zm320-270Z"/></svg>';

  // Make Offer — handshake icon
  static const String _offerSvg =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 -960 960 960"><path d="M475-160q4 0 8-2t6-4l328-328q12-12 17.5-27t5.5-30q0-16-5.5-30.5T817-607L647-777q-11-12-25.5-17.5T591-800q-15 0-30 5.5T534-777l-11 11 74 74q15 14 22 32t7 38q0 42-28.5 70T527-524q-20 0-38.5-7T456-553l-70-74-175 175q-3 3-4.5 6.5T205-438q0 8 6 14.5t14 6.5q4 0 8-2t6-4l136-136 56 56-135 136q-3 3-4.5 6.5T291-354q0 8 6 14t14 6q4 0 8-2t6-4l136-136 56 56-135 135q-3 3-4.5 7t-1.5 8q0 8 6 14t14 6q4 0 7.5-1.5t6.5-4.5l136-135 56 56-136 136q-3 3-4.5 6.5T465-186q0 8 6.5 14t13.5 6Zm-1 80q-37 0-65.5-24.5T375-166q-34-5-57.5-28.5T289-251q-34-5-56.5-28T205-336q-38-5-62-31t-24-63q0-20 7.5-38.5T149-500l232-231 131 131q2 3 6 4.5t8 1.5q9 0 15-5.5t6-14.5q0-4-1.5-8T542-628L410-760l69-69q24-24 53.5-37.5T591-880q31 0 60.5 13T705-829l170 170q24 23 37.5 53t13.5 61q0 31-13.5 61T875-431L547-104q-14 14-32 19t-41 5Z"/></svg>';

  // My Orders — shopping bag icon
  static const String _orderSvg =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 -960 960 960"><path d="M240-80q-33 0-56.5-23.5T160-160v-480q0-33 23.5-56.5T240-720h80q0-66 47-113t113-47q66 0 113 47t47 113h80q33 0 56.5 23.5T800-640v480q0 33-23.5 56.5T720-80H240Zm0-80h480v-480H240v480Zm240-240q66 0 113-47t47-113h-80q0 33-23.5 56.5T480-480q-33 0-56.5-23.5T400-560h-80q0 66 47 113t113 47ZM400-720h160q0-33-23.5-56.5T480-800q-33 0-56.5 23.5T400-720Zm80 320Z"/></svg>';

  // Profile — person icon
  static const String _profileSvg =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 -960 960 960"><path d="M480-480q-66 0-113-47t-47-113q0-66 47-113t113-47q66 0 113 47t47 113q0 66-47 113t-113 47ZM160-240v-32q0-34 17.5-62.5T224-378q62-31 126-46.5T480-440q66 0 130 15.5T736-378q29 15 46.5 43.5T800-272v32q0 33-23.5 56.5T720-160H240q-33 0-56.5-23.5T160-240Z"/></svg>';

  final List<_NavItem> _navItems = const [
    _NavItem(label: 'Home', svg: _homeSvg),
    _NavItem(label: 'Make Offer', svg: _offerSvg),
    _NavItem(label: 'Order now', svg: _orderSvg),
    _NavItem(label: 'Profile', svg: _profileSvg),
  ];

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        orderNow: () => setState(() => _selectedIndex = 2),
      ),
      MakeOfferView(orderNow: () => setState(() => _selectedIndex = 2)),
      CustomOrderView(),
      const ProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(
        context,
        () => _scaffoldKey.currentState?.openDrawer(),
        false,
        showMenuButton: true,
      ),
      key: _scaffoldKey,
      drawer: AppDrawer(
        closeDrawer: () => _scaffoldKey.currentState?.closeDrawer(),
        onOrderNowTap: () {
          _scaffoldKey.currentState?.closeDrawer();
          setState(() => _selectedIndex = 2);
        },
        onMakeOfferTap: () {
          _scaffoldKey.currentState?.closeDrawer();
          setState(() => _selectedIndex = 1);
        },
      ),
      extendBody: true,
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: _FloatingNavBar(
        selectedIndex: _selectedIndex,
        items: _navItems,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}

// ─── Data ─────────────────────────────────────────────────────────────────────

class _NavItem {
  final String label;
  final String svg;
  const _NavItem({required this.label, required this.svg});
}

// ─── Floating Nav Bar Container ───────────────────────────────────────────────

class _FloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _FloatingNavBar({
    required this.selectedIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        bottomPadding > 0 ? bottomPadding : 16,
      ),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
          boxShadow: [
            BoxShadow(
              color: ColorPalette.secondary.withOpacity(0.12),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            children: List.generate(items.length, (index) {
              return Expanded(
                child: _NavBarItem(
                  item: items[index],
                  isSelected: selectedIndex == index,
                  onTap: () => onTap(index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─── Individual Nav Item ──────────────────────────────────────────────────────

class _NavBarItem extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: animation,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: isSelected
              ? _ActivePill(item: item, key: ValueKey('active_${item.label}'))
              : _InactiveIcon(
                  item: item,
                  key: ValueKey('inactive_${item.label}'),
                ),
        ),
      ),
    );
  }
}

// ─── Active Pill (icon + label side by side) ──────────────────────────────────

class _ActivePill extends StatelessWidget {
  final _NavItem item;
  const _ActivePill({required this.item, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: ColorPalette.secondary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.string(
            item.svg,
            width: 17,
            height: 17,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              item.label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Inactive (icon + label stacked) ─────────────────────────────────────────

class _InactiveIcon extends StatelessWidget {
  final _NavItem item;
  const _InactiveIcon({required this.item, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.string(
          item.svg,
          width: 22,
          height: 22,
          colorFilter: const ColorFilter.mode(
            Color(0xFF9E9E9E),
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          item.label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF9E9E9E),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
