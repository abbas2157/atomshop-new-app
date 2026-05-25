import 'package:atompro/core/mode/app_mode.dart';
import 'package:atompro/core/auth/seller_session_manager.dart';
import 'package:atompro/core/routes/app_route_constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppModeManager {
  AppModeManager._();

  static const _storage = FlutterSecureStorage(aOptions: AndroidOptions());
  static const _keyAppMode = 'app_mode';

  static Future<AppMode> getMode() async {
    final value = await _storage.read(key: _keyAppMode);
    return AppMode.fromStorage(value);
  }

  static Future<void> setMode(AppMode mode) async {
    await _storage.write(key: _keyAppMode, value: mode.storageValue);
  }

  static Future<bool> isSellerMode() async {
    return await getMode() == AppMode.seller;
  }

  static Future<void> switchToCustomer() async {
    await setMode(AppMode.customer);
  }

  static Future<void> switchToSeller() async {
    await setMode(AppMode.seller);
  }

  static Future<String> resolveSellerLandingRoute() async {
    final sellerLoggedIn = await SellerSessionManager.isLoggedIn();
    return sellerLoggedIn ? AppRoutes.sellerShell : AppRoutes.sellerLogin;
  }
}
