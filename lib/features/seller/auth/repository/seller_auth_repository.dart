import 'package:atompro/core/auth/seller_session_manager.dart';
import 'package:atompro/core/network/api_endpoints.dart';
import 'package:atompro/core/network/network_manager.dart';
import 'package:atompro/core/network/network_provider.dart';
import 'package:atompro/core/services/fcm_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sellerAuthRepositoryProvider = Provider<SellerAuthRepository>((ref) {
  final network = ref.watch(networkManagerProvider);
  return SellerAuthRepository(network);
});

class SellerAuthRepository {
  final NetworkManager _network;

  SellerAuthRepository(this._network);

  Future<void> login({required String email, required String password}) async {
    final body = {'email': email, 'password': password};
    final fcmToken = await FcmService.getToken();
    if (fcmToken != null && fcmToken.isNotEmpty) {
      body['fcm_token'] = fcmToken;
    }

    final response = await _network.postRequest(ApiEndpoints.sellerLogin, body);

    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Seller login failed.');
    }

    final data = response['data'] as Map<String, dynamic>? ?? {};
    final user = data['user'] as Map<String, dynamic>? ?? {};
    final seller = data['seller'] as Map<String, dynamic>? ?? {};

    await SellerSessionManager.saveSellerSession(
      token: data['token'].toString(),
      userId: user['id'].toString(),
      userUuid: user['uuid'].toString(),
      userName: user['name'].toString(),
      email: user['email'].toString(),
      role: user['role'].toString(),
      sellerId: seller['id'].toString(),
      businessName: seller['business_name'].toString(),
      verified: seller['verified'].toString() == '1',
    );
    await FcmService.attachUser(userId: user['id'].toString());
  }

  Future<void> logout() async {
    await FcmService.unlinkUser();
    final token = await SellerSessionManager.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        await _network.postRequest(
          ApiEndpoints.sellerLogout,
          const {},
          token: token,
        );
      } catch (_) {
        // Local logout must still complete if the server session is expired.
      }
    }
    await SellerSessionManager.logout();
  }
}
