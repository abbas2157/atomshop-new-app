import 'dart:async';

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

  // ── In-memory session cache ────────────────────────────────────────────────
  // Every value is read from secure storage at most once per session and then
  // served from memory. This matters because flutter_secure_storage serialises
  // ALL reads through a single Android platform channel: one slow Keystore read
  // (which can take tens of seconds on some devices) blocks every read queued
  // behind it. Previously only the token was cached, so an unbounded read like
  // getBusinessName() on the dashboard could stall the channel and make the
  // next screen's data appear to "load" for up to a minute before its request
  // even fired. [_inflight] collapses concurrent first-reads of the same key
  // into one (single-flight); reads are bounded so a hung Keystore can never
  // block longer than [_readTimeout].
  static const Duration _readTimeout = Duration(seconds: 5);
  static final Map<String, String?> _cache = {};
  static final Map<String, Future<String?>> _inflight = {};

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
    // Prime the cache up front so no getter ever has to touch storage afterwards.
    _cache[_keyToken] = token;
    _cache[_keyUserId] = userId;
    _cache[_keyUserUuid] = userUuid;
    _cache[_keyUserName] = userName;
    _cache[_keyEmail] = email;
    _cache[_keyRole] = role;
    _cache[_keySellerId] = sellerId;
    _cache[_keyBusinessName] = businessName;
    _cache[_keyVerified] = verified ? '1' : '0';

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

  /// Reads [key] through the in-memory cache with single-flight + a bounded
  /// storage read, so a slow Keystore can never stall the caller indefinitely.
  static Future<String?> _read(String key) async {
    if (_cache.containsKey(key)) return _cache[key];

    final existing = _inflight[key];
    if (existing != null) return existing;

    final future = _readFromStorage(key);
    _inflight[key] = future;
    try {
      return await future;
    } finally {
      _inflight.remove(key);
    }
  }

  static Future<String?> _readFromStorage(String key) async {
    try {
      final value = await _storage.read(key: key).timeout(_readTimeout);
      // Cache the genuine result (including null) so it's never re-read.
      _cache[key] = value;
      return value;
    } on TimeoutException {
      // Do NOT cache a timeout — allow a later retry to succeed.
      return null;
    }
  }

  static Future<String?> getToken() => _read(_keyToken);
  static Future<String?> getUserId() => _read(_keyUserId);
  static Future<String?> getUserUuid() => _read(_keyUserUuid);
  static Future<String?> getUserName() => _read(_keyUserName);
  static Future<String?> getEmail() => _read(_keyEmail);
  static Future<String?> getRole() => _read(_keyRole);
  static Future<String?> getSellerId() => _read(_keySellerId);
  static Future<String?> getBusinessName() => _read(_keyBusinessName);

  static Future<bool> isVerified() async => await _read(_keyVerified) == '1';

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> logout() async {
    _cache.clear();
    _inflight.clear();
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
