import 'package:atompro/core/common/widgets/app_bar.dart';
import 'package:atompro/core/common/widgets/custom_button.dart';
import 'package:atompro/core/routes/app_navigator.dart';
import 'package:atompro/core/style/app_text_styles.dart';
import 'package:atompro/core/style/color_palette.dart';
import 'package:atompro/core/style/extensions.dart';
import 'package:atompro/features/drawer/view/drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:atompro/core/common/widgets/app_cached_image.dart';

class SmartSellerHome extends StatelessWidget {
  SmartSellerHome({super.key});
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: ColorPalette.background,
      appBar: buildAppBar(context, () {
        _scaffoldKey.currentState
            ?.openDrawer(); // <--- Use the key instead of context
      }),
      drawer: AppDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Column(
              children: [
                SizedBox(height: context.h(30)),
                RichText(
                  textAlign: TextAlign.left,

                  text: TextSpan(
                    style: AppTextStyles.h4,
                    children: [
                      TextSpan(text: "The ", style: AppTextStyles.h5.bold),
                      TextSpan(
                        text: "Smart Seller ",
                        style: AppTextStyles.h5.bold.copyWith(
                          color: ColorPalette.primaryLight,
                        ),
                      ),
                      TextSpan(
                        text: " - Powered by AtomShop",
                        style: AppTextStyles.h5.bold,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: context.h(10)),

                Text(
                  textAlign: TextAlign.left,
                  "Become a Smart Seller with AtomShop and grow your business with confidence. We provide the platform, tools, and hands-on support you need to succeed.",
                ),
                SizedBox(height: context.h(10)),

                CustomButton(
                  width: context.w(150),
                  title: "Become Seller",
                  onPressed: () {
                    AppNavigator.goToSmartSellerForm();
                  },
                  backgroundColor: ColorPalette.primaryLight,
                  textColor: Colors.black,
                ).alignTopLeft,
                SizedBox(height: context.h(20)),

                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AppCachedImage(
                    imageUrl: "https://atomshop.pk/public/web/img/seller.png",
                  ),
                ),
                SizedBox(height: context.h(30)),

                Text(
                  "Smart Seller Dashboard Features",
                  style: AppTextStyles.h4.bold,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: context.h(20)),

                ////////// 1
                _smartSellerFeaturesWidget(
                  context: context,
                  icon: Icons.show_chart,
                  title: "Live Sales & Revenue Tracking",
                  description:
                      "Track your sales, installment recoveries, and profitability in real time.",
                ),

                _smartSellerFeaturesWidget(
                  context: context,

                  icon: Icons.payments_outlined,
                  title: "Installment Payment Tracker",
                  description:
                      "Your shop and products featured in our app and digital campaigns.",
                ),

                _smartSellerFeaturesWidget(
                  context: context,

                  icon: Icons.campaign_outlined,
                  title: "Shop Promotion & Campaigns",
                  description:
                      "Your shop and products featured in our app and digital campaigns.",
                ),

                _smartSellerFeaturesWidget(
                  context: context,

                  icon: Icons.inventory_2_outlined,
                  title: "No Product Limits",
                  description:
                      "Sell from our pre-listed products, offer your own custom products, or let us help you source products.",
                ),

                _smartSellerFeaturesWidget(
                  context: context,

                  icon: Icons.bar_chart_outlined,
                  title: "Business Reports & Insights",
                  description:
                      "Download reports, monitor your growth, and make informed decisions.",
                ),

                _smartSellerFeaturesWidget(
                  context: context,

                  icon: Icons.shopping_bag_outlined,
                  title: "Orders Through Our Customer Apps",
                  description:
                      "Our mobile apps generate regular customer orders — you focus on selling.",
                ),
                SizedBox(height: context.h(10)),

                Text(
                  "Software Support, Trainings & Seller Benefits",
                  style: AppTextStyles.h5.bold,
                  textAlign: TextAlign.left,
                ),
                SizedBox(height: context.h(10)),

                _buildBenifitsWidget(
                  context: context,
                  title: "Personalized Seller Panel Access",
                  description:
                      "Personalized Seller Panel Access,full control of your sales, customers, and recoveries.",
                ),
                _buildBenifitsWidget(
                  context: context,

                  title: "Manual KYC with Direct Onboarding",
                  description:
                      "Our team visits your shop for verification and onboarding — no automated approvals",
                ),
                _buildBenifitsWidget(
                  context: context,

                  title: "Seller Trainings",
                  description:
                      "Customer KYC Process.\nInstallment & Recovery Handling.\nBest Practices for Sales Growth.",
                ),
                _buildBenifitsWidget(
                  context: context,

                  title: "Product Sourcing Support",
                  description:
                      "We help you source genuine products if you can't find them yourself.",
                ),
                _buildBenifitsWidget(
                  context: context,

                  title: "Branding for Premium Sellers",
                  description:
                      "Get exclusive branding and marketing support when you qualify as a Premium Seller.",
                ),
                SizedBox(height: context.h(20)),
                SizedBox(
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: context.w(80)),
                        child: AppCachedImage(
                          imageUrl:
                              "https://atomshop.pk/public/web/img/SoftwareSupport.png",
                          height: context.h(180),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        child: AppCachedImage(
                          height: context.h(100),

                          imageUrl:
                              "https://atomshop.pk/public/web/img/SoftwareSupport1.png",
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: context.h(30)),
              ],
            ).paddingHorizontal(16),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.w(20),
                vertical: context.h(40),
              ),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomRight,
                  end: Alignment.topLeft,
                  colors: [
                    Color(0xFFEECA47),
                    Color(0xFFCAB673),
                    Color(0xFF9397B5),
                    Color(0xFF7687D6),
                  ],
                ),
              ),
              child: Column(
                children: [
                  Text(
                    textAlign: TextAlign.center,
                    "Ready to Become a Smart Seller?",
                    style: AppTextStyles.h3.bold.white,
                  ),
                  SizedBox(height: 10),
                  Text(
                    textAlign: TextAlign.center,
                    "Apply now through our Sell on AtomShop Seller Signup form — and let's grow together!",
                    style: AppTextStyles.bodyLarge.white,
                  ),
                  SizedBox(height: 20),
                  CustomButton(
                    title: "Become Seller",
                    onPressed: () {
                      AppNavigator.goToSmartSellerForm();
                    },
                    width: context.w(200),
                    backgroundColor: Colors.white,
                    textColor: Colors.black,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Container _buildBenifitsWidget({
    required BuildContext context,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Color(0xFFE9ECEF),
      ),
      padding: EdgeInsets.only(left: 20, right: 40, top: 20, bottom: 30),
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.h6.bold),
          SizedBox(height: context.h(10)),

          Text(description, style: AppTextStyles.bodyLarge),
        ],
      ),
    );
  }

  Container _smartSellerFeaturesWidget({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 40),
      margin: EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: ColorPalette.accentBlue, size: 28),
          SizedBox(height: context.h(10)),

          Text(title, style: AppTextStyles.h6.bold),
          SizedBox(height: context.h(10)),

          Text(description, style: AppTextStyles.bodyLarge),
        ],
      ),
    );
  }
}
