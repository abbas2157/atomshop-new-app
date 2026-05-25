import 'package:atompro/core/auth/seller_session_manager.dart';
import 'package:atompro/core/network/api_endpoints.dart';
import 'package:atompro/core/network/network_manager.dart';
import 'package:atompro/core/network/network_provider.dart';
import 'package:atompro/features/seller/dashboard/model/seller_dashboard_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sellerDashboardRepositoryProvider = Provider<SellerDashboardRepository>((
  ref,
) {
  final network = ref.watch(networkManagerProvider);
  return SellerDashboardRepository(network);
});

class SellerDashboardRepository {
  final NetworkManager _network;

  SellerDashboardRepository(this._network);

  Future<SellerDashboardModel> getDashboard() async {
    final token = await SellerSessionManager.getToken();
    final response = await _network.getRequest(
      ApiEndpoints.sellerDashboard,
      token: token,
    );

    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to load dashboard.');
    }

    return SellerDashboardModel.fromResponse(
      Map<String, dynamic>.from(response),
    );
  }

  Future<SellerSalesRevenueModel> getSalesRevenue({
    String? from,
    String? to,
  }) async {
    final token = await SellerSessionManager.getToken();
    final queryParameters = <String, String>{};
    if (from != null && from.trim().isNotEmpty) {
      queryParameters['from'] = from.trim();
    }
    if (to != null && to.trim().isNotEmpty) {
      queryParameters['to'] = to.trim();
    }
    final endpoint = queryParameters.isEmpty
        ? ApiEndpoints.sellerSalesRevenue
        : '${ApiEndpoints.sellerSalesRevenue}?${Uri(queryParameters: queryParameters).query}';

    final response = await _network.getRequest(endpoint, token: token);

    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to load sales revenue.');
    }

    return SellerSalesRevenueModel.fromResponse(
      Map<String, dynamic>.from(response),
    );
  }
}
