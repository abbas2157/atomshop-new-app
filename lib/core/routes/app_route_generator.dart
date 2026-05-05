import 'package:atompro/core/routes/app_route_constants.dart';
import 'package:atompro/features/customer/about_us/view/about_us_view.dart';
import 'package:atompro/features/customer/auth/view/change_password.dart';
import 'package:atompro/features/customer/auth/view/login_signup_view.dart';
import 'package:atompro/features/customer/auth/view/otp_verify_view.dart';
import 'package:atompro/features/customer/custom_order/view/custom_order_view.dart';
import 'package:atompro/features/customer/custom_order/view/my_orders.dart';
import 'package:atompro/features/customer/home/view/bottom_nav_bar/bottom_nav_bar.dart';
import 'package:atompro/features/customer/home/view/home_page.dart';
import 'package:atompro/features/customer/make_offer/view/make_offer_view.dart';
import 'package:atompro/features/customer/notifications/notifications_view.dart';
import 'package:atompro/features/customer/privacy_policy/view/privacy_policy_view.dart';
import 'package:atompro/features/customer/profile/view/edit_profile.dart';
import 'package:atompro/features/customer/profile/view/profile_view.dart';
import 'package:atompro/features/customer/return_refund_policy/return_refund_policy.dart';
import 'package:atompro/features/customer/smart_seller/view/smart_seller_form.dart';
import 'package:atompro/features/customer/smart_seller/view/smart_seller_home.dart';
import 'package:atompro/features/customer/smart_supplier/view/smart_supllier_form.dart';
import 'package:atompro/features/customer/smart_supplier/view/smart_supplier_home.dart';
import 'package:atompro/features/customer/terms_and_conditions/terms_and_conditions.dart';
import 'package:atompro/features/customer/terms_of_use/terms_of_use.dart';
import 'package:atompro/features/customer/why_atomshop/view/why_atomshop_view.dart';



import 'package:flutter/material.dart';

class AppRouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.profile:
        return MaterialPageRoute(builder: (_) => ProfilePage());
      case AppRoutes.privacyPolicy:
        return MaterialPageRoute(builder: (_) => PrivacyPolicyPage());
      case AppRoutes.termsAndConditions:
        return MaterialPageRoute(builder: (_) => TermsAndConditionsPage());
      case AppRoutes.notifications:
        return MaterialPageRoute(builder: (_) => NotificationsScreen());
      case AppRoutes.changePassword:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ChangePasswordScreen(userUuid: args?['uuid'] ?? ''),
        );
      case AppRoutes.termsOfUse:
        return MaterialPageRoute(builder: (_) => TermsOfUse());
      case AppRoutes.returnRefundPolicy:
        return MaterialPageRoute(builder: (_) => ReturnRefundPolicy());
      case AppRoutes.aboutUs:
        return MaterialPageRoute(builder: (_) => AboutUs());
      case AppRoutes.myOrders:
        return MaterialPageRoute(builder: (_) => MyOrdersPage());
      case AppRoutes.homePage:
        return MaterialPageRoute(builder: (_) => HomePage());
      case AppRoutes.bottomnavbar:
        return MaterialPageRoute(builder: (_) => BottomBarPage());
      case AppRoutes.customOrder:
        return MaterialPageRoute(builder: (_) => CustomOrderView());
      case AppRoutes.makeoffer:
        return MaterialPageRoute(builder: (_) => MakeOfferView());
      case AppRoutes.authpage:
        return MaterialPageRoute(builder: (_) => ModernAuthScreen());
      case AppRoutes.whyatomshop:
        return MaterialPageRoute(builder: (_) => WhyAtomshopView());
      // smart seller
      case AppRoutes.smartsellerhome:
        return MaterialPageRoute(builder: (_) => SmartSellerHome());
      case AppRoutes.smartsellerform:
        return MaterialPageRoute(builder: (_) => SmartSellerForm());
      // smart supplier
      case AppRoutes.smartsupllierhome:
        return MaterialPageRoute(builder: (_) => SmartSupplierHome());
      case AppRoutes.smartsupllierform:
        return MaterialPageRoute(builder: (_) => SupplierForm());
      case AppRoutes.verifyOTP:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) =>
              OTPVerifyScreen(email: args['email'], userId: args['user_id']),
        );

      // ── Edit / Complete Profile ────────────────────────────────────────────
      case AppRoutes.editProfile:
        final args = settings.arguments as Map<String, dynamic>?;
        final isCompletionFlow = args?['isCompletionFlow'] as bool? ?? false;
        return MaterialPageRoute(
          builder: (_) => EditProfilePage(isCompletionFlow: isCompletionFlow),
        );
     

      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text("Page not found"))),
        );
    }
  }
}
