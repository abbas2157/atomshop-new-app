import 'package:atompro/core/auth/seller_session_manager.dart';
import 'package:atompro/core/network/api_endpoints.dart';
import 'package:atompro/core/network/network_manager.dart';
import 'package:atompro/core/network/network_provider.dart';
import 'package:atompro/features/seller/standard_orders/model/seller_standard_orders_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sellerStandardOrdersRepositoryProvider =
    Provider<SellerStandardOrdersRepository>((ref) {
      return SellerStandardOrdersRepository(ref.watch(networkManagerProvider));
    });

class SellerStandardOrdersRepository {
  final NetworkManager _network;

  SellerStandardOrdersRepository(this._network);

  Future<SellerStandardOrdersResponse> getOrders({int page = 1}) async {
    final response = await _get('${ApiEndpoints.sellerOrders}?page=$page');
    return SellerStandardOrdersResponse.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  Future<SellerStandardOrderDetails> getOrderDetails(String orderUuid) async {
    final response = await _get(ApiEndpoints.sellerOrderDetails(orderUuid));
    return SellerStandardOrderDetails.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  Future<void> updateStatus({
    required String orderUuid,
    required String status,
    required String receivedBy,
  }) async {
    final response = await _post(ApiEndpoints.sellerOrderStatus(orderUuid), {
      'status': status,
      'recieved_by': receivedBy,
    });

    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to update order status.');
    }
  }

  Future<String> getPdfUrl(String orderUuid) async {
    final response = await _get(ApiEndpoints.sellerOrderPdf(orderUuid));
    final data = response['data'] is Map
        ? Map<String, dynamic>.from(response['data'])
        : <String, dynamic>{};
    final url = data['url']?.toString().trim();
    if (url == null || url.isEmpty) throw Exception('Order PDF unavailable.');
    return url;
  }

  Future<void> storeOrder({
    required String customerId,
    required String productId,
    required String areaId,
    required String cityId,
    required String minAdvancePrice,
    required String tenureMonths,
  }) async {
    final response = await _post(ApiEndpoints.sellerStoreOrder, {
      'customer_id': customerId,
      'product_id': productId,
      'area_id': areaId,
      'city_id': cityId,
      'min_advance_price': minAdvancePrice,
      'tenure_months': tenureMonths,
    });

    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to create order.');
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

  Future<dynamic> _post(String endpoint, Map<String, dynamic> data) async {
    final token = await SellerSessionManager.getToken();
    return _network.postRequest(endpoint, data, token: token);
  }
}
