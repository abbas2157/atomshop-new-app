import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/atom_auth.dart';
import '../data/atom_models.dart';
import '../data/atom_order.dart';
import '../data/atom_product_detail.dart';
import '../screens/account/atom_custom_orders_screen.dart';
import '../screens/account/atom_notifications_screen.dart';
import '../screens/account/atom_order_detail_screen.dart';
import '../screens/account/atom_orders_screen.dart';
import '../screens/account/atom_overview_screen.dart';
import '../screens/account/atom_password_screen.dart';
import '../screens/account/atom_profile_screen.dart';
import '../screens/auth/atom_code_screen.dart';
import '../screens/auth/atom_forgot_screen.dart';
import '../screens/auth/atom_location_screen.dart';
import '../screens/auth/atom_register_screen.dart';
import '../screens/auth/atom_reset_screen.dart';
import '../screens/auth/atom_sign_in_screen.dart';
import '../screens/auth/atom_welcome_screen.dart';
import '../screens/custom/atom_custom_order_screen.dart';
import '../screens/custom/atom_make_offer_screen.dart';
import '../screens/info/atom_about_screen.dart';
import '../screens/info/atom_apps_screen.dart';
import '../screens/info/atom_contact_screen.dart';
import '../screens/info/atom_faqs_screen.dart';
import '../screens/info/atom_legal_screen.dart';
import '../screens/info/atom_why_screen.dart';
import '../screens/installments/atom_payments_screen.dart';
import '../screens/installments/atom_receipt_screen.dart';
import '../screens/order/atom_order_placed_screen.dart';
import '../screens/order/atom_order_screen.dart';
import '../screens/placeholder/atom_placeholder_screen.dart';
import '../screens/product/atom_product_screen.dart';
import '../screens/shop/atom_product_list_screen.dart';
import '../screens/shop/atom_search_screen.dart';
import 'atom_shell.dart';

/// Every way of moving between screens, in one place.
///
/// Lists (a category, a brand) open inside the current tab, so the bottom
/// bar stays. Everything else opens full screen on the root navigator, as
/// in the design (no bottom bar on those screens).
abstract final class AtomNav {
  // ── Shop ────────────────────────────────────────────────────────────────

  static Future<void> category(BuildContext context, CatalogueItem item) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => AtomProductListScreen.category(item)));

  static Future<void> brand(BuildContext context, CatalogueItem item) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => AtomProductListScreen.brand(item)));

  static Future<void> product(BuildContext context, int id) => _push(context, AtomProductScreen(productId: id));

  static Future<void> search(BuildContext context, {String query = ''}) => _push(context, AtomSearchScreen(initialQuery: query));

  static Future<void> order(BuildContext context, ProductOrderChoice choice) => _push(context, AtomOrderScreen(choice: choice));

  /// Replaces the order form, so back never returns to a sent form.
  static Future<void> orderPlaced(BuildContext context, OrderReceipt receipt) =>
      Navigator.of(context, rootNavigator: true).pushReplacement(MaterialPageRoute(builder: (_) => AtomOrderPlacedScreen(receipt: receipt)));

  static Future<void> customOrder(BuildContext context) => _push(context, const AtomCustomOrderScreen());

  static Future<void> makeOffer(BuildContext context) => _push(context, const AtomMakeOfferScreen());

  // ── Sign in and sign up ─────────────────────────────────────────────────
  //
  // Auth screens are named routes under [authPrefix]. When a flow ends
  // (signed in), [finishAuth] closes all of them, so the customer lands back
  // where they started (an order form, the account tab…).

  static const authPrefix = '/auth';

  static Future<void> _auth(BuildContext context, String name, Widget page, {bool replace = false}) {
    final route = MaterialPageRoute<void>(settings: RouteSettings(name: '$authPrefix/$name'), builder: (_) => page);
    final nav = Navigator.of(context, rootNavigator: true);
    return replace ? nav.pushReplacement(route) : nav.push(route);
  }

  static Future<void> welcome(BuildContext context) => _auth(context, 'welcome', const AtomWelcomeScreen());

  static Future<void> signIn(BuildContext context, {bool replace = false}) => _auth(context, 'sign-in', const AtomSignInScreen(), replace: replace);

  static Future<void> register(BuildContext context, {bool replace = false}) => _auth(context, 'register', const AtomRegisterScreen(), replace: replace);

  static Future<void> code(BuildContext context, CodeSent code, CodePurpose purpose, {String login = ''}) =>
      _auth(context, 'code', AtomCodeScreen(code: code, purpose: purpose, login: login));

  static Future<void> forgotPassword(BuildContext context, {String login = ''}) => _auth(context, 'forgot', AtomForgotScreen(login: login));

  static Future<void> resetPassword(BuildContext context, CodeSent code) => _auth(context, 'reset', AtomResetScreen(code: code));

  /// Step 3 of sign-up (inside the auth flow), or the account's "City and area".
  static Future<void> location(BuildContext context, {bool signUpStep = false}) => signUpStep
      ? _auth(context, 'location', const AtomLocationScreen(signUpStep: true), replace: true)
      : _push(context, const AtomLocationScreen());

  /// Closes every auth screen after signing in or up.
  static void finishAuth(BuildContext context) {
    Navigator.of(context, rootNavigator: true).popUntil((route) => !(route.settings.name ?? '').startsWith(authPrefix));
  }

  // ── Account ─────────────────────────────────────────────────────────────

  static Future<void> overview(BuildContext context) => _push(context, const AtomOverviewScreen());

  static Future<void> orders(BuildContext context) => _push(context, const AtomOrdersScreen());

  static Future<void> orderDetail(BuildContext context, String uuid) => _push(context, AtomOrderDetailScreen(uuid: uuid));

  static Future<void> customOrders(BuildContext context, {bool offers = false}) => _push(context, AtomCustomOrdersScreen(showOffers: offers));

  static Future<void> profile(BuildContext context) => _push(context, const AtomProfileScreen());

  static Future<void> changePassword(BuildContext context) => _push(context, const AtomPasswordScreen());

  static Future<void> notifications(BuildContext context) => _push(context, const AtomNotificationsScreen());

  static Future<void> payments(BuildContext context, {String orderUuid = ''}) => _push(context, AtomPaymentsScreen(orderUuid: orderUuid));

  static Future<void> receipt(BuildContext context, int paymentId) => _push(context, AtomReceiptScreen(paymentId: paymentId));

  // ── Help and info ───────────────────────────────────────────────────────

  static Future<void> about(BuildContext context) => _push(context, const AtomAboutScreen());

  static Future<void> why(BuildContext context) => _push(context, const AtomWhyScreen());

  static Future<void> apps(BuildContext context) => _push(context, const AtomAppsScreen());

  static Future<void> contact(BuildContext context) => _push(context, const AtomContactScreen());

  static Future<void> faqs(BuildContext context) => _push(context, const AtomFaqsScreen());

  static Future<void> legal(BuildContext context, {LegalTab tab = LegalTab.privacy}) => _push(context, AtomLegalScreen(tab: tab));

  // ── Tabs ────────────────────────────────────────────────────────────────

  /// Closes full-screen pages and switches to [tab].
  static void toTab(BuildContext context, WidgetRef ref, AtomTab tab) {
    Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
    ref.read(atomTabProvider.notifier).select(tab);
  }

  /// A screen that is designed but not built yet.
  static Future<void> placeholder(BuildContext context, String title, IconData icon) =>
      _push(context, AtomPlaceholderScreen(title: title, icon: icon));

  static Future<void> _push(BuildContext context, Widget page) =>
      Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => page));
}
