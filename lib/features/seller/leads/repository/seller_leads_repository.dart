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

  Future<SellerLeadsBundle> getLeadsBundle(SellerLeadsQuery query) async {
    final leads = await getLeads(query);
    final counts = await getStatusCounts(query.scope);
    final newCount = query.scope == SellerLeadScope.mine
        ? await getNewLeadsCount()
        : 0;

    return SellerLeadsBundle(
      leads: leads,
      statusCounts: counts,
      newLeadsCount: newCount,
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

  Future<void> updateLead({
    required int leadId,
    required String status,
    required String comments,
  }) async {
    final response = await _post(ApiEndpoints.sellerLeadUpdate(leadId), {
      'status': status,
      'comments': comments,
    });

    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to update lead.');
    }
  }

  Future<void> createCustomOrderFromLead({
    required int leadId,
    required String userType,
    required String productPrice,
    required String advancePrice,
    required String installments,
    required String perMonthPercentage,
  }) async {
    final response = await _post(ApiEndpoints.sellerLeadCustomOrder(leadId), {
      'user_type': userType,
      'product_price': productPrice,
      'advance_price': advancePrice,
      'installments': installments,
      'per_month_percentage': perMonthPercentage,
    });

    if (response['success'] != true) {
      throw Exception(
        response['message'] ?? 'Failed to create custom order from lead.',
      );
    }
  }

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
