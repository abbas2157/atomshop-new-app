import 'package:atompro/core/common/widgets/app_bar.dart';
import 'package:atompro/core/common/widgets/custom_button.dart';
import 'package:atompro/core/routes/app_navigator.dart';
import 'package:atompro/core/style/app_text_styles.dart';
import 'package:atompro/core/style/color_palette.dart';
import 'package:atompro/features/customer/drawer/view/drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class SmartSupplierHome extends StatelessWidget {
  SmartSupplierHome({super.key});
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _features = [
    (Icons.attach_money, "Instant Cash Sales",
        "We purchase products from you at market price — fast and hassle-free."),
    (Icons.campaign, "Free Marketing",
        "Your shop and products featured in our app and digital campaigns."),
    (Icons.storefront, "Extra Footfall",
        "Customers looking for installment plans will visit you directly."),
    (Icons.money_off, "No Upfront Investment",
        "No fees, no tech hassle — we handle everything!"),
    (Icons.qr_code, "Tracking Code System",
        "Every customer you refer is tracked via your unique Supplier Code."),
  ];

  static const _steps = [
    "Register with us and get your supplier code.",
    "Display our Small Branded Board at your shop.",
    "Keep our App QR Code visible for customer scans.",
    "Briefly guide customers who inquire about installments.",
    "Notify us with the Supplier Code for each potential order.",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: ColorPalette.backgroundGray,
      appBar: buildAppBar(context, () {
        _scaffoldKey.currentState?.openDrawer();
      }, true),
      drawer: AppDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Hero ──────────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              color: ColorPalette.secondary,
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "SMART SUPPLIER",
                      style: AppTextStyles.overline.copyWith(
                        color: Colors.white70,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Partner With AtomShop\n& Reach New Customers",
                    style: AppTextStyles.h3.bold.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Simple, scalable, and rewarding — no cost, no complexity.",
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    title: "Become Partner",
                    onPressed: () => AppNavigator.goToSmartSupplierForm(),
                    backgroundColor: Colors.white,
                    textColor: ColorPalette.secondary,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Partner Benefits ───────────────────────────────────────────────
            Container(
              color: ColorPalette.background,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(
                    "What You Get as a Supplier Partner",
                    Icons.card_giftcard_outlined,
                  ),
                  const SizedBox(height: 12),
                  ..._features.map(
                    (f) => _featureTile(
                      context,
                      icon: f.$1,
                      title: f.$2,
                      subtitle: f.$3,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── How to Start ───────────────────────────────────────────────────
            Container(
              color: ColorPalette.background,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader("How to Start", Icons.rocket_launch_outlined),
                  const SizedBox(height: 12),
                  ...List.generate(
                    _steps.length,
                    (i) => _stepTile(context, number: i + 1, step: _steps[i]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── CTA ────────────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              color: ColorPalette.secondary,
              padding: EdgeInsets.fromLTRB(20, context.h(28), 20, context.h(48)),
              child: Column(
                children: [
                  Text(
                    "Become Partner\nAnd Earn More",
                    textAlign: TextAlign.center,
                    style: AppTextStyles.h4.bold.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Join AtomShop today — sell more, earn more, stress less.",
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    title: "Become Partner",
                    onPressed: () => AppNavigator.goToSmartSupplierForm(),
                    width: context.w(200),
                    backgroundColor: Colors.white,
                    textColor: ColorPalette.secondary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: ColorPalette.secondary, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(title, style: AppTextStyles.h6.bold)),
      ],
    );
  }

  Widget _featureTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ColorPalette.backgroundBlueLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: ColorPalette.secondary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepTile(
    BuildContext context, {
    required int number,
    required String step,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: ColorPalette.secondary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                "$number",
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(step, style: AppTextStyles.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }
}
