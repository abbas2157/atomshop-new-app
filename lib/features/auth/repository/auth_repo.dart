import 'package:atompro/core/network/api_endpoints.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:atompro/core/network/network_manager.dart';

part 'auth_repo.g.dart';

@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepository(NetworkManager.create());
}

class AuthRepository {
  final NetworkManager _network;
  AuthRepository(this._network);

  Future<Map<String, dynamic>> login(String email, String password) async {
    final body = {'email': email, 'password': password};
    return await _network.postRequest(ApiEndpoints.login, body);
  }

  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    final body = {
      'name': name,
      'email': email,
      'password': password,
      'c_password': password,
    };
    return await _network.postRequest(ApiEndpoints.signup, body);
  }

  /// Used for signup OTP — sends user_id (int id as string)
  Future<Map<String, dynamic>> verifyOtp(String userId, String code) async {
    final body = {'user_id': userId, 'code': code};
    return await _network.postRequest(ApiEndpoints.verifyOTP, body);
  }

  /// Used for signup resend — sends email
  Future<Map<String, dynamic>> resendOtp(String email) async {
    final body = {'email': email};
    return await _network.postRequest(ApiEndpoints.sendOTP, body);
  }

  /// Forgot password step 1 — send OTP to email, returns uuid in response
  Future<Map<String, dynamic>> sendForgotPasswordOtp(String email) async {
    final body = {'email': email};
    return await _network.postRequest(ApiEndpoints.sendOTP, body);
  }

  /// Forgot password step 2 — verify OTP using uuid (not int id!)
  Future<Map<String, dynamic>> verifyForgotPasswordOtp(
    String uuid,
    String code,
  ) async {
    final body = {'user_id': uuid, 'code': code};
    return await _network.postRequest(ApiEndpoints.verifyOTP, body);
  }

  /// Forgot password step 3 — set new password using uuid
  Future<Map<String, dynamic>> setNewPassword({
    required String uuid,
    required String password,
  }) async {
    final body = {
      'user_id': uuid,
      'password': password,
      'c_password': password,
    };
    return await _network.postRequest(ApiEndpoints.setPassword, body);
  }
}
