import 'package:atompro/core/auth/seller_session_manager.dart';
import 'package:atompro/core/network/api_endpoints.dart';
import 'package:atompro/core/network/network_manager.dart';
import 'package:atompro/core/network/network_provider.dart';
import 'package:atompro/features/seller/fee_charge/model/seller_fee_charge_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sellerFeeChargeRepositoryProvider = Provider<SellerFeeChargeRepository>((
  ref,
) {
  return SellerFeeChargeRepository(ref.watch(networkManagerProvider));
});

class SellerFeeChargeRepository {
  final NetworkManager _network;

  SellerFeeChargeRepository(this._network);

  Future<SellerFeeChargeResponse> getFeeCharges({int page = 1}) async {
    final response = await _get('${ApiEndpoints.sellerFeeCharge}?page=$page');
    return SellerFeeChargeResponse.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  Future<void> payFeeCharge() async {
    final token = await SellerSessionManager.getToken();
    final response = await _network.postRequest(
      ApiEndpoints.sellerPayFeeCharge,
      const {},
      token: token,
    );

    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to pay fee charge.');
    }
  }

  Future<dynamic> _get(String endpoint) async {
    final token = await SellerSessionManager.getToken();
    final response = await _network.getRequest(endpoint, token: token);
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Request failed.');
    }
    return response;
  }
}
