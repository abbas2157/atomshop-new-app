import 'package:atompro/core/common/widgets/app_bar.dart';
import 'package:atompro/core/common/widgets/app_cached_image.dart';
import 'package:atompro/core/common/widgets/custom_button.dart';
import 'package:atompro/core/routes/app_navigator.dart';
import 'package:atompro/core/style/app_text_styles.dart';
import 'package:atompro/core/style/color_palette.dart';
import 'package:atompro/core/style/extensions.dart';
import 'package:atompro/features/drawer/view/drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class SmartSupplierHome extends StatelessWidget {
  SmartSupplierHome({super.key});
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
                      TextSpan(
                        text: "Partner with ",
                        style: AppTextStyles.h5.bold,
                      ),
                      TextSpan(
                        text: "AtomShop ",
                        style: AppTextStyles.h5.bold.copyWith(
                          color: ColorPalette.primaryLight,
                        ),
                      ),
                      TextSpan(
                        text: "& Reach Thousands of ",
                        style: AppTextStyles.h5.bold,
                      ),
                      TextSpan(
                        text: "New Customers ",
                        style: AppTextStyles.h5.bold.copyWith(
                          color: ColorPalette.primaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: context.h(10)),

                Text(
                  textAlign: TextAlign.left,
                  "At AtomShop.pk, we believe every shopkeeper deserves a chance to grow — without the cost and complexity of building their own e-commerce system. That’s why we’ve created a platform that makes selling online simple, scalable, and rewarding.",
                ),
                SizedBox(height: context.h(10)),

                CustomButton(
                  width: context.w(180),
                  title: "Become Partner",
                  onPressed: () {
                    AppNavigator.goToSmartSupplierForm();
                  },
                  backgroundColor: ColorPalette.primaryLight,
                  textColor: Colors.black,
                ).alignTopLeft,
                SizedBox(height: context.h(20)),

                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AppCachedImage(
                    imageUrl: "https://atomshop.pk/public/web/img/partner.png",
                  ),
                ),
                SizedBox(height: context.h(30)),

                Text(
                  "What You Get as a Supplier Partner",
                  style: AppTextStyles.h4.bold,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: context.h(20)),

                ////////// 1
                _smartSellerFeaturesWidget(
                  context: context,
                  icon: Icons.attach_money, // Better for cash sales
                  title: "Instant Cash Sales",
                  description: "We purchase products from you at market price.",
                ),

                ////////// 2
                _smartSellerFeaturesWidget(
                  context: context,
                  icon: Icons.campaign, // Marketing promotion icon
                  title: "Free Marketing",
                  description:
                      "Your shop and products featured in our app and digital campaigns.",
                ),

                ////////// 3
                _smartSellerFeaturesWidget(
                  context: context,
                  icon: Icons.storefront, // Customers visiting shop
                  title: "Extra Footfall",
                  description:
                      "Customers looking for installment plans will visit you directly.",
                ),

                ////////// 4
                _smartSellerFeaturesWidget(
                  context: context,
                  icon: Icons.money_off, // No fees / no investment
                  title: "No Upfront Investment",
                  description:
                      "No fees, no tech hassle — we handle everything!",
                ),

                ////////// 5
                _smartSellerFeaturesWidget(
                  context: context,
                  icon: Icons.qr_code, // Tracking / code system
                  title: "Tracking Code System",
                  description:
                      "Every customer you refer to is tracked via your unique Supplier Code.",
                ),

                SizedBox(height: context.h(10)),

                Text(
                  "How to Start",
                  style: AppTextStyles.h5.bold,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: context.h(10)),

                _buildBenifitsWidget(
                  context: context,
                  description: "Register with us and get your supplier code.",
                ),
                _buildBenifitsWidget(
                  context: context,

                  description: "Display our Small Branded Board at your shop.",
                ),
                _buildBenifitsWidget(
                  context: context,

                  description:
                      "Keep our App QR Code visible for customer scans.",
                ),
                _buildBenifitsWidget(
                  context: context,

                  description:
                      "Briefly guide customers who inquire about installments.",
                ),
                _buildBenifitsWidget(
                  context: context,

                  description:
                      "Notify us with the Supplier Code for each potential order.",
                ),
                SizedBox(height: context.h(20)),
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
                    "Become Partner And Earn More",
                    style: AppTextStyles.h3.bold.white,
                  ),
                  SizedBox(height: 10),
                  Text(
                    textAlign: TextAlign.center,
                    "Join AtomShop today — sell more, earn more, stress less.",
                    style: AppTextStyles.bodyLarge.white,
                  ),
                  SizedBox(height: 20),
                  CustomButton(
                    title: "Become Partner",
                    onPressed: () {
                      AppNavigator.goToSmartSupplierForm();
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

    required String description,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Color(0xFFE9ECEF),
      ),
      padding: EdgeInsets.only(left: 20, right: 40, top: 10, bottom: 10),
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text(description, style: AppTextStyles.bodyMedium)],
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
