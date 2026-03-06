import 'dart:ui';

import 'package:atompro/core/common/images/app_images.dart';
import 'package:atompro/core/common/widgets/app_bar.dart';
import 'package:atompro/core/common/widgets/app_cached_image.dart';
import 'package:atompro/core/common/widgets/custom_button.dart';
import 'package:atompro/core/style/app_text_styles.dart';
import 'package:atompro/core/style/color_palette.dart';
import 'package:atompro/core/style/extensions.dart';
import 'package:atompro/features/drawer/view/drawer.dart';
import 'package:atompro/features/lead_form/lead_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class MakeOfferView extends StatefulWidget {
  const MakeOfferView({super.key});

  @override
  State<MakeOfferView> createState() => _MakeOfferViewState();
}

class _MakeOfferViewState extends State<MakeOfferView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final GlobalKey _leadFormKey = GlobalKey();

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
            SizedBox(height: context.h(20)),

            Text("تنخواہ کا کیا انتظار؟", style: AppTextStyles.h2.purple.bold),
            SizedBox(height: context.h(20)),
            RichText(
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              text: TextSpan(
                style: AppTextStyles.h4,
                children: [
                  TextSpan(
                    text: "ابھی خریداری کریں، ",
                    style: AppTextStyles.h5.bold,
                  ),
                  TextSpan(
                    text: "آسان قسطوں ",
                    style: AppTextStyles.h5.bold.copyWith(
                      color: ColorPalette.accentRed,
                    ),
                  ),
                  TextSpan(text: "میں ادا کریں۔", style: AppTextStyles.h5.bold),
                ],
              ),
            ),
            SizedBox(height: context.h(20)),

            CustomButton(
              title: "Apply Now",
              onPressed: () {
                Scrollable.ensureVisible(
                  _leadFormKey.currentContext!,
                  duration: Duration(seconds: 2),
                  curve: Curves.ease,
                );
              },
              backgroundColor: ColorPalette.accentRed,
              width: 200.w,
            ),
            SizedBox(height: context.h(20)),

            AppCachedImage(imageUrl: AppImages.makeOffer).paddingHorizontal(16),
            SizedBox(height: context.h(30)),
            Text("HOW IT WORKS", style: AppTextStyles.h5.bold),
            SizedBox(height: context.h(30)),
            Column(
              children: [
                _buildStepWidget(
                  context,
                  color: Colors.orange,
                  engTitle: 'Choose any product from the market',
                  urduTitle: 'مارکیٹ سے کوئی بھی پروڈکٹ پسند کریں۔',
                  stepNumber: '1',
                ),

                // The bendy arrow connector
                CustomPaint(
                  size: Size(
                    double.infinity,
                    60.h,
                  ), // 60.h gives it that nice vertical gap
                  painter: LoopingArrowPainter(color: ColorPalette.accentRed),
                ),

                _buildStepWidget(
                  context,
                  color: Colors.red,
                  engTitle: 'Place your order through our custom order form',
                  urduTitle: 'ہمارے کسٹم آرڈر فارم سے آرڈر کریں۔',
                  stepNumber: '2',
                ),

                CustomPaint(
                  size: Size(double.infinity, 60.h),
                  painter: LoopingArrowPainter(
                    color: ColorPalette.accentPurple,
                    isClockwise: false,
                  ),
                ),

                _buildStepWidget(
                  context,
                  color: Colors.deepPurple,
                  engTitle:
                      'Get your product at home and pay in easy installments',
                  urduTitle:
                      'گھر بیٹھے اپنی چیزیں حاصل کریں اور آسان قسطوں میں ادائیگی کریں۔',
                  stepNumber: '3',
                ),
              ],
            ),
            SizedBox(height: context.h(30)),

            LeadForm(key: _leadFormKey),
            SizedBox(height: context.h(20)),

            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: ColorPalette.secondary,
              ),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
              child: Column(
                children: [
                  Text(
                    "Plan Your Installments With Our Smart Calculator",
                    textAlign: TextAlign.center,
                    style: AppTextStyles.h5.bold.white,
                  ),
                  SizedBox(height: context.h(15)),
                  CustomButton(
                    textColor: Colors.black,
                    title: "Calculate Installments",
                    onPressed: () {},
                    backgroundColor: Colors.white,
                    width: 200.w,
                  ),
                ],
              ),
            ).paddingHorizontal(16),
            SizedBox(height: context.h(50)),
          ],
        ),
      ),
    );
  }

  Widget _buildStepWidget(
    BuildContext context, {
    required Color color,
    required String engTitle,
    required String urduTitle,
    required String stepNumber,
  }) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 15.h),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Container(
        // Margin creates the "Frame" effect
        margin: EdgeInsets.only(left: 10.w, right: 10.w, top: 1.h),
        padding: EdgeInsets.symmetric(vertical: 30.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(3.r),
          // Mature Shadow: Low opacity, high blur, subtle offset
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Step Label
            CircleAvatar(
              radius: context.r(20),
              backgroundColor: color,
              child: Text(
                stepNumber,
                style: AppTextStyles.h4.white,
                textAlign: .center,
              ),
            ),
            SizedBox(height: 18.h),

            // English Title
            Text(
              engTitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.bold,
            ),

            SizedBox(height: 10.h),

            // Urdu Title
            Text(
              urduTitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.bold,
            ),
          ],
        ),
      ),
    ).paddingHorizontal(16);
  }
}

