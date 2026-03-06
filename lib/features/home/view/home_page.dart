import 'package:atompro/core/common/images/app_images.dart';
import 'package:atompro/core/common/utils/utils.dart';
import 'package:atompro/core/common/widgets/app_bar.dart';
import 'package:atompro/core/common/widgets/app_cached_image.dart';
import 'package:atompro/core/routes/app_navigator.dart';
import 'package:atompro/core/style/app_text_styles.dart';
import 'package:atompro/core/style/color_palette.dart';
import 'package:atompro/core/style/extensions.dart';
import 'package:atompro/features/drawer/view/drawer.dart';
import 'package:atompro/features/home/model/category_model.dart';
import 'package:atompro/features/home/utils/home_utils.dart';
import 'package:atompro/features/home/widgets/faq_widget.dart';
import 'package:atompro/features/lead_form/lead_form.dart';
import 'package:flutter/material.dart';
import 'package:atompro/core/common/widgets/custom_button.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey _leadFormKey = GlobalKey();

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
            SizedBox(height: context.h(25)),

            buildTopHeadingAndButton(context).paddingHorizontal(16),

            SizedBox(height: context.h(20)),

            _mainImageOne().paddingLarge.alignTopRight,

            _mainImageTwo(context),
            SizedBox(height: context.h(20)),

            ///////// modern installment section
            buildModernInstallmentsSection(context).paddingHorizontal(16),

            SizedBox(height: context.h(50)),
            // steps section
            _buildHowItWorksSection(context).paddingHorizontal(16),
            SizedBox(height: context.h(30)),

            // ready to make order section
            Text("Ready to make order?", style: AppTextStyles.bodyLarge),
            SizedBox(height: context.h(10)),
            CustomButton(
              title: "Order Now",
              onPressed: () {
                AppNavigator.goToCustomOrder();
              },
            ).paddingHorizontal(16),
            SizedBox(height: context.h(40)),
            LeadForm(key: _leadFormKey),
            SizedBox(height: context.h(40)),

            // calculate installments section
            Text("Calculate Installments?", style: AppTextStyles.bodyLarge),
            SizedBox(height: context.h(10)),
            CustomButton(
              title: "Go to Calculator",
              onPressed: () {
                AppNavigator.goToCustomOrder();
              },
            ).paddingHorizontal(16),
            SizedBox(height: context.h(40)),
            Column(
              children: [
                Text("Buy Anything On Installments", style: AppTextStyles.h3),
                SizedBox(height: context.h(10)),

                Container(
                  padding: EdgeInsets.all(16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Color(0xFFE4E8F3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ColorPalette.border, width: 1),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Can't Find Right Category For Your Product ?",
                        style: AppTextStyles.bodyLarge,
                      ),
                      SizedBox(height: context.h(10)),

                      CustomButton(
                        title: "Make Custom Order",
                        onPressed: () {
                          AppNavigator.goToCustomOrder();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ).paddingHorizontal(16),
            SizedBox(height: context.h(10)),
            _buildCategorySection().paddingHorizontal(16), // Padding stays here
            SizedBox(height: context.h(30)),
            Text("Why Choose ATOMSHOP", style: AppTextStyles.h3),
            SizedBox(height: context.h(20)),

            Column(
              children: [
                whyAtomShop(
                  context: context,
                  icon: Icons.category_outlined,
                  title: "All Categories Covered",
                  description:
                      "From electronics and appliances to furniture and lifestyle products we support every category.",
                ),
                SizedBox(height: context.h(20)),

                whyAtomShop(
                  context: context,
                  icon: Icons.flash_on,
                  title: "Instant Installments",
                  description:
                      "Get approved instantly and start shoppingno credit card required.",
                ),
                SizedBox(height: context.h(20)),

                whyAtomShop(
                  context: context,
                  icon: Icons.security_rounded,
                  title: "Transparent Payments",
                  description:
                      "No hidden fees. No surprises. Just clear, predictable monthly plans",
                ),
              ],
            ).paddingHorizontal(30),
            SizedBox(height: context.h(10)),

            _buildSmartSellerSection(context),

            SizedBox(height: context.h(30)),
            Text(
              "Frequently Asked\nQuestions",
              textAlign: TextAlign.left,
              style: AppTextStyles.h5,
            ).alignTopLeft.paddingLeft(16),
            SizedBox(height: context.h(5)),
            Text(
              "Here are answers to the most common questions about our process, payments, and custom order service",
              style: AppTextStyles.bodyMedium,
            ).alignTopLeft.paddingLeft(16),
            SizedBox(height: context.h(10)),

            CustomFAQWidget(faqs: myFaqs).paddingHorizontal(10),

            SizedBox(height: context.h(50)),
          ],
        ),
      ),
    );
  }

  Container _mainImageTwo(BuildContext context) {
    return Container(
      color: Colors.transparent,
      height: context.h(300), // Ensure enough height for the overlap effect
      width: double.infinity,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // 1. BACKGROUND IMAGE (Full Width, anchored to bottom)
          Positioned(
            bottom: context.h(
              20,
            ), // Negative to pull it down and create overlap
            left: 0,
            right: 0,
            child: Image.asset(
              AppImages.herobg,
              width: double.infinity,
              fit: BoxFit.fitWidth, // Ensures it stretches across the screen
            ),
          ),

          // 2. FOREGROUND CONTENT (The Builder Stack)
          Positioned(
            left: context.w(40),
            child: Builder(
              builder: (context) {
                final double screenWidth = MediaQuery.sizeOf(context).width;

                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    // TOP IMAGE (hero2)
                    SizedBox(
                      width: screenWidth * 0.7,
                      child: AppCachedImage(
                        imageUrl:
                            "https://atomshop.pk/public/web/img/hero-1.png",
                      ),
                    ),

                    // TEXT CONTAINER (Bottom Center)
                    Positioned(
                      bottom: 0,
                      child: Container(
                        width: screenWidth * 0.75,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F9F9),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade400,
                              blurRadius: 4,
                              spreadRadius: 1,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(8.w),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: AppTextStyles.bodyMedium,
                            children: [
                              TextSpan(
                                text: "آسان اقساط ",
                                style: AppTextStyles.bodyBold.copyWith(
                                  color: Colors.red,
                                ),
                              ),
                              TextSpan(
                                text: "پر کچھ بھی حاصل کریں ",
                                style: AppTextStyles.bodyBold.copyWith(
                                  color: Colors.black,
                                ),
                              ),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Icon(
                                  Icons.check_circle_outline,
                                  size: 15,
                                  color: ColorPalette.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  SizedBox _mainImageOne() {
    return SizedBox(
      child: Builder(
        builder: (context) {
          final double screenWidth = MediaQuery.sizeOf(context).width;

          return Stack(
            clipBehavior:
                Clip.none, // Allows the container to "pop" out if needed
            alignment: Alignment.topCenter,
            children: [
              // 1. Image: 55% of screen width
              SizedBox(
                width: screenWidth * 0.7,
                child: AppCachedImage(
                  imageUrl: "https://atomshop.pk/public/web/img/hero-2.png",
                  fit: BoxFit.contain,
                ),
              ),

              // 2. Text Container: Bottom Center, 60% of screen width
              Positioned(
                bottom: 0, // Pins it to the bottom of the stack
                child: Container(
                  width: screenWidth * 0.75,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade400,
                        blurRadius: 4,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(8.w),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
                      children: [
                        TextSpan(
                          text: "سب کچھ ایک ہی ",
                          style: AppTextStyles.bodyBold,
                        ),
                        TextSpan(
                          text: "پلیٹ فارم ",
                          style: AppTextStyles.bodyBold.copyWith(
                            color: ColorPalette.primary,
                          ),
                        ),
                        TextSpan(text: "پر ", style: AppTextStyles.bodyBold),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4.0),
                            child: Icon(
                              Icons.check_circle_outline,
                              size: 15,
                              color: ColorPalette.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Container _buildSmartSellerSection(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Color(0xFFF9F9F9),
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          SizedBox(height: context.h(30)),
          Text(
            "Partner With Us And Grow Your Business",
            textAlign: .center,
            style: AppTextStyles.h3.bold,
          ),
          SizedBox(height: context.h(30)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ColorPalette.secondary,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade400,
                  blurRadius: 4,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Smart Seller", style: AppTextStyles.h4.white),
                SizedBox(height: context.h(5)),

                Text(
                  "Become a Smart Seller with AtomShop and grow your business with confidence. We provide the platform, tools, and hands on support you need to succeed.",
                  style: AppTextStyles.bodyLarge.white,
                ),
                SizedBox(height: context.h(15)),

                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 5),
                    Text(
                      "Live Sales & Revenue Tracking",
                      style: AppTextStyles.bodyLarge.white,
                    ),
                  ],
                ),
                SizedBox(height: context.h(2)),

                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 5),
                    Text(
                      "Installment Payment Tracker",
                      style: AppTextStyles.bodyLarge.white,
                    ),
                  ],
                ),
                SizedBox(height: context.h(2)),

                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 5),
                    Text(
                      "Order & Customer Management",
                      style: AppTextStyles.bodyLarge.white,
                    ),
                  ],
                ),
                SizedBox(height: 30),
                CustomButton(
                  textColor: ColorPalette.secondary,
                  title: "Register Now",
                  onPressed: () {
                    AppNavigator.goToSmartSellerHome();
                  },
                  backgroundColor: Colors.white,
                  width: context.w(180),
                ),
              ],
            ),
          ),
          SizedBox(height: context.h(10)),

          // smart supplier
          _buildSmartSupplierSection(context),
        ],
      ),
    );
  }

  Container _buildSmartSupplierSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade400,
            blurRadius: 4,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Smart Supplier", style: AppTextStyles.h4),
          SizedBox(height: context.h(5)),

          Text(
            "At AtomShop.pk, we believe every shopkeeper deserves a chance to grow without the cost and complexity of building their own e commerce system.",
          ),
          SizedBox(height: context.h(15)),

          Row(
            children: [
              Icon(Icons.check_circle, color: ColorPalette.secondary),
              SizedBox(width: 5),
              Text("Instant Cash Sales", style: AppTextStyles.bodyLarge),
            ],
          ),
          SizedBox(height: context.h(2)),

          Row(
            children: [
              Icon(Icons.check_circle, color: ColorPalette.secondary),
              SizedBox(width: 5),
              Text("Free Marketing", style: AppTextStyles.bodyLarge),
            ],
          ),
          SizedBox(height: context.h(2)),

          Row(
            children: [
              Icon(Icons.check_circle, color: ColorPalette.secondary),
              SizedBox(width: 5),
              Text("No Upfront Investment", style: AppTextStyles.bodyLarge),
            ],
          ),
          SizedBox(height: 30),
          CustomButton(
            title: "Register Now",
            onPressed: () {
              AppNavigator.goToSmartSupplierHome();
            },
            width: context.w(180),
          ),
        ],
      ),
    );
  }

  LayoutBuilder _buildCategorySection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 1. Calculate width based on the actual parent width
        // [Parent Max Width] - [Spacing between items (12)]
        // We don't subtract 32 here because the padding is usually on the parent
        final double itemWidth = (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12, // Horizontal space
          runSpacing: 16, // Vertical space
          children: categories.map((category) {
            return Container(
              width: itemWidth,
              height: 160, // Reduced height for better UX (less scrolling)
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade400,
                    blurRadius: 4,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 12),
                      // Image
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Image.asset(
                            category.imageUrl,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Name
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4.0,
                          vertical: 8.0,
                        ),
                        child: Text(
                          category.name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize:
                                13, // Slightly smaller to prevent overflow
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Column _buildHowItWorksSection(BuildContext context) {
    return Column(
      children: [
        Text("How It Works", style: AppTextStyles.h3),
        SizedBox(height: context.h(15)),

        Text(
          "Experience a simple, fast, and transparent process to get anything you need on easy monthly installments with these simple steps.",
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: ColorPalette.textPrimary,
          ),
        ),
        SizedBox(height: context.h(20)),

        _buildStepWidget(
          context,
          color: ColorPalette.primary,
          engTitle: "Choose any product from the market",
          urduTitle: "مارکیٹ سے کوئی بھی چیز پسند کریں",
          stepNumber: "1",
        ),
        SizedBox(height: context.h(15)),

        _buildStepWidget(
          context,
          color: ColorPalette.error,
          engTitle: "Place your order through our custom order form",
          urduTitle: "ہمارے کسٹم آرڈر فارم کے ذریعے آرڈر کریں",
          stepNumber: "2",
        ),
        SizedBox(height: context.h(15)),

        _buildStepWidget(
          context,
          color: Color(0xFF62449A),
          engTitle: "Get your product at home and pay in easy installments",
          urduTitle: "گھر بیٹھے اپنی چیز حاصل کریں، آسان قسطوں کی ادائیگی پر",
          stepNumber: "3",
        ),
      ],
    );
  }

  Column buildModernInstallmentsSection(BuildContext context) {
    return Column(
      children: [
        Text(
          "Modern Installment Shopping, Simplified.",
          style: AppTextStyles.h3,
        ),
        SizedBox(height: context.h(15)),

        Text(
          "We are a modern installment shopping platform designed to remove financial barriers for everyday buyers. Our goal is simple: make essential and aspirational purchases accessible to everyone, without the stress of full upfront payments.",
          style: AppTextStyles.bodyMedium.copyWith(
            color: ColorPalette.textPrimary,
          ),
        ),
        SizedBox(height: context.h(20)),

        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade400,
                blurRadius: 4,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.all(8.w),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 15,
                color: ColorPalette.success,
              ),
              SizedBox(width: context.w(8)),
              Text(
                "Instant Approval, Zero Waiting",
                style: AppTextStyles.bodyBold,
              ),
            ],
          ),
        ),
        SizedBox(height: context.h(10)),

        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade400,
                blurRadius: 4,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.all(8.w),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 15,
                color: ColorPalette.success,
              ),
              SizedBox(width: context.w(8)),
              Text("Budget-Friendly Options", style: AppTextStyles.bodyBold),
            ],
          ),
        ),
        SizedBox(height: context.h(10)),

        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade400,
                blurRadius: 4,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.all(8.w),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 15,
                color: ColorPalette.success,
              ),
              SizedBox(width: context.w(8)),
              Text("No Credit Card Required", style: AppTextStyles.bodyBold),
            ],
          ),
        ),
        SizedBox(height: context.h(20)),

        AppCachedImage(
          imageUrl: "https://atomshop.pk/public/web/img/section-2.png",
        ),
      ],
    );
  }

  Column buildTopHeadingAndButton(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        SizedBox(
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: CircleAvatar(
                    radius: context.r(30),
                    backgroundColor: ColorPalette.primary,
                  ),
                ),
              ),
              Text(
                "Why Wait For Pay Day\nShop Now, Pay Later",
                style: AppTextStyles.h3,
              ),
            ],
          ),
        ),
        SizedBox(height: context.h(15)),

        Text(
          "Shop thousands of items today and split the cost into easy, manageable monthly payments.",
          style: AppTextStyles.bodyMedium.copyWith(
            color: ColorPalette.textPrimary,
          ),
        ),
        SizedBox(height: context.h(10)),

        CustomButton(
          title: "Get Quote Now",
          onPressed: () {
            Scrollable.ensureVisible(
              _leadFormKey.currentContext!,
              duration: Duration(seconds: 2),
              curve: Curves.ease,
            );
          },
          width: context.w(200),
        ),
      ],
    );
  }

  Container whyAtomShop({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      height: 200,
      width: double.infinity,
      padding: EdgeInsets.only(left: 15),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: ColorPalette.secondary, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: .start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: ColorPalette.secondary, size: 50),
          SizedBox(height: context.h(5)),
          Text(title, style: AppTextStyles.h5),
          SizedBox(height: context.h(5)),

          Text(description, style: AppTextStyles.bodyLarge),
        ],
      ),
    );
  }

  Container _buildStepWidget(
    BuildContext context, {
    required Color color,
    required String engTitle,
    required String urduTitle,
    required String stepNumber,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: color, width: 4.w),
          right: BorderSide(color: color, width: 4.w),
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: context.h(10)),
          CircleAvatar(
            radius: context.r(20),
            backgroundColor: color,
            child: Text(
              stepNumber,
              style: AppTextStyles.h4.white,
              textAlign: .center,
            ),
          ),
          SizedBox(height: context.h(10)),

          Text(engTitle, style: AppTextStyles.h6, textAlign: .center),
          SizedBox(height: context.h(10)),

          Text(urduTitle, style: AppTextStyles.h6, textAlign: .center),
        ],
      ),
    );
  }
}
