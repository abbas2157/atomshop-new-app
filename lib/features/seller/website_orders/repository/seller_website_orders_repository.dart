import 'package:atompro/core/auth/seller_session_manager.dart';
import 'package:atompro/core/network/api_endpoints.dart';
import 'package:atompro/core/network/network_manager.dart';
import 'package:atompro/core/network/network_provider.dart';
import 'package:atompro/features/seller/website_orders/model/seller_website_orders_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sellerWebsiteOrdersRepositoryProvider =
    Provider<SellerWebsiteOrdersRepository>((ref) {
  return SellerWebsiteOrdersRepository(ref.watch(networkManagerProvider));
});

class SellerWebsiteOrdersRepository {
  final NetworkManager _network;

  SellerWebsiteOrdersRepository(this._network);

  Future<SellerWebsiteOrdersResponse> getWebsiteOrders({
    String? search,
    int page = 1,
  }) async {
    final token = await SellerSessionManager.getToken();
    var endpoint = ApiEndpoints.sellerWebsiteOrders;
    final params = <String, String>{'page': page.toString()};
    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }
    final qs = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    endpoint = '$endpoint?$qs';

    final response = await _network.getRequest(endpoint, token: token);
    if (response['success'] != true) {
      throw Exception(
        response['message'] ?? 'Failed to load website orders.',
      );
    }
    return SellerWebsiteOrdersResponse.fromResponse(
      Map<String, dynamic>.from(response),
    );
  }
}
