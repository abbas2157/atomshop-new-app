import 'package:atompro/core/auth/session_manager.dart';
import 'package:atompro/core/common/images/app_images.dart';
import 'package:atompro/core/common/utils/utils.dart';
import 'package:atompro/core/routes/app_navigator.dart';
import 'package:atompro/core/routes/app_route_constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Fixed visual constants
// ─────────────────────────────────────────────────────────────────────────────
const _kBlue1 = Color(0xFF1A3277);
const _kBlue2 = Color(0xFF213F9A);
const _kGold1 = Color(0xFFFFD333);
const _kGold2 = Color(0xFFFFA500);
const _kFacebook = Color(0xFF1877F2);
const _kInstagram = Color(0xFFE1306C);

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
    _NavItem(
      label: 'Smart Seller',
      subtitle: 'Become a Smart Seller',
      icon: Icons.storefront_outlined,
      onTap: () => AppNavigator.goToSmartSellerHome(),
    ),
    _NavItem(
      label: 'Smart Supplier',
      subtitle: 'A chance to grow with us',
      icon: Icons.inventory_2_outlined,
      onTap: () => AppNavigator.goToSmartSupplierHome(),
    ),
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
      duration: const Duration(milliseconds: 550),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );

    _slideAnimations = List.generate(_navItems.length, (i) {
      final start = (0.15 + i * 0.10).clamp(0.0, 1.0);
      final end = (start + 0.28).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0.25, 0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });

    _itemFadeAnimations = List.generate(_navItems.length, (i) {
      final start = (0.15 + i * 0.10).clamp(0.0, 1.0);
      final end = (start + 0.28).clamp(0.0, 1.0);
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

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenH = mq.size.height;
    final screenW = mq.size.width;
    final statusBarH = mq.padding.top;
    final bottomInset = mq.padding.bottom;

    final drawerW = (screenW * 0.78).clamp(240.0, 300.0);
    final hPad = (drawerW * 0.072).clamp(14.0, 22.0);

    // ── Height budget ─────────────────────────────────────────────────────
    // Footer: top border(1) + top padding(10) + content(36) + bottom inset
    final footerH = 1.0 + 10.0 + 36.0 + (bottomInset > 0 ? bottomInset : 10.0);

    // Header: 22% of screen, clamped so it never dominates small screens
    final headerH = (screenH * 0.22).clamp(108.0, 158.0);

    // Body = everything between header and footer
    final bodyH = screenH - headerH - footerH;

    // Social block: 19% of body, clamped
    final socialH = (bodyH * 0.19).clamp(70.0, 88.0);

    // Menu label row
    const menuLabelH = 26.0;
    final menuTopGap = (bodyH * 0.030).clamp(5.0, 14.0);
    final menuBottomGap = (bodyH * 0.015).clamp(3.0, 8.0);

    // Per-item height — fills all leftover space
    final menuH = bodyH - socialH - menuLabelH - menuTopGap - menuBottomGap;
    final itemH = (menuH / _navItems.length).clamp(38.0, 66.0);

    // Derive all sizes from itemH so everything scales together
    final iconBoxSize = (itemH * 0.52).clamp(22.0, 36.0);
    final iconSize = iconBoxSize * 0.48;
    final labelSize = (itemH * 0.225).clamp(10.5, 14.5);
    final subSize = (itemH * 0.165).clamp(8.5, 11.5);
    final showSubtitle = itemH >= 48.0;

    // Avatar from header budget
    final avatarSize = (headerH * 0.27).clamp(34.0, 48.0);

    return Drawer(
      width: drawerW,
      backgroundColor: Colors.white,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      // Use a plain Column — every child has an exact height, zero overflow
      child: Column(
        children: [
          // ── Header ───────────────────────────────────────────────────────
          SizedBox(
            height: headerH,
            child: _buildHeader(
              statusBarH: statusBarH,
              avatarSize: avatarSize,
              hPad: hPad,
              headerH: headerH,
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────────
          SizedBox(
            height: bodyH,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: menuTopGap),

                  // "MENU" label
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SizedBox(
                      height: menuLabelH,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: Text(
                            'MENU',
                            style: TextStyle(
                              fontSize: (menuLabelH * 0.38).clamp(8.0, 11.0),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.0,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Nav items — each pinned to exactly itemH
                  ...List.generate(_navItems.length, (i) {
                    return SlideTransition(
                      position: _slideAnimations[i],
                      child: FadeTransition(
                        opacity: _itemFadeAnimations[i],
                        child: SizedBox(
                          height: itemH,
                          child: _buildNavItem(
                            _navItems[i],
                            i,
                            iconBoxSize: iconBoxSize,
                            iconSize: iconSize,
                            labelSize: labelSize,
                            subSize: subSize,
                            showSubtitle: showSubtitle,
                          ),
                        ),
                      ),
                    );
                  }),

                  SizedBox(height: menuBottomGap),

                  // Social — pinned to exactly socialH, always visible
                  SizedBox(
                    height: socialH,
                    child: _buildSocialSection(socialH: socialH),
                  ),
                ],
              ),
            ),
          ),

          // ── Footer ───────────────────────────────────────────────────────
          _buildFooter(hPad: hPad, footerH: footerH, bottomInset: bottomInset),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader({
    required double statusBarH,
    required double avatarSize,
    required double hPad,
    required double headerH,
  }) {
    return FutureBuilder(
      future: Future.wait([
        SessionManager.isLoggedIn(),
        SessionManager.getUserName(),
        SessionManager.getUserNameTwoCharchters(),
      ]),
      builder: (context, snapshot) {
        final bool loggedIn = snapshot.hasData
            ? (snapshot.data![0] as bool)
            : false;
        final String userName = snapshot.hasData
            ? ((snapshot.data![1] as String?) ?? 'User')
            : '';
        final String initials = snapshot.hasData
            ? ((snapshot.data![2] as String?) ?? 'U')
            : '';

        final contentH = headerH - statusBarH;
        final nameFontSize = (contentH * 0.155).clamp(12.0, 18.0);
        final subFontSize = (contentH * 0.10).clamp(9.0, 11.5);

        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_kBlue1, _kBlue2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              SizedBox(height: statusBarH),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Avatar
                          Container(
                            width: avatarSize,
                            height: avatarSize,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [_kGold1, _kGold2],
                              ),
                            ),
                            child: Center(
                              child: Text(
                                loggedIn ? initials : 'GU',
                                style: TextStyle(
                                  fontSize: avatarSize * 0.34,
                                  fontWeight: FontWeight.w700,
                                  color: _kBlue1,
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Close
                          Builder(
                            builder: (ctx) => GestureDetector(
                              onTap: () => Navigator.of(ctx).pop(),
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: (contentH * 0.08).clamp(5.0, 11.0)),
                      Text(
                        'Welcome back,',
                        style: TextStyle(
                          fontSize: subFontSize,
                          color: Colors.white.withOpacity(0.55),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        loggedIn ? userName : 'Guest User',
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
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Nav item ──────────────────────────────────────────────────────────────

  Widget _buildNavItem(
    _NavItem item,
    int index, {
    required double iconBoxSize,
    required double iconSize,
    required double labelSize,
    required double subSize,
    required bool showSubtitle,
  }) {
    final isHovered = _hoveredIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = -1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(vertical: 1),
        decoration: BoxDecoration(
          color: isHovered ? _kGold2.withOpacity(0.06) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isHovered ? _kGold2.withOpacity(0.15) : Colors.transparent,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: item.onTap,
            borderRadius: BorderRadius.circular(10),
            splashColor: _kGold2.withOpacity(0.08),
            highlightColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: iconBoxSize,
                    height: iconBoxSize,
                    decoration: BoxDecoration(
                      color: isHovered
                          ? _kGold2.withOpacity(0.12)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      item.icon,
                      size: iconSize,
                      color: isHovered ? _kGold2 : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: labelSize,
                            fontWeight: FontWeight.w600,
                            color: isHovered ? _kBlue2 : Colors.black87,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (showSubtitle) ...[
                          const SizedBox(height: 1),
                          Text(
                            item.subtitle,
                            style: TextStyle(
                              fontSize: subSize,
                              color: Colors.grey.shade400,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  AnimatedSlide(
                    offset: isHovered ? const Offset(0.15, 0) : Offset.zero,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: (iconSize * 0.60).clamp(7.0, 11.0),
                      color: isHovered ? _kGold2 : Colors.grey.shade300,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Social section ────────────────────────────────────────────────────────

  Widget _buildSocialSection({required double socialH}) {
    // Derive every measurement from socialH — nothing can overflow
    final topGap = (socialH * 0.09).clamp(4.0, 9.0);
    final labelFontSize = (socialH * 0.13).clamp(7.5, 10.0);
    final labelGap = (socialH * 0.08).clamp(3.0, 8.0);
    // chipH gets whatever is left after divider(1) + topGap + label + labelGap
    final chipH = (socialH - 1 - topGap - labelFontSize * 1.4 - labelGap).clamp(
      26.0,
      38.0,
    );
    final imgSize = (chipH * 0.44).clamp(12.0, 17.0);
    final chipFontSize = (chipH * 0.28).clamp(8.5, 12.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Divider
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
        SizedBox(height: topGap),
        Text(
          'CONNECT WITH US',
          style: TextStyle(
            fontSize: labelFontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
            color: Colors.grey.shade400,
          ),
        ),
        SizedBox(height: labelGap),
        // Always side by side, Expanded fills exactly half each
        Row(
          children: [
            Expanded(
              child: _socialChip(
                image: AppImages.facebook,
                label: 'Facebook',
                url: 'https://www.facebook.com/atomshoppk',
                brandColor: _kFacebook,
                chipH: chipH,
                imgSize: imgSize,
                fontSize: chipFontSize,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _socialChip(
                image: AppImages.instagram,
                label: 'Instagram',
                url: 'https://www.instagram.com/atomshop.pk/',
                brandColor: _kInstagram,
                chipH: chipH,
                imgSize: imgSize,
                fontSize: chipFontSize,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _socialChip({
    required String image,
    required String label,
    required String url,
    required Color brandColor,
    required double chipH,
    required double imgSize,
    required double fontSize,
  }) {
    return GestureDetector(
      onTap: () => _launchUrl(url),
      child: Container(
        height: chipH,
        decoration: BoxDecoration(
          color: brandColor.withOpacity(0.07),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: brandColor.withOpacity(0.18)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: imgSize,
              height: imgSize,
              child: CachedNetworkImage(imageUrl: image, fit: BoxFit.contain),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: brandColor,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────

  Widget _buildFooter({
    required double hPad,
    required double footerH,
    required double bottomInset,
  }) {
    return Container(
      height: footerH,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      padding: EdgeInsets.only(
        top: 10,
        bottom: bottomInset > 0 ? bottomInset : 10,
        left: hPad,
        right: hPad,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          navLogo(),
          const Spacer(),
          Text(
            'v2.1.0',
            style: TextStyle(fontSize: 9, color: Colors.grey.shade300),
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