class LoopingArrowPainter extends CustomPainter {
  final Color color;
  final bool isClockwise;

  LoopingArrowPainter({required this.color, this.isClockwise = true});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth =
          2.5 // Slightly thicker for better visibility
      ..strokeCap = StrokeCap.round;

    final path = Path();

    if (isClockwise) {
      path.moveTo(size.width * 0.75, 0);
      path.cubicTo(
        size.width * 1.1,
        size.height * 0.2, // Control Point 1
        size.width * 0.2,
        size.height * 0.8, // Control Point 2
        size.width * 0.45,
        size.height, // End Point
      );
    } else {
      path.moveTo(size.width * 0.25, 0);
      path.cubicTo(
        -size.width * 0.1,
        size.height * 0.2,
        size.width * 0.8,
        size.height * 0.8,
        size.width * 0.55,
        size.height,
      );
    }

    // --- Draw Dotted Line ---
    const double dashWidth = 5;
    const double dashSpace = 5;
    double distance = 0;
    for (PathMetric metric in path.computeMetrics()) {
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }

    // --- Draw Perfect Arrow Head ---
    final lastMetric = path.computeMetrics().last;
    final tangent = lastMetric.getTangentForOffset(lastMetric.length);

    if (tangent != null) {
      final Offset pos = tangent.position;

      final arrowPath = Path();
      const double arrowSize = 8.0; // Adjust size here

      // Create a sharp triangle pointing "forward" based on the angle
      arrowPath.moveTo(pos.dx, pos.dy);
      arrowPath.lineTo(
        pos.dx -
            arrowSize * (1.2 * (tangent.vector.dx) + 0.6 * (tangent.vector.dy)),
        pos.dy -
            arrowSize * (1.2 * (tangent.vector.dy) - 0.6 * (tangent.vector.dx)),
      );
      arrowPath.moveTo(pos.dx, pos.dy);
      arrowPath.lineTo(
        pos.dx -
            arrowSize * (1.2 * (tangent.vector.dx) - 0.6 * (tangent.vector.dy)),
        pos.dy -
            arrowSize * (1.2 * (tangent.vector.dy) + 0.6 * (tangent.vector.dx)),
      );

      // Using stroke for a modern "open" arrowhead (like in your screenshot)
      canvas.drawPath(arrowPath, paint..style = PaintingStyle.stroke);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
