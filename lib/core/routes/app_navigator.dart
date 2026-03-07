import 'package:atompro/core/routes/app_route_constants.dart';
import 'package:flutter/material.dart';

class AppNavigator {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // ========= Core Utilities =========
  static Future<void> pushTo(String routeName) async {
    navigatorKey.currentState?.pushNamed(routeName);
  }

  static Future<void> getBack() async {
    navigatorKey.currentState?.pop();
  }

  static Future<void> pushReplacementTo(String routeName) async {
    navigatorKey.currentState?.pushReplacementNamed(routeName);
  }

  static Future<void> clearStackAndPush(String routeName) async {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
    );
  }

  static void goToEditProfile({bool isCompletionFlow = false}) => pushNamed(
    AppRoutes.editProfile,
    arguments: {'isCompletionFlow': isCompletionFlow},
  );

  // Add this method to AppNavigator
  static Future<T?> pushNamed<T>(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushNamed<T>(
      routeName,
      arguments: arguments,
    );
  }
  // Add this method to AppNavigator

  // ========= Semantic Aliases (Optional, Recommended for main routes) =========
  static void goToHome() => pushReplacementTo(AppRoutes.homePage);
  static void goToCustomOrder() => pushTo(AppRoutes.customOrder);
  static void goToAuthPage() => pushTo(AppRoutes.authpage);
  static void goToMakeOfferView() => pushTo(AppRoutes.makeoffer);
  static void goToWhyAtomshop() => pushTo(AppRoutes.whyatomshop);
  static void goToSmartSellerHome() => pushTo(AppRoutes.smartsellerhome);
  static void goToSmartSellerForm() => pushTo(AppRoutes.smartsellerform);
  static void goToSmartSupplierForm() => pushTo(AppRoutes.smartsupllierform);
  static void goToSmartSupplierHome() => pushTo(AppRoutes.smartsupllierhome);
  static void goToProfilePage() => pushTo(AppRoutes.profile);
  static void goToAboutUs() => pushTo(AppRoutes.aboutUs);
  static void goToPrivacyPolicy() => pushTo(AppRoutes.privacyPolicy);
  static void goToTermsAndConditions() => pushTo(AppRoutes.termsAndConditions);
  static void gotTermsOfUse() => pushTo(AppRoutes.termsOfUse);
  static void goToReturnRefundPolicy() => pushTo(AppRoutes.returnRefundPolicy);
  static void goToMyOrders() => pushTo(AppRoutes.myOrders);
  static void goToNotifications() => pushTo(AppRoutes.notifications);
}
