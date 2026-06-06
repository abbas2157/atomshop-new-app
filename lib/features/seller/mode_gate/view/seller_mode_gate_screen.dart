import 'package:atompro/core/mode/app_mode_manager.dart';
import 'package:atompro/core/routes/app_navigator.dart';
import 'package:atompro/features/seller/core/design/design.dart';
import 'package:flutter/material.dart';

class SellerModeGateScreen extends StatefulWidget {
  const SellerModeGateScreen({super.key});

  @override
  State<SellerModeGateScreen> createState() => _SellerModeGateScreenState();
}

class _SellerModeGateScreenState extends State<SellerModeGateScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveRoute());
  }

  Future<void> _resolveRoute() async {
    await AppModeManager.switchToSeller();
    final route = await AppModeManager.resolveSellerLandingRoute();
    if (!mounted) return;
    await AppNavigator.clearStackAndPush(route);
  }

  @override
  Widget build(BuildContext context) {
    // Pushed as its own route → wrap in the seller theme scope for dark mode.
    return SellerThemeScope(
      child: Builder(
        builder: (context) {
          final c = context.sellerColors;
          return Scaffold(
            backgroundColor: c.canvas,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: c.headerGradient,
                      borderRadius: AppRadius.brXl,
                      boxShadow: c.floatingShadow,
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const Gap.v(AppSpace.lg),
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: c.accent,
                    ),
                  ),
                  const Gap.v(AppSpace.md),
                  Text('Entering Seller Mode', style: context.sellerText.bodySm),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
