import 'package:atompro/core/mode/app_mode.dart';
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
}
