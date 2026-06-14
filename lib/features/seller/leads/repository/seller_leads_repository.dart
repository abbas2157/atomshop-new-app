import 'dart:io';

import 'package:atompro/core/auth/seller_session_manager.dart';
import 'package:atompro/core/network/api_endpoints.dart';
import 'package:atompro/core/network/network_manager.dart';
import 'package:atompro/core/network/network_provider.dart';
import 'package:atompro/features/seller/core/services/seller_file_service.dart';
import 'package:atompro/features/seller/leads/model/seller_leads_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sellerLeadsRepositoryProvider = Provider<SellerLeadsRepository>((ref) {
  return SellerLeadsRepository(ref.watch(networkManagerProvider));
});

class SellerLeadsRepository {
  final NetworkManager _network;

  SellerLeadsRepository(this._network);

  // ── Leads list + bundle ──────────────────────────────────────────────────────

  Future<SellerLeadsBundle> getLeadsBundle(SellerLeadsQuery query) async {
    // eagerError: surface the plan-gate (thrown by getLeads) the instant it
    // fails rather than waiting for the other two parallel calls to settle.
    final results = await Future.wait([
      getLeads(query),
      getStatusCounts(query.scope),
      if (query.scope == SellerLeadScope.mine)
        getNewLeadsCount().catchError((_) => 0)
      else
        Future.value(0),
    ], eagerError: true);
    return SellerLeadsBundle(
      leads: results[0] as SellerLeadsResponse,
      statusCounts: results[1] as Map<String, int>,
      newLeadsCount: results[2] as int,
    );
  }

  Future<SellerLeadsResponse> getLeads(SellerLeadsQuery query) async {
    final base = query.scope == SellerLeadScope.mine
        ? ApiEndpoints.sellerLeads
        : ApiEndpoints.sellerOtherLeads;
    final queryString = Uri(queryParameters: query.toQueryParameters()).query;
    final endpoint = queryString.isEmpty ? base : '$base?$queryString';
    final response = await _get(endpoint);
    return SellerLeadsResponse.fromJson(Map<String, dynamic>.from(response));
  }

  Future<Map<String, int>> getStatusCounts(SellerLeadScope scope) async {
    final endpoint = scope == SellerLeadScope.mine
        ? ApiEndpoints.sellerLeadStatusCounts
        : ApiEndpoints.sellerOtherLeadStatusCounts;
    try {
      final response = await _get(endpoint);
      final data = response['data'] is Map
          ? Map<String, dynamic>.from(response['data'])
          : <String, dynamic>{};
      return data.map((key, value) => MapEntry(_labelize(key), _asInt(value)));
    } catch (_) {
      return const {};
    }
  }

  Future<int> getNewLeadsCount() async {
    final response = await _get(ApiEndpoints.sellerNewLeadsCount);
    final data = response['data'] is Map
        ? Map<String, dynamic>.from(response['data'])
        : <String, dynamic>{};
    return _asInt(data['count']);
  }

  // ── Update lead status ───────────────────────────────────────────────────────

  /// POST seller-app/leads/update/{id}
  /// Fields: status (required), reason (optional — send when status=Lost),
  ///         comments (optional)
  Future<void> updateLead({
    required int leadId,
    required String status,
    String? reason,
    String? comments,
  }) async {
    final body = <String, dynamic>{'status': status};
    if (reason != null && reason.trim().isNotEmpty) {
      body['reason'] = reason.trim();
    }
    if (comments != null && comments.trim().isNotEmpty) {
      body['comments'] = comments.trim();
    }
    final response = await _post(ApiEndpoints.sellerLeadUpdate(leadId), body);
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to update lead.');
    }
  }

  // ── Convert lead → custom order ──────────────────────────────────────────────

  /// POST seller-app/leads/custom-order/{id}
  /// Payload: city_id, area_id, user_type (auth|guest),
  ///          product_price, advance_price, installments, per_month_percentage
  Future<Map<String, dynamic>> convertLeadToCustomOrder({
    required int leadId,
    required String userType,
    required int cityId,
    required int areaId,
    required int productPrice,
    required int advancePrice,
    required num perMonthPercentage,
    required int installments,
    // kept for signature compat — not sent to API
    int totalDealPrice = 0,
  }) async {
    final body = <String, dynamic>{
      'user_type': userType,
      'city_id': cityId.toString(),
      'area_id': areaId.toString(),
      'product_price': productPrice.toString(),
      'advance_price': advancePrice.toString(),
      'per_month_percentage': perMonthPercentage.toString(),
      'installments': installments.toString(),
    };
    final response = await _post(
      ApiEndpoints.sellerLeadCustomOrder(leadId),
      body,
    );
    if (response['success'] != true) {
      throw Exception(
        response['message'] ?? 'Failed to create custom order from lead.',
      );
    }
    return response['data'] is Map
        ? Map<String, dynamic>.from(response['data'])
        : {};
  }

  // ── Lookup APIs for the convert-to-order form ────────────────────────────────

  /// GET api/cities  →  data is a flat List [{id, title}, ...]
  Future<List<SellerLeadLookup>> getCities() async {
    final response = await _get(ApiEndpoints.cities);
    return _parseFlatList(response['data']);
  }

  /// GET api/areas/{cityId}  →  data is a flat List [{id, title}, ...]
  Future<List<SellerLeadLookup>> getAreasByCity(int cityId) async {
    final response = await _get(ApiEndpoints.areasByCity(cityId));
    return _parseFlatList(response['data']);
  }

  /// GET api/categories  →  data is a flat List or wrapped in 'data' key
  Future<List<SellerLeadLookup>> getCategories() async {
    final response = await _get(ApiEndpoints.categories);
    return _parseFlatList(response['data']);
  }

  /// GET api/brands  →  data is a flat List or wrapped in 'data' key
  Future<List<SellerLeadLookup>> getBrands() async {
    final response = await _get(ApiEndpoints.brands);
    return _parseFlatList(response['data']);
  }

  // ── Import / export ──────────────────────────────────────────────────────────

  Future<void> importLeads(File file) async {
    final token = await SellerSessionManager.getToken();
    final response = await _network.postMultipartRequest(
      ApiEndpoints.sellerImportLeads,
      const {},
      {'file': file},
      token: token,
    );
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to import leads.');
    }
  }

  Future<String> downloadImportSample() {
    return SellerFileService.downloadAuthenticatedFile(
      endpoint: ApiEndpoints.sellerLeadsSample,
      fileName: 'atomshop_leads_import_sample.xlsx',
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  /// Parses a flat List response into [SellerLeadLookup] items.
  /// Handles both direct List and {data: [...]} formats.
  List<SellerLeadLookup> _parseFlatList(dynamic data) {
    final list = data is List
        ? data
        : (data is Map ? (data['data'] as List? ?? []) : <dynamic>[]);
    return list
        .whereType<Map>()
        .map(
          (item) => SellerLeadLookup.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);
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

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _labelize(String key) {
  return key
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .replaceAll('-', ' ')
      .trim();
}
