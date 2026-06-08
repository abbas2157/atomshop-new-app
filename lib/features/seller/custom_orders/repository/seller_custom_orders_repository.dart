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

  Future<List<SellerCustomOrderLookup>> getCategories() => _lookup(
        ApiEndpoints.categories,
      );

  Future<List<SellerCustomOrderLookup>> getBrands() => _lookup(
        ApiEndpoints.brands,
      );

  Future<List<SellerCustomOrderLookup>> _lookup(String endpoint) async {
    final token = await SellerSessionManager.getToken();
    final response = await _network.getRequest(endpoint, token: token);
    final raw = response is Map
        ? (response['data'] ?? response)
        : response;
    final list = raw is List
        ? raw
        : (raw is Map && raw['data'] is List ? raw['data'] as List : const []);
    return list
        .whereType<Map>()
        .map(
          (item) =>
              SellerCustomOrderLookup.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);
  }

  /// Create a custom order (see Custom Orders API — Store). Product is created
  /// inline; `area_id`/`city_id` are taken server-side from the customer.
  /// [categoryId]/[brandId] may be a numeric id string or the literal `"other"`
  /// (then send the matching *_title). [detailTitles]/[detailValues] are spec
  /// pairs sent as `detail_titles[]` / `detail_values[]`.
  Future<void> storeCustomOrder({
    required String customerId,
    String? categoryId,
    String? categoryTitle,
    String? brandId,
    String? brandTitle,
    String? productTitle,
    String? productPrice,
    String? advancePrice,
    List<String> detailTitles = const [],
    List<String> detailValues = const [],
    String? tenureMonths,
    String? perMonthPercentage,
    String? totalDealPrice,
    File? picture,
  }) async {
    final token = await SellerSessionManager.getToken();

    final data = <String, dynamic>{
      'customer_id': customerId,
      if (_has(categoryId)) 'category_id': categoryId,
      if (categoryId == 'other' && _has(categoryTitle))
        'category_title': categoryTitle,
      if (_has(brandId)) 'brand_id': brandId,
      if (brandId == 'other' && _has(brandTitle)) 'brand_title': brandTitle,
      if (_has(productTitle)) 'product_title': productTitle,
      if (_has(productPrice)) 'product_price': productPrice,
      if (_has(advancePrice)) 'advance_price': advancePrice,
      if (_has(tenureMonths)) 'tenure_months': tenureMonths,
      if (_has(perMonthPercentage)) 'per_month_percentage': perMonthPercentage,
      if (_has(totalDealPrice)) 'total_deal_price': totalDealPrice,
      if (detailTitles.isNotEmpty) 'detail_titles[]': detailTitles,
      if (detailValues.isNotEmpty) 'detail_values[]': detailValues,
    };

    final response = await _network.postMultipartRequest(
      ApiEndpoints.sellerStoreCustomOrder,
      data,
      {if (picture != null) 'picture': picture},
      token: token,
    );

    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to create custom order.');
    }
  }

  bool _has(String? v) => v != null && v.trim().isNotEmpty;

  // ── Status transitions (see Custom Order Status Update API) ──────────────
  // NOTE: "Varification", "recieved_by", "delivered_pictrue" and
  // "instalment_pictrue" are intentional spellings required by the backend.

  /// STATUS 1 — Varification (requires a verification comment).
  Future<void> setVarification({
    required String orderUuid,
    required String comment,
  }) {
    return _postStatus(orderUuid, {
      'status': 'Varification',
      'comment': comment,
    });
  }

  /// STATUS 2 — Processing. Optionally attach up to 2 guarantors. Each entry is
  /// a map of the guarantor fields (name, father_name, cnic, profession,
  /// relation, res_address, office_address, res_tel, office_tel, house_type).
  Future<void> setProcessing({
    required String orderUuid,
    List<Map<String, String>> guarantors = const [],
  }) {
    return _postStatus(orderUuid, {
      'status': 'Processing',
      if (guarantors.isNotEmpty) 'guarantor': guarantors,
    });
  }

  /// STATUS 3 — Delivered. [receivedBy] = "By Himself" | "By Someone else".
  Future<void> setDelivered({
    required String orderUuid,
    required String receivedBy,
    File? photo,
  }) {
    return _postStatus(
      orderUuid,
      {'status': 'Delivered', 'recieved_by': receivedBy},
      file: photo,
      fileField: 'delivered_pictrue',
    );
  }

  /// STATUS 4 — Instalments. Generates the full schedule + advance record.
  Future<void> setInstalments({
    required String orderUuid,
    required String advancePrice,
    required String perMonthPercentage,
    required String sourcingAgentFee,
    required String installmentTenure,
    required String paymentMethod,
    String? dayOfMonth,
    String? recoveryMemberId,
    File? receipt,
  }) {
    return _postStatus(
      orderUuid,
      {
        'status': 'Instalments',
        'advance_price': advancePrice,
        'per_month_percentage': perMonthPercentage,
        'sourcing_agent_fee': sourcingAgentFee,
        'installment_tenure': installmentTenure,
        'payment_method': paymentMethod,
        if (dayOfMonth != null && dayOfMonth.isNotEmpty)
          'day_of_month': dayOfMonth,
        if (recoveryMemberId != null && recoveryMemberId.isNotEmpty)
          'recovery_member_id': recoveryMemberId,
      },
      file: receipt,
      fileField: 'instalment_pictrue',
    );
  }

  /// STATUS 5 — Completed (server validates all installments are paid).
  Future<void> setCompleted({required String orderUuid}) {
    return _postStatus(orderUuid, {'status': 'Completed'});
  }

  /// STATUS 6 — Cancelled. Allowed at any stage without customer verification.
  Future<void> setCancelled({
    required String orderUuid,
    String? customerVerificationFailed,
    String? installmentPlanRejected,
    String? productUnavailable,
    String? reason,
  }) {
    return _postStatus(orderUuid, {
      'status': 'Cancelled',
      if (customerVerificationFailed != null)
        'customer_verification_failed': customerVerificationFailed,
      if (installmentPlanRejected != null)
        'installment_plan_rejected': installmentPlanRejected,
      if (productUnavailable != null) 'product_unavailable': productUnavailable,
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
    });
  }

  Future<void> _postStatus(
    String orderUuid,
    Map<String, dynamic> data, {
    File? file,
    String? fileField,
  }) async {
    final token = await SellerSessionManager.getToken();
    final endpoint = ApiEndpoints.sellerCustomOrderStatus(orderUuid);
    final response = (file != null && fileField != null)
        ? await _network.postMultipartRequest(
            endpoint,
            data.map((k, v) => MapEntry(k, v is List ? v : v.toString())),
            {fileField: file},
            token: token,
          )
        : await _network.postRequest(endpoint, data, token: token);

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

  /// Close Deal (early settlement). Sets status to Completed regardless of
  /// unpaid installments. Customer verification is NOT required.
  /// [paymentMethod] = "By Hand" | "JazzCash" | "Easypaisa" | "Bank".
  Future<void> closeCustomOrderDeal({
    required String orderUuid,
    String? outstandingAmount,
    String settlementAmount = '0',
    required String paymentMethod,
    String? recoveryMemberId,
    File? receipt,
  }) async {
    final token = await SellerSessionManager.getToken();
    final endpoint = ApiEndpoints.sellerCustomOrderCloseDeal(orderUuid);
    final data = <String, dynamic>{
      if (outstandingAmount != null && outstandingAmount.isNotEmpty)
        'outstanding_amount': outstandingAmount,
      'settlement_amount': settlementAmount,
      'payment_method': paymentMethod,
      if (recoveryMemberId != null && recoveryMemberId.isNotEmpty)
        'recovery_member_id': recoveryMemberId,
    };

    final response = receipt != null
        ? await _network.postMultipartRequest(
            endpoint,
            data.map((k, v) => MapEntry(k, v.toString())),
            {'receipt': receipt},
            token: token,
          )
        : await _network.postRequest(endpoint, data, token: token);

    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to close deal.');
    }
  }

  /// Pay Instalment — pays the next unpaid instalment for the order. The
  /// server finds the first `Unpaid` instalment of type `Instalment` or
  /// `Outstanding` and marks it `Paid`; [orderUuid]'s numeric order id
  /// (not uuid) must be sent as `order_id`.
  /// [paymentMethod] = "By Hand" | "JazzCash" | "Easypaisa" | "Bank".
  Future<void> payInstalment({
    required int orderId,
    required String instalmentPrice,
    required String paymentMethod,
    String? recoveryMemberId,
    File? receipt,
  }) async {
    final token = await SellerSessionManager.getToken();
    final data = <String, dynamic>{
      'order_id': orderId.toString(),
      'instalment_price': instalmentPrice,
      'payment_method': paymentMethod,
      if (recoveryMemberId != null && recoveryMemberId.isNotEmpty)
        'recovery_member_id': recoveryMemberId,
    };

    final response = receipt != null
        ? await _network.postMultipartRequest(
            ApiEndpoints.sellerPayInstalment,
            data,
            {'instalment_pictrue': receipt},
            token: token,
          )
        : await _network.postRequest(
            ApiEndpoints.sellerPayInstalment,
            data,
            token: token,
          );

    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to pay instalment.');
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
