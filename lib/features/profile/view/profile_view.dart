import 'package:atompro/core/auth/session_manager.dart';
import 'package:atompro/core/routes/app_navigator.dart';
import 'package:atompro/core/routes/app_route_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:atompro/core/style/color_palette.dart';

// ══════════════════════════════════════════════════════════════════════════════

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  bool _isLoggedIn = false;
  bool _loading = true;
  String? _userName;
  String? _initials;

  late final AnimationController _entryCtrl;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scaleIn;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fadeIn = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _scaleIn = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _loadSession();
  }

  Future<void> _loadSession() async {
    final loggedIn = await SessionManager.isLoggedIn();
    String? name, initials;
    if (loggedIn) {
      name = await SessionManager.getUserName();
      initials = await SessionManager.getUserNameTwoCharchters();
    }
    if (mounted) {
      setState(() {
        _isLoggedIn = loggedIn;
        _userName = name;
        _initials = initials;
        _loading = false;
      });
      _entryCtrl.forward();
    }
  }

  Future<void> _logout() async {
    try {
      HapticFeedback.mediumImpact();
      await _entryCtrl.reverse().orCancel.catchError((_) {});
      await SessionManager.logout();
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _userName = null;
          _initials = null;
        });
        _entryCtrl.forward();
      }
    } catch (e) {
      // Handle logout errors if necessary
    }
  }

  void _simulateLogin() {
    // In real app → Navigator.push(context, MaterialPageRoute(builder: (_) => LoginPage()))
    AppNavigator.goToAuthPage();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF2F5FB),
        body: Center(
          child: CircularProgressIndicator(color: ColorPalette.secondary),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F5FB),
        body: ScaleTransition(
          scale: _scaleIn,
          child: FadeTransition(
            opacity: _fadeIn,
            child: _isLoggedIn ? _buildLoggedIn() : _buildGuest(),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  LOGGED-IN
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildLoggedIn() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildHeader()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _label('My Account'),
              const SizedBox(height: 10),
              _group([
                _tile(
                  Icons.shopping_bag_outlined,
                  'My Orders & Installments',
                  () {
                    AppNavigator.goToMyOrders();
                  },
                ),
              ]),
              const SizedBox(height: 22),
              _label('Security'),
              const SizedBox(height: 10),
              _group([
                _tile(Icons.lock_outline_rounded, 'Change Password', () async {
                  AppNavigator.pushNamed(
                    AppRoutes.changePassword,
                    arguments: {'uuid': await SessionManager.getUserUuid()},
                  );
                }),
              ]),
              const SizedBox(height: 22),
              _label('Legal & Info'),
              const SizedBox(height: 10),
              _group([
                _tile(Icons.info_outline_rounded, 'About Us', () {
                  AppNavigator.goToAboutUs();
                }),
                _tile(
                  Icons.assignment_return_outlined,
                  'Return & Refund Policy',
                  () {
                    AppNavigator.goToReturnRefundPolicy();
                  },
                ),
                _tile(Icons.privacy_tip_outlined, 'Privacy Policy', () {
                  AppNavigator.goToPrivacyPolicy();
                }),
                _tile(Icons.description_outlined, 'Terms & Conditions', () {
                  AppNavigator.goToTermsAndConditions();
                }),
                _tile(Icons.article_outlined, 'Terms of Use (EULA)', () {
                  AppNavigator.gotTermsOfUse();
                }),
              ]),
              const SizedBox(height: 30),
              _ActionButton(
                label: 'Logout',
                icon: Icons.logout_rounded,
                tonal: true,
                color: ColorPalette.secondary,
                onTap: () => _confirm(
                  icon: Icons.logout_rounded,
                  title: 'Logout?',
                  body: 'You will be signed out of your account.',
                  cta: 'Logout',
                  ctaColor: ColorPalette.secondary,
                  action: _logout,
                ),
              ),
              const SizedBox(height: 12),
              _ActionButton(
                label: 'Delete My Account',
                icon: Icons.delete_outline_rounded,
                tonal: false,
                color: ColorPalette.error,
                onTap: () => _confirm(
                  icon: Icons.delete_outline_rounded,
                  title: 'Delete Account?',
                  body:
                      'All your orders, history, and profile will be permanently erased and cannot be recovered.',
                  cta: 'Yes, Delete',
                  ctaColor: ColorPalette.error,
                  action: _logout,
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  // ── Header without a wasteful blue block ──────────────────────────────────
  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar
            Row(
              children: [
                _iconBtn(Icons.arrow_back_ios, () {
                  AppNavigator.getBack();
                }),
                SizedBox(width: 30),
                const Text(
                  'AtomShop',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: ColorPalette.textPrimary,
                    letterSpacing: -0.6,
                  ),
                ),
                const Spacer(),
                _iconBtn(Icons.notifications_none_rounded, () {
                  AppNavigator.goToNotifications();
                }),
                // const SizedBox(width: 8),
                // _iconBtn(Icons.settings_outlined, () {}),
              ],
            ),
            const SizedBox(height: 18),

            // Identity card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: ColorPalette.secondaryGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: ColorPalette.secondary.withOpacity(0.26),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _initials ?? '?',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userName ?? 'User',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: const Color(0xFF50FAB0),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF50FAB0,
                                    ).withOpacity(0.7),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Active Account',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Edit pill
                  GestureDetector(
                    onTap: () {
                      AppNavigator.goToEditProfile();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.28),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 13,
                            color: Colors.white,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Edit',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  GUEST / LOGGED-OUT
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildGuest() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Top bar
            Row(
              children: [
                _iconBtn(Icons.arrow_back_ios, () {
                  AppNavigator.getBack();
                }),
                SizedBox(width: 30),
                const Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: ColorPalette.textPrimary,
                    letterSpacing: -0.6,
                  ),
                ),
              ],
            ),
            const Spacer(flex: 2),
            // Illustration
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: ColorPalette.secondaryGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: ColorPalette.secondary.withOpacity(0.3),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: Colors.white,
                size: 44,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'You\'re not logged in',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: ColorPalette.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Sign in to access your orders,\ninstallments, and account settings.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: ColorPalette.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 30),
            _ActionButton(
              label: 'Login to your Account',
              icon: Icons.login_rounded,
              tonal: false,
              filled: true,
              color: ColorPalette.secondary,
              onTap: _simulateLogin,
            ),
            const Spacer(flex: 2),
            _label('Information'),
            const SizedBox(height: 10),
            _group([
              _tile(Icons.info_outline_rounded, 'About Us', () {
                AppNavigator.goToAboutUs();
              }),
              _tile(
                Icons.assignment_return_outlined,
                'Return & Refund Policy',
                () {
                  AppNavigator.goToReturnRefundPolicy();
                },
              ),
              _tile(Icons.privacy_tip_outlined, 'Privacy Policy', () {
                AppNavigator.goToPrivacyPolicy();
              }),
              _tile(Icons.description_outlined, 'Terms & Conditions', () {
                AppNavigator.goToTermsAndConditions();
              }),
              _tile(Icons.article_outlined, 'Terms of Use (EULA)', () {
                AppNavigator.gotTermsOfUse();
              }),
            ]),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  SHARED COMPONENTS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(left: 2),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: ColorPalette.secondary,
        letterSpacing: 2.2,
      ),
    ),
  );

  Widget _group(List<Widget> tiles) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF213F9A).withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: List.generate(tiles.length, (i) {
          return Column(
            children: [
              tiles[i],
              if (i < tiles.length - 1)
                Divider(height: 1, indent: 58, color: ColorPalette.border),
            ],
          );
        }),
      ),
    );
  }

  Widget _tile(IconData icon, String label, Function() onTap, {String? badge}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          onTap();
          await HapticFeedback.selectionClick();
        },
        borderRadius: BorderRadius.circular(18),
        splashColor: ColorPalette.secondary.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFECF0FF),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 18, color: ColorPalette.secondary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: ColorPalette.textPrimary,
                  ),
                ),
              ),
              if (badge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: ColorPalette.secondary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Color(0xFFBCC5D6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, Function() ontap) => GestureDetector(
    onTap: ontap,
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
      child: Icon(icon, size: 20, color: ColorPalette.textPrimary),
    ),
  );

  void _confirm({
    required IconData icon,
    required String title,
    required String body,
    required String cta,
    required Color ctaColor,
    required VoidCallback action,
  }) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ConfirmSheet(
        icon: icon,
        title: title,
        body: body,
        cta: cta,
        ctaColor: ctaColor,
        action: action,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  ACTION BUTTON  (press-scale micro-interaction)
// ══════════════════════════════════════════════════════════════════════════════
class _ActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool tonal;
  final bool filled;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.tonal,
    this.filled = false,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isGradient = widget.filled;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: isGradient
                ? const LinearGradient(
                    colors: ColorPalette.secondaryGradient,
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: isGradient
                ? null
                : (widget.tonal
                      ? Colors.white
                      : widget.color.withOpacity(0.08)),
            borderRadius: BorderRadius.circular(15),
            border: isGradient
                ? null
                : Border.all(
                    color: widget.color.withOpacity(widget.tonal ? 0.35 : 0.2),
                    width: 1.5,
                  ),
            boxShadow: isGradient
                ? [
                    BoxShadow(
                      color: widget.color.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : widget.tonal
                ? [
                    BoxShadow(
                      color: widget.color.withOpacity(0.07),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  color: isGradient ? Colors.white : widget.color,
                  size: 18,
                ),
                const SizedBox(width: 9),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: isGradient ? Colors.white : widget.color,
                    letterSpacing: 0.1,
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

// ══════════════════════════════════════════════════════════════════════════════
//  CONFIRM BOTTOM SHEET
// ══════════════════════════════════════════════════════════════════════════════
class _ConfirmSheet extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String cta;
  final Color ctaColor;
  final VoidCallback action;

  const _ConfirmSheet({
    required this.icon,
    required this.title,
    required this.body,
    required this.cta,
    required this.ctaColor,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 34,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFDDE3F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 22),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: ctaColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: ctaColor, size: 26),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: ColorPalette.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: ColorPalette.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F5FB),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: ColorPalette.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    action();
                  },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: ctaColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: ctaColor.withOpacity(0.3),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        cta,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
