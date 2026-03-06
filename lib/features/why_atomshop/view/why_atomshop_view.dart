import 'package:atompro/core/common/images/app_images.dart';
import 'package:atompro/core/common/widgets/app_bar.dart';
import 'package:atompro/core/common/widgets/custom_button.dart';
import 'package:atompro/core/routes/app_navigator.dart';
import 'package:atompro/core/style/app_text_styles.dart';
import 'package:atompro/core/style/color_palette.dart';
import 'package:atompro/core/style/extensions.dart';

import 'package:atompro/features/drawer/view/drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class WhyAtomshopView extends StatelessWidget {
  WhyAtomshopView({super.key});
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: buildAppBar(context, () {
        _scaffoldKey.currentState?.openDrawer();
      }),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: context.h(400), // Height of the whole hero section
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [
                    Color(0xFFEEE2F8),
                    Color(0xFFFDF5F3),
                    Color(0xFFE4EDFC),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
              child: Stack(
                alignment:
                    Alignment.bottomCenter, // Aligns everything to the bottom
                children: [
                  Positioned(
                    top: 20.h, // Controls the distance from the very top
                    left: 20.w,
                    right: 20.w,
                    child: Column(
                      children: [
                        SizedBox(height: 30),
                        Text(
                          "Why Wait for Pay-Day",
                          style: AppTextStyles.h3.bold.copyWith(
                            color: ColorPalette.accentPurple,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20),

                        Text(
                          "Shop Now Pay in Steps",
                          style: AppTextStyles.h2.bold,
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 10),

                        CustomButton(
                          title: "Order Now",
                          onPressed: () {
                            AppNavigator.goToCustomOrder();
                          },
                          width: 150.w,
                        ).alignTopLeft,
                      ],
                    ),
                  ),
                  // 1. The Waves (The Foundation)
                  _buildPremiumHeader(context),

                  // 2. The Image (Placed exactly on the waves)
                  Positioned(
                    // 'bottom' value should be slightly higher than the wave peak
                    // to make it look like it's resting on top.
                    bottom: 25.h,
                    child: Image.network(
                      AppImages.whyAtomshopHeader,
                      height: 180.h,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: context.h(20)),
            Text(
              "How it Works",
              style: AppTextStyles.h4.bold,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.h(10)),

            Text(
              "Shopping on installments is simple — here’s how you get started:",
              style: AppTextStyles.bodyLarge.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ).paddingHorizontal(16),
            SizedBox(height: 20.h),

            _buildDownloadCard(
              context,
              "Choose Any Product Online or from any physical store",
              "Choose any product of any brand you want, fill form and we will make it available for you on installments.",
              Icons.shopping_cart_outlined,
            ),
            _buildDownloadCard(
              context,
              "Choose Installment Plan & Checkout",
              "At checkout, Make Your Installment Plan Using Our Installment Calculator.",
              Icons.account_balance_wallet_outlined,
            ),
            SizedBox(height: 40.h),
            // Steps go here...
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
  ) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 15.h),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. The Rotated Blue Background
          Transform.rotate(
            angle: 0.09, // Approximately -4 degrees for that stylish peek
            child: Container(
              width: double.infinity,
              height: 200
                  .h, // Slightly shorter than the white card to keep it subtle
              decoration: BoxDecoration(
                color: const Color(0xFF004296), // Your deep brand blue
                borderRadius: BorderRadius.circular(24.r),
              ),
            ),
          ),

          // 2. The Main White Card (Kept perfectly straight)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon with the light blue blob
                _buildIconHeader(icon),

                SizedBox(height: 5.h),

                Text(
                  title,
                  style: AppTextStyles.h6.bold.copyWith(
                    color: ColorPalette.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),

                SizedBox(height: 12.h),

                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconHeader(IconData icon) {
    return SizedBox(
      height: 80.r,
      width: 80.r,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The soft blue "blob" offset behind the icon
          Positioned(
            left: 10,
            top: 0,
            child: Container(
              height: 35.r,
              width: 35.r,
              decoration: BoxDecoration(
                color: const Color(0xFFE4EDFC), // Your light blue accent
                shape: BoxShape.circle,
              ),
            ),
          ),
          Icon(icon, size: 30.r, color: const Color(0xFF004296)),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader(BuildContext context) {
    return Stack(
      children: [
        // --- THE TRIPLE WAVE LAYERS ---
        // Layer 1: Farthest back (Taller & Lightest)
        ClipPath(
          clipper: TopWaveClipper(),
          child: Container(
            height: 100.h,
            width: double.infinity,
            color: Color(0xFF0072C8),
          ),
        ),
        // Layer 2: Middle (Depth)
        ClipPath(
          clipper: TopWaveClipper(),
          child: Container(
            height: 80.h,
            width: double.infinity,
            color: Color(0xFF241D53),
          ),
        ),
        // Layer 3: Main Front Container
        ClipPath(
          clipper: TopWaveClipper(),
          child: Container(
            height: 60.h,
            width: double.infinity,
            decoration: BoxDecoration(color: Color(0xFF004296)),
          ),
        ),

        // --- THE CONTENT OVERLAY ---
      ],
    );
  }
}

class TopWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 40.h);

    var firstControlPoint = Offset(size.width * 0.75, 0);
    var firstEndPoint = Offset(size.width * 0.5, 30.h);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    var secondControlPoint = Offset(size.width * 0.25, 60.h);
    var secondEndPoint = Offset(0, 20.h);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
