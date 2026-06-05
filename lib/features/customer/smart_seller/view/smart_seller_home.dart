import 'package:atompro/core/common/widgets/app_bar.dart';
import 'package:atompro/core/common/widgets/custom_button.dart';
import 'package:atompro/core/routes/app_navigator.dart';
import 'package:atompro/core/style/app_text_styles.dart';
import 'package:atompro/core/style/color_palette.dart';
import 'package:atompro/features/customer/drawer/view/drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class SmartSellerHome extends StatelessWidget {
  SmartSellerHome({super.key});
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _features = [
    (Icons.show_chart, "Live Sales & Revenue Tracking",
        "Track your sales, installment recoveries, and profitability in real time."),
    (Icons.payments_outlined, "Installment Payment Tracker",
        "Monitor all customer installment schedules and recovery status."),
    (Icons.campaign_outlined, "Shop Promotion & Campaigns",
        "Your shop and products featured in our app and digital campaigns."),
    (Icons.inventory_2_outlined, "No Product Limits",
        "Sell from pre-listed products, offer your own, or let us help you source."),
    (Icons.bar_chart_outlined, "Business Reports & Insights",
        "Download reports, monitor your growth, and make informed decisions."),
    (Icons.shopping_bag_outlined, "Orders Through Our Customer Apps",
        "Our mobile apps generate regular customer orders — you focus on selling."),
  ];

  static const _benefits = [
    ("Personalized Seller Panel Access",
        "Full control of your sales, customers, and recoveries."),
    ("Manual KYC with Direct Onboarding",
        "Our team visits your shop for verification — no automated approvals."),
    ("Seller Trainings",
        "Customer KYC, Installment & Recovery Handling, Best Practices for Sales Growth."),
    ("Product Sourcing Support",
        "We help you source genuine products if you can't find them yourself."),
    ("Branding for Premium Sellers",
        "Exclusive branding and marketing support when you qualify as Premium Seller."),
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
                      "SMART SELLER",
                      style: AppTextStyles.overline.copyWith(
                        color: Colors.white70,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Grow Your Business\nWith AtomShop",
                    style: AppTextStyles.h3.bold.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Platform, tools & hands-on support to help you succeed.",
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    title: "Become Seller",
                    onPressed: () => AppNavigator.goToSmartSellerForm(),
                    backgroundColor: Colors.white,
                    textColor: ColorPalette.secondary,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Dashboard Features ─────────────────────────────────────────────
            Container(
              color: ColorPalette.background,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(
                    "Dashboard Features",
                    Icons.dashboard_outlined,
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

            // ── Support & Benefits ─────────────────────────────────────────────
            Container(
              color: ColorPalette.background,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(
                    "Software Support & Benefits",
                    Icons.verified_outlined,
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(
                    _benefits.length,
                    (i) => _benefitTile(
                      context,
                      number: i + 1,
                      title: _benefits[i].$1,
                      description: _benefits[i].$2,
                    ),
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
                    "Ready to Become a\nSmart Seller?",
                    textAlign: TextAlign.center,
                    style: AppTextStyles.h4.bold.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Apply now and let's grow together!",
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    title: "Apply Now",
                    onPressed: () => AppNavigator.goToSmartSellerForm(),
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
        Text(title, style: AppTextStyles.h6.bold),
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

  Widget _benefitTile(
    BuildContext context, {
    required int number,
    required String title,
    required String description,
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
                Text(description, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
