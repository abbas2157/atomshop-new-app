import 'package:atompro/core/auth/session_manager.dart';
import 'package:atompro/core/common/images/app_images.dart';
import 'package:atompro/core/common/utils/utils.dart';
import 'package:atompro/core/routes/app_navigator.dart';
import 'package:atompro/core/routes/app_route_constants.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late List<Animation<Offset>> _slideAnimations;
  late List<Animation<double>> _itemFadeAnimations;

  int _hoveredIndex = -1;

  final List<_NavItem> _navItems = [
    _NavItem(
      label: 'Home',
      subtitle: 'Back to home',
      icon: Icons.home_outlined,
      onTap: () => AppNavigator.clearStackAndPush(AppRoutes.homePage),
    ),
    _NavItem(
      label: 'Order Now',
      subtitle: 'Browse & buy instantly',
      icon: Icons.shopping_bag_outlined,
      onTap: () => AppNavigator.goToCustomOrder(),
    ),
    _NavItem(
      label: 'Make Offer',
      subtitle: 'Negotiate your price',
      icon: Icons.local_offer_outlined,
      onTap: () => AppNavigator.goToMakeOfferView(),
    ),

    ///
    _NavItem(
      label: 'Smart Seller',
      subtitle: 'Become a Smart Seller with AtomShop',
      icon: Icons.storefront_outlined, // Better for seller/store
      onTap: () => AppNavigator.goToSmartSellerHome(),
    ),
    _NavItem(
      label: 'Smart Supplier',
      subtitle: 'A chance to grow with us',
      icon: Icons.inventory_2_outlined, // Better for supplier/inventory
      onTap: () => AppNavigator.goToSmartSupplierHome(),
    ),
    ////
    _NavItem(
      label: 'Why AtomShop',
      subtitle: 'Our promise to you',
      icon: Icons.verified_outlined,
      onTap: () => AppNavigator.goToWhyAtomshop(),
    ),
  ];

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );

    _slideAnimations = List.generate(_navItems.length, (i) {
      final start = 0.2 + (i * 0.15);
      final end = (start + 0.35).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0.3, 0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });

    _itemFadeAnimations = List.generate(_navItems.length, (i) {
      final start = 0.2 + (i * 0.15);
      final end = (start + 0.35).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Responsive helpers ────────────────────────────────────────────────────

  /// Drawer width: 78% of screen, capped at 300 logical px
  double _drawerWidth(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    return (screenW * 0.78).clamp(240.0, 300.0);
  }

  /// Returns a size that scales between [min] and [max] based on screen width.
  /// Avoids ScreenUtil on dimensions that should respond to actual device width.
  double _scale(BuildContext context, double min, double max) {
    final w = MediaQuery.sizeOf(context).width;
    // 320 → min, 480+ → max
    final t = ((w - 320) / (480 - 320)).clamp(0.0, 1.0);
    return min + (max - min) * t;
  }

  @override
  Widget build(BuildContext context) {
    final drawerW = _drawerWidth(context);
    final hPad = _scale(context, 16, 24);
    final avatarSize = _scale(context, 40, 52);
    final headerVPad = _scale(context, 36, 48);

    return Drawer(
      width: drawerW,
      backgroundColor: Colors.white,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Column(
        children: [
          _buildHeader(
            hPad: hPad,
            avatarSize: avatarSize,
            headerVPad: headerVPad,
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: _scale(context, 20, 28)),

                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 10),
                      child: Text(
                        'MENU',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: _scale(context, 9, 11),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.0,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),

                  ...List.generate(_navItems.length, (i) {
                    return SlideTransition(
                      position: _slideAnimations[i],
                      child: FadeTransition(
                        opacity: _itemFadeAnimations[i],
                        child: _buildNavItem(_navItems[i], i, context),
                      ),
                    );
                  }),

                  const Spacer(),
                  _buildSocialSection(context),
                  SizedBox(height: _scale(context, 16, 24)),
                ],
              ),
            ),
          ),
          _buildFooter(context, hPad),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader({
    required double hPad,
    required double avatarSize,
    required double headerVPad,
  }) {
    return FutureBuilder(
      future: Future.wait([
        SessionManager.isLoggedIn(),
        SessionManager.getUserName(),
        SessionManager.getUserNameTwoCharchters(),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final bool loggedIn = snapshot.data![0] as bool;
        final String? userName = snapshot.data![1] as String?;
        final String? initials = snapshot.data![2] as String?;
        return _headerContent(
          context: context,
          userName: loggedIn ? (userName ?? 'User') : 'Guest User',
          initials: loggedIn ? (initials ?? 'U') : 'GU',
          hPad: hPad,
          avatarSize: avatarSize,
          headerVPad: headerVPad,
        );
      },
    );
  }

  Widget _headerContent({
    required BuildContext context,
    required String userName,
    required String initials,
    required double hPad,
    required double avatarSize,
    required double headerVPad,
  }) {
    final nameFontSize = _scale(context, 16, 20);
    final subFontSize = _scale(context, 10, 12);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: headerVPad,
        left: hPad,
        right: hPad,
        bottom: _scale(context, 14, 20),
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A3277), Color(0xFF213F9A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFD333), Color(0xFFFFA500)],
                  ),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: avatarSize * 0.34,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A3277),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),

          SizedBox(height: _scale(context, 10, 14)),

          Text(
            'Welcome back,',
            style: TextStyle(
              fontSize: subFontSize,
              color: Colors.white.withOpacity(0.55),
            ),
          ),

          SizedBox(height: 2),

          Text(
            userName,
            style: TextStyle(
              fontSize: nameFontSize,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── Nav item ──────────────────────────────────────────────────────────────

  Widget _buildNavItem(_NavItem item, int index, BuildContext context) {
    final isHovered = _hoveredIndex == index;
    final iconBoxSize = _scale(context, 32, 40);
    final iconSize = _scale(context, 16, 19);
    final labelSize = _scale(context, 13, 15);
    final subSize = _scale(context, 10, 12);
    final vPad = _scale(context, 10, 13);
    final hPad = _scale(context, 10, 13);

    return Padding(
      padding: EdgeInsets.only(bottom: _scale(context, 4, 7)),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredIndex = index),
        onExit: (_) => setState(() => _hoveredIndex = -1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: isHovered
                ? const Color(0xFFFFA500).withOpacity(0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHovered
                  ? const Color(0xFFFFA500).withOpacity(0.15)
                  : Colors.transparent,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: item.onTap,
              borderRadius: BorderRadius.circular(12),
              splashColor: const Color(0xFFFFA500).withOpacity(0.08),
              highlightColor: Colors.transparent,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: vPad, horizontal: hPad),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: iconBoxSize,
                      height: iconBoxSize,
                      decoration: BoxDecoration(
                        color: isHovered
                            ? const Color(0xFFFFA500).withOpacity(0.12)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        item.icon,
                        size: iconSize,
                        color: isHovered
                            ? const Color(0xFFFFA500)
                            : Colors.grey.shade500,
                      ),
                    ),
                    SizedBox(width: _scale(context, 10, 14)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: labelSize,
                              fontWeight: FontWeight.w600,
                              color: isHovered
                                  ? const Color(0xFF213F9A)
                                  : Colors.black87,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            item.subtitle,
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: subSize,
                              color: Colors.grey.shade400,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedSlide(
                      offset: isHovered ? const Offset(0.15, 0) : Offset.zero,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: _scale(context, 10, 13),
                        color: isHovered
                            ? const Color(0xFFFFA500)
                            : Colors.grey.shade300,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Social section ────────────────────────────────────────────────────────

  Widget _buildSocialSection(BuildContext context) {
    final labelSize = _scale(context, 8, 10);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Colors.grey.shade200,
                Colors.transparent,
              ],
            ),
          ),
        ),
        SizedBox(height: _scale(context, 14, 18)),
        Text(
          'CONNECT WITH US',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: labelSize,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.8,
            color: Colors.grey.shade400,
          ),
        ),
        SizedBox(height: _scale(context, 8, 12)),
        Row(
          children: [
            Flexible(
              child: _socialChip(
                context,
                AppImages.facebook,
                'Facebook',
                'https://www.facebook.com/atomshoppk',
                const Color(0xFF1877F2),
              ),
            ),
            SizedBox(width: _scale(context, 6, 10)),
            Flexible(
              child: _socialChip(
                context,
                AppImages.instagram,
                'Instagram',
                'https://www.instagram.com/atomshop.pk/',
                const Color(0xFFE1306C),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _socialChip(
    BuildContext context,
    String image,
    String label,
    String url,
    Color brandColor,
  ) {
    final chipFontSize = _scale(context, 10, 12);
    final imgSize = _scale(context, 14, 17);

    return GestureDetector(
      onTap: () => _launchUrl(url),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: _scale(context, 8, 12),
          vertical: _scale(context, 6, 8),
        ),
        decoration: BoxDecoration(
          color: brandColor.withOpacity(0.07),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: brandColor.withOpacity(0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: imgSize,
              height: imgSize,
              child: Image.asset(image, fit: BoxFit.contain),
            ),
            SizedBox(width: _scale(context, 5, 7)),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: chipFontSize,
                  fontWeight: FontWeight.w600,
                  color: brandColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────

  Widget _buildFooter(BuildContext context, double hPad) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: _scale(context, 0, 16),
        horizontal: hPad,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          navLogo(),
          const Spacer(),
          Text(
            'v2.1.0',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: _scale(context, 9, 11),
              color: Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class _NavItem {
  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}
