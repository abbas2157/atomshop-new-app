import 'package:atompro/features/seller/customers/view/seller_customers_screen.dart';
import 'package:atompro/features/seller/dashboard/view/seller_dashboard_screen.dart';
import 'package:atompro/features/seller/instalments/view/seller_instalments_screen.dart';
import 'package:atompro/features/seller/leads/view/seller_leads_screen.dart';
import 'package:atompro/features/seller/orders/view/seller_orders_hub_screen.dart';
import 'package:atompro/features/seller/profile/view/seller_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// ─── Shell ────────────────────────────────────────────────────────────────────

class SellerShellScreen extends StatefulWidget {
  const SellerShellScreen({super.key});

  @override
  State<SellerShellScreen> createState() => _SellerShellScreenState();
}

class _SellerShellScreenState extends State<SellerShellScreen> {
  int _selectedIndex = 0;

  // Home — house icon
  static const String _homeSvg =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 -960 960 960"><path d="M240-200h120v-200q0-17 11.5-28.5T400-440h160q17 0 28.5 11.5T600-400v200h120v-360L480-740 240-560v360Zm-80 0v-360q0-19 8.5-36t23.5-28l240-180q21-16 48-16t48 16l240 180q15 11 23.5 28t8.5 36v360q0 33-23.5 56.5T720-120H560q-17 0-28.5-11.5T520-160v-200h-80v200q0 17-11.5 28.5T400-120H240q-33 0-56.5-23.5T160-200Zm320-270Z"/></svg>';

  // Orders — receipt icon
  static const String _ordersSvg =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 -960 960 960"><path d="M240-80q-50 0-85-35t-35-85v-120h120v-560l60 60 60-60 60 60 60-60 60 60 60-60 60 60 60-60v560h120v120q0 50-35 85T720-80H240Zm480-80q17 0 28.5-11.5T760-200v-40H560v40q0 17 11.5 28.5T600-160h120ZM320-280h320v-480H320v480Zm40-360h240v-80H360v80Zm0 120h240v-80H360v80Zm-120 400h280q-6-13-9-26.5t-3-27.5v-40H240v40q0 17 11.5 28.5T280-160Zm280-440Z"/></svg>';

  // Customers — people icon
  static const String _customersSvg =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 -960 960 960"><path d="M0-240v-63q0-43 44-70t116-27q13 0 25 .5t23 2.5q-14 21-21 44t-7 48v65H0Zm240 0v-65q0-32 17.5-58.5T307-410q32-20 76.5-30t96.5-10q53 0 97.5 10t76.5 30q32 20 49 46.5t17 58.5v65H240Zm560 0v-65q0-26-6.5-49T773-397q11-2 22.5-2.5t23.5-.5q72 0 116 26.5t44 70.5v63H800ZM160-440q-33 0-56.5-23.5T80-520q0-34 23.5-57t56.5-23q34 0 57 23t23 57q0 33-23 56.5T160-440Zm640 0q-33 0-56.5-23.5T720-520q0-34 23.5-57t56.5-23q34 0 57 23t23 57q0 33-23 56.5T800-440Zm-320-40q-50 0-85-35t-35-85q0-51 35-85.5t85-34.5q51 0 85.5 34.5T600-600q0 50-34.5 85T480-480Z"/></svg>';

  // Profile — person icon
  static const String _leadsSvg =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 -960 960 960"><path d="m136-240-56-56 296-298 160 160 208-206H640v-80h240v240h-80v-104L536-320 376-480 136-240Z"/></svg>';

  static const String _duesSvg =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 -960 960 960"><path d="M560-440q-50 0-85-35t-35-85q0-50 35-85t85-35q50 0 85 35t35 85q0 50-35 85t-85 35ZM280-320q-33 0-56.5-23.5T200-400v-320q0-33 23.5-56.5T280-800h560q33 0 56.5 23.5T920-720v320q0 33-23.5 56.5T840-320H280Zm80-80h400q0-33 23.5-56.5T840-480v-160q-33 0-56.5-23.5T760-720H360q0 33-23.5 56.5T280-640v160q33 0 56.5 23.5T360-400Zm440 240H120q-33 0-56.5-23.5T40-240v-400h80v400h680v80ZM280-400v-320 320Z"/></svg>';

  static const String _profileSvg =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 -960 960 960"><path d="M480-480q-66 0-113-47t-47-113q0-66 47-113t113-47q66 0 113 47t47 113q0 66-47 113t-113 47ZM160-240v-32q0-34 17.5-62.5T224-378q62-31 126-46.5T480-440q66 0 130 15.5T736-378q29 15 46.5 43.5T800-272v32q0 33-23.5 56.5T720-160H240q-33 0-56.5-23.5T160-240Z"/></svg>';

  final List<_NavItem> _navItems = const [
    _NavItem(label: 'Home', svg: _homeSvg),
    _NavItem(label: 'Leads', svg: _leadsSvg),
    _NavItem(label: 'Orders', svg: _ordersSvg),
    _NavItem(label: 'Cust.', svg: _customersSvg),
    _NavItem(label: 'Dues', svg: _duesSvg),
    _NavItem(label: 'Me', svg: _profileSvg),
  ];

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const SellerDashboardScreen(),
      const SellerLeadsScreen(),
      const SellerOrdersHubScreen(),
      const SellerCustomersScreen(),
      const SellerInstalmentsScreen(),
      const SellerProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: _SellerFloatingNavBar(
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

// ─── Colors ───────────────────────────────────────────────────────────────────

// Blue gradient — from accent to a lighter violet-blue
const _kSellerAccentStart = Color(0xFF3B5BDB); // accent
const _kSellerAccentEnd = Color(0xFF748FFC); // lighter periwinkle
const _kInactiveGrey = Color(0xFFB0B8C8); // cool slate grey for inactive

// ─── Floating Nav Bar Container ───────────────────────────────────────────────

class _SellerFloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _SellerFloatingNavBar({
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
              color: _kSellerAccentStart.withValues(alpha: 0.14),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
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

// ─── Active Pill ──────────────────────────────────────────────────────────────

class _ActivePill extends StatelessWidget {
  final _NavItem item;
  const _ActivePill({required this.item, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kSellerAccentStart, _kSellerAccentEnd],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _kSellerAccentStart.withValues(alpha: 0.38),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: SvgPicture.string(
          item.svg,
          width: 19,
          height: 19,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
      ),
    );
  }
}

// ─── Inactive Icon ────────────────────────────────────────────────────────────

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
          colorFilter: const ColorFilter.mode(_kInactiveGrey, BlendMode.srcIn),
        ),
        const SizedBox(height: 3),
        Text(
          item.label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _kInactiveGrey,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ─── Placeholder Page ─────────────────────────────────────────────────────────
