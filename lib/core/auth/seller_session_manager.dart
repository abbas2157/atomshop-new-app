import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SellerSessionManager {
  SellerSessionManager._();

  static const _storage = FlutterSecureStorage(aOptions: AndroidOptions());

  static const String _keyToken = 'seller_auth_token';
  static const String _keyUserId = 'seller_user_id';
  static const String _keyUserUuid = 'seller_user_uuid';
  static const String _keyUserName = 'seller_user_name';
  static const String _keyEmail = 'seller_email';
  static const String _keyRole = 'seller_role';
  static const String _keySellerId = 'seller_id';
  static const String _keyBusinessName = 'seller_business_name';
  static const String _keyVerified = 'seller_verified';

  static Future<void> saveSellerSession({
    required String token,
    required String userId,
    required String userUuid,
    required String userName,
    required String email,
    required String role,
    required String sellerId,
    required String businessName,
    required bool verified,
  }) async {
    await _storage.write(key: _keyToken, value: token);
    await _storage.write(key: _keyUserId, value: userId);
    await _storage.write(key: _keyUserUuid, value: userUuid);
    await _storage.write(key: _keyUserName, value: userName);
    await _storage.write(key: _keyEmail, value: email);
    await _storage.write(key: _keyRole, value: role);
    await _storage.write(key: _keySellerId, value: sellerId);
    await _storage.write(key: _keyBusinessName, value: businessName);
    await _storage.write(key: _keyVerified, value: verified ? '1' : '0');
  }

  static Future<String?> getToken() =>
      _storage.read(key: _keyToken).timeout(
        const Duration(seconds: 8),
        onTimeout: () => null,
      );
  static Future<String?> getUserId() => _storage.read(key: _keyUserId);
  static Future<String?> getUserUuid() => _storage.read(key: _keyUserUuid);
  static Future<String?> getUserName() => _storage.read(key: _keyUserName);
  static Future<String?> getEmail() => _storage.read(key: _keyEmail);
  static Future<String?> getRole() => _storage.read(key: _keyRole);
  static Future<String?> getSellerId() => _storage.read(key: _keySellerId);
  static Future<String?> getBusinessName() =>
      _storage.read(key: _keyBusinessName);

  static Future<bool> isVerified() async {
    return await _storage.read(key: _keyVerified) == '1';
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> logout() async {
    await Future.wait([
      _storage.delete(key: _keyToken),
      _storage.delete(key: _keyUserId),
      _storage.delete(key: _keyUserUuid),
      _storage.delete(key: _keyUserName),
      _storage.delete(key: _keyEmail),
      _storage.delete(key: _keyRole),
      _storage.delete(key: _keySellerId),
      _storage.delete(key: _keyBusinessName),
      _storage.delete(key: _keyVerified),
    ]);
  }
}
