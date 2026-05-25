import 'package:atompro/core/auth/seller_session_manager.dart';
import 'package:atompro/core/network/api_endpoints.dart';
import 'package:atompro/core/network/network_manager.dart';
import 'package:atompro/core/network/network_provider.dart';
import 'package:atompro/features/seller/investments/model/seller_investment_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sellerInvestmentsRepositoryProvider =
    Provider<SellerInvestmentsRepository>((ref) {
      return SellerInvestmentsRepository(ref.watch(networkManagerProvider));
    });

class SellerInvestmentsRepository {
  final NetworkManager _network;

  SellerInvestmentsRepository(this._network);

  Future<SellerInvestmentsResponse> getInvestments({int page = 1}) async {
    final response = await _get('${ApiEndpoints.sellerInvestments}?page=$page');
    return SellerInvestmentsResponse.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  Future<SellerInvestmentDetails> getInvestmentDetails(int investmentId) async {
    final response = await _get(
      ApiEndpoints.sellerInvestmentDetails(investmentId),
    );
    return SellerInvestmentDetails.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  Future<void> updateStatus({
    required int investmentId,
    required String status,
  }) async {
    final token = await SellerSessionManager.getToken();
    final response = await _network.postRequest(
      ApiEndpoints.sellerInvestmentStatus(investmentId),
      {'status': status},
      token: token,
    );

    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to update investment.');
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
