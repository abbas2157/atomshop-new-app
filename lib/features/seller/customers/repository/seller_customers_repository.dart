import 'dart:io';

import 'package:atompro/core/auth/seller_session_manager.dart';
import 'package:atompro/core/network/api_endpoints.dart';
import 'package:atompro/core/network/network_manager.dart';
import 'package:atompro/core/network/network_provider.dart';
import 'package:atompro/features/seller/core/services/seller_file_service.dart';
import 'package:atompro/features/seller/customers/model/seller_customers_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sellerCustomersRepositoryProvider = Provider<SellerCustomersRepository>((
  ref,
) {
  return SellerCustomersRepository(ref.watch(networkManagerProvider));
});

class SellerCustomersRepository {
  final NetworkManager _network;

  SellerCustomersRepository(this._network);

  Future<SellerCustomersResponse> getCustomers(
    SellerCustomersQuery query,
  ) async {
    final endpoint = switch (query.scope) {
      SellerCustomerScope.all => ApiEndpoints.sellerCustomers,
      SellerCustomerScope.mine => ApiEndpoints.sellerMyCustomers,
      SellerCustomerScope.other => ApiEndpoints.sellerOtherCustomers,
    };
    final response = await _get(_withPage(endpoint, query.page));
    return SellerCustomersResponse.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  Future<int> getNotificationCount() async {
    final response = await _get(ApiEndpoints.sellerCustomersNotificationCount);
    final data = response['data'] is Map
        ? Map<String, dynamic>.from(response['data'])
        : <String, dynamic>{};
    return int.tryParse(data['count']?.toString() ?? '') ?? 0;
  }

  Future<SellerCustomerDetails> getCustomerProfile(String customerUuid) async {
    final response = await _get(
      ApiEndpoints.sellerCustomerProfile(customerUuid),
    );
    return SellerCustomerDetails.fromJson(Map<String, dynamic>.from(response));
  }

  Future<SellerCustomerInstalmentsResponse> getCustomerInstalments({
    required String customerUuid,
    int page = 1,
  }) async {
    final response = await _get(
      _withPage(ApiEndpoints.sellerCustomerInstalments(customerUuid), page),
    );
    return SellerCustomerInstalmentsResponse.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  Future<SellerCustomerCustomOrdersResponse> getCustomerCustomOrders({
    required String customerUuid,
    int page = 1,
  }) async {
    final response = await _get(
      _withPage(ApiEndpoints.sellerCustomerCustomOrders(customerUuid), page),
    );
    return SellerCustomerCustomOrdersResponse.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  Future<List<SellerCustomerArea>> getAreasByCity(int cityId) async {
    final response = await _get(ApiEndpoints.sellerCustomerAreasByCity(cityId));
    final data = response['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map(
          (item) =>
              SellerCustomerArea.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);
  }

  Future<void> storeCustomer({
    required String name,
    required String phone,
    required String email,
    required String fatherName,
    required String cnicNo,
    required String cityId,
    required String areaId,
    required String address,
    File? idCardFrontSide,
    File? idCardBackSide,
  }) async {
    final token = await SellerSessionManager.getToken();
    final files = <String, File>{};
    if (idCardFrontSide != null) files['id_card_front_side'] = idCardFrontSide;
    if (idCardBackSide != null) files['id_card_back_side'] = idCardBackSide;

    final response = await _network.postMultipartRequest(
      ApiEndpoints.sellerStoreCustomer,
      {
        'name': name,
        'phone': phone,
        'email': email,
        'father_name': fatherName,
        'cnic_no': cnicNo,
        'city_id': cityId,
        'area_id': areaId,
        'address': address,
      },
      files,
      token: token,
    );

    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to save customer.');
    }
  }

  Future<void> importCustomers(File file) async {
    final token = await SellerSessionManager.getToken();
    final response = await _network.postMultipartRequest(
      ApiEndpoints.sellerImportCustomers,
      const {},
      {'file': file},
      token: token,
    );

    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to import customers.');
    }
  }

  Future<String> downloadImportSample() {
    return SellerFileService.downloadAuthenticatedFile(
      endpoint: ApiEndpoints.sellerCustomersImportSample,
      fileName: 'atomshop_customer_import_sample.xlsx',
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

  String _withPage(String endpoint, int page) {
    final separator = endpoint.contains('?') ? '&' : '?';
    return '$endpoint${separator}page=$page';
  }
}
