import 'dart:io';

import 'package:atompro/core/auth/seller_session_manager.dart';
import 'package:atompro/core/network/api_endpoints.dart';
import 'package:atompro/core/network/network_manager.dart';
import 'package:atompro/core/network/network_provider.dart';
import 'package:atompro/features/seller/custom_orders/model/seller_custom_orders_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sellerCustomOrdersRepositoryProvider =
    Provider<SellerCustomOrdersRepository>((ref) {
      final network = ref.watch(networkManagerProvider);
      return SellerCustomOrdersRepository(network);
    });

class SellerCustomOrdersRepository {
  final NetworkManager _network;

  SellerCustomOrdersRepository(this._network);

  Future<SellerCustomOrdersResponse> getCustomOrders(
    SellerCustomOrdersQuery query,
  ) async {
    final token = await SellerSessionManager.getToken();
    final queryString = Uri(queryParameters: query.toQueryParameters()).query;
    final endpoint = queryString.isEmpty
        ? ApiEndpoints.sellerCustomOrders
        : '${ApiEndpoints.sellerCustomOrders}?$queryString';

    final response = await _network.getRequest(endpoint, token: token);
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to load custom orders.');
    }

    return SellerCustomOrdersResponse.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  Future<SellerCustomOrderDetails> getCustomOrderDetails(
    String orderUuid,
  ) async {
    final token = await SellerSessionManager.getToken();
    final response = await _network.getRequest(
      ApiEndpoints.sellerCustomOrderDetails(orderUuid),
      token: token,
    );

    if (response['success'] != true) {
      throw Exception(
        response['message'] ?? 'Failed to load custom order details.',
      );
    }

    return SellerCustomOrderDetails.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  Future<int> getPendingCount() async {
    final token = await SellerSessionManager.getToken();
    final response = await _network.getRequest(
      ApiEndpoints.sellerCustomOrdersPendingCount,
      token: token,
    );

    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to load pending count.');
    }

    return _countFromResponse(response);
  }

  Future<Map<String, int>> getStatusCounts() async {
    final token = await SellerSessionManager.getToken();
    final response = await _network.getRequest(
      ApiEndpoints.sellerCustomOrdersStatusCounts,
      token: token,
    );

    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to load status counts.');
    }

    return _statusCountsFromResponse(response);
  }

  Future<void> storeCustomOrder({
    required String userId,
    required String productId,
    required String totalDealPrice,
    required String advancePrice,
    required String perMonthPercentage,
    required String tenure,
    required String areaId,
    required String cityId,
  }) async {
    final token = await SellerSessionManager.getToken();
    final response = await _network
        .postRequest(ApiEndpoints.sellerStoreCustomOrder, {
          'user_id': userId,
          'product_id': productId,
          'total_deal_price': totalDealPrice,
          'advance_price': advancePrice,
          'per_month_percentage': perMonthPercentage,
          'tenure': tenure,
          'area_id': areaId,
          'city_id': cityId,
        }, token: token);

    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to create custom order.');
    }
  }

  Future<void> updateCustomOrderStatus({
    required String orderUuid,
    required Map<String, dynamic> body,
    Map<String, File> files = const {},
  }) async {
    final token = await SellerSessionManager.getToken();
    final dynamic response;
    if (files.isEmpty) {
      response = await _network.postRequest(
        ApiEndpoints.sellerCustomOrderStatus(orderUuid),
        body,
        token: token,
      );
    } else {
      response = await _network.postMultipartRequest(
        ApiEndpoints.sellerCustomOrderStatus(orderUuid),
        body,
        files,
        token: token,
      );
    }
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to update status.');
    }
  }

  Future<String> getCustomOrderPdfUrl(String orderUuid) async {
    final token = await SellerSessionManager.getToken();
    final response = await _network.getRequest(
      ApiEndpoints.sellerCustomOrderPdf(orderUuid),
      token: token,
    );

    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to load PDF URL.');
    }

    final data = response['data'] is Map
        ? Map<String, dynamic>.from(response['data'])
        : <String, dynamic>{};
    final url = data['url']?.toString().trim();
    if (url == null || url.isEmpty) throw Exception('PDF URL unavailable.');
    return url;
  }

  Future<void> closeCustomOrderDeal({
    required String orderUuid,
    required String paymentMethod,
    int? outstandingAmount,
    int? settlementAmount,
    int? recoveryMemberId,
    File? receipt,
  }) async {
    final token = await SellerSessionManager.getToken();
    final body = <String, dynamic>{'payment_method': paymentMethod};
    if (outstandingAmount != null) body['outstanding_amount'] = outstandingAmount;
    if (settlementAmount != null) body['settlement_amount'] = settlementAmount;
    if (recoveryMemberId != null) body['recovery_member_id'] = recoveryMemberId;

    final dynamic response;
    if (receipt == null) {
      response = await _network.postRequest(
        ApiEndpoints.sellerCustomOrderCloseDeal(orderUuid),
        body,
        token: token,
      );
    } else {
      response = await _network.postMultipartRequest(
        ApiEndpoints.sellerCustomOrderCloseDeal(orderUuid),
        body,
        {'receipt': receipt},
        token: token,
      );
    }
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to close deal.');
    }
  }

  Future<SellerCustomOrderGuarantor> getCustomOrderGuarantor(
    String orderUuid,
  ) async {
    final token = await SellerSessionManager.getToken();
    final response = await _network.getRequest(
      ApiEndpoints.sellerCustomOrderGuarantor(orderUuid),
      token: token,
    );

    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to load guarantor.');
    }

    return SellerCustomOrderGuarantor.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  Future<void> storeCustomOrderGuarantor({
    required String orderUuid,
    required String name,
    required String phone,
    required String cnic,
    required String address,
  }) async {
    final token = await SellerSessionManager.getToken();
    final response = await _network.postRequest(
      ApiEndpoints.sellerCustomOrderGuarantor(orderUuid),
      {'name': name, 'phone': phone, 'cnic': cnic, 'address': address},
      token: token,
    );

    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to save guarantor.');
    }
  }
}

int _countFromResponse(dynamic response) {
  final data = response['data'];
  if (data is num) return data.toInt();
  if (data is Map) {
    for (final key in const ['count', 'pending_count', 'total', 'pending']) {
      final value = data[key];
      final parsed = _asInt(value);
      if (parsed != null) return parsed;
    }
  }
  return _asInt(response['count']) ?? 0;
}

Map<String, int> _statusCountsFromResponse(dynamic response) {
  final data = response['data'];
  final source = data is Map && data['statuses'] is Map
      ? data['statuses'] as Map
      : data is Map
      ? data
      : const {};

  return source.map(
    (key, value) => MapEntry(_labelize(key.toString()), _asInt(value) ?? 0),
  );
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

String _labelize(String key) {
  return key
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .trim();
}
