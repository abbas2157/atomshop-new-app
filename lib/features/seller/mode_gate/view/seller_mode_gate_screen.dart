import 'package:atompro/core/mode/app_mode_manager.dart';
import 'package:atompro/core/routes/app_navigator.dart';
import 'package:atompro/core/style/color_palette.dart';
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
    return const Scaffold(
      backgroundColor: ColorPalette.background,
      body: Center(
        child: CircularProgressIndicator(color: ColorPalette.secondary),
      ),
    );
  }
}
