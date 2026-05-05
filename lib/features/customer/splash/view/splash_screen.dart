import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:atompro/core/auth/seller_session_manager.dart';
import 'package:atompro/core/mode/app_mode.dart';
import 'package:atompro/core/mode/app_mode_manager.dart';
import 'package:atompro/core/style/color_palette.dart';
import 'package:atompro/core/auth/session_manager.dart';
import 'package:atompro/core/routes/app_navigator.dart';
import 'package:atompro/core/routes/app_route_constants.dart';
import 'package:atompro/core/common/utils/utils.dart'; // For your logo()

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.5, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove(); // Native splash exits, your animation takes over
    });
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    final mode = await AppModeManager.getMode();
    if (!mounted) return;

    if (mode == AppMode.seller) {
      final sellerLoggedIn = await SellerSessionManager.isLoggedIn();
      if (!mounted) return;
      AppNavigator.clearStackAndPush(
        sellerLoggedIn ? AppRoutes.sellerShell : AppRoutes.sellerLogin,
      );
      return;
    }

    final bool loggedIn = await SessionManager.isLoggedIn();
    if (!mounted) return;

    if (loggedIn) {
      final bool isAgent = await SessionManager.isAgent();
      if (!mounted) return;

      if (isAgent) {
        AppNavigator.clearStackAndPush(AppRoutes.smartsellerform);
        return;
      }
    }

    AppNavigator.clearStackAndPush(AppRoutes.bottomnavbar);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.background,
      body: Stack(
        children: [
          // Background Decorative Shapes
          Positioned(
            top: -100,
            right: -50,
            child: _buildCircle(200, ColorPalette.secondary.withOpacity(0.1)),
          ),
          Positioned(
            bottom: -50,
            left: -80,
            child: _buildCircle(250, ColorPalette.primary.withOpacity(0.05)),
          ),
          Positioned(
            top: 200,
            left: 20,
            child: _buildCircle(
              50,
              ColorPalette.secondaryLight.withOpacity(0.15),
            ),
          ),

          // Central Logo & Text
          Center(
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    logo(), // Your custom logo widget
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ColorPalette.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
