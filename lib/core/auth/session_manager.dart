import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionManager {
  // Encrypted storage instance
  static const _storage = FlutterSecureStorage(aOptions: AndroidOptions());

  static const String _keyToken = "auth_token";
  static const String _keyUserId = "user_id";
  static const String _keyUserUuid = "user_uuid";
  static const String _keyUserName = "user_name";

  /// Save the session after Login/OTP success
  static Future<void> saveUserSession({
    required String token,
    required String userId,
    required String username,
    required String userUuid,
  }) async {
    await _storage.write(key: _keyToken, value: token);
    await _storage.write(key: _keyUserId, value: userId);
    await _storage.write(key: _keyUserUuid, value: userUuid);
    await _storage.write(key: _keyUserName, value: username);
  }

  /// Retrieve the token for API headers
  static Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  /// Retrieve user ID
  static Future<String?> getUserId() async {
    return await _storage.read(key: _keyUserId);
  }

  /// Retrieve user UUID
  static Future<String?> getUserUuid() async {
    return await _storage.read(key: _keyUserUuid);
  }

  static Future<String?> getUserName() async {
    return await _storage.read(key: _keyUserName);
  }

  static Future<String?> getUserNameTwoCharchters() async {
    String? name = await _storage.read(key: _keyUserName);

    if (name != null && name.trim().isNotEmpty) {
      List<String> parts = name.trim().split(
        RegExp(r'\s+'),
      ); // handles extra spaces

      if (parts.length >= 2) {
        return (parts[0][0] + parts[1][0]).toUpperCase();
      } else {
        // If only one word like "Muhammad"
        return parts[0][0].toUpperCase();
      }
    }

    return null;
  }

  /// Check if user is authenticated
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Wipe everything on Logout
  static Future<void> logout() async {
    await _storage.deleteAll();
  }
}
