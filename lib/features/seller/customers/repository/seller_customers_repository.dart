import 'dart:io';

import 'package:atompro/core/auth/seller_session_manager.dart';
import 'package:atompro/core/network/api_endpoints.dart';
import 'package:atompro/core/network/network_manager.dart';
import 'package:atompro/core/network/network_provider.dart';
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

  /// Public cities list (`GET /cities`). Reuses the {id, title} area model.
  Future<List<SellerCustomerArea>> getCities() async {
    final token = await SellerSessionManager.getToken();
    final response = await _network.getRequest(
      ApiEndpoints.cities,
      token: token,
    );
    final raw = response is Map
        ? (response['data'] ?? response['cities'] ?? response)
        : response;
    final list = raw is List
        ? raw
        : (raw is Map && raw['data'] is List ? raw['data'] as List : const []);
    return list
        .whereType<Map>()
        .map(
          (item) =>
              SellerCustomerArea.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);
  }

  /// Create a new customer (see Customer Store & Update API — Store).
  /// `bussiness` is the intentional stored value for the `work` field.
  Future<void> storeCustomer({
    required String name,
    required String fatherName,
    required String phone,
    String? email,
    required String cnicNo,
    required String status,
    required String cityId,
    required String areaId,
    required String address,
    String? residencePhone,
    String? officeAddress,
    String? officePhone,
    String? work,
    String? addressFound,
    String? house,
    String? customerPhysicalMeet,
    File? picture,
    File? idCardFrontSide,
    File? idCardBackSide,
    File? selfieWithCustomer,
  }) async {
    final data = <String, String>{
      'name': name,
      'father_name': fatherName,
      'phone': phone,
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      'cnic_no': cnicNo,
      'status': status,
      'city_id': cityId,
      'area_id': areaId,
      'address': address,
      if (_filled(residencePhone)) 'residence_phone': residencePhone!.trim(),
      if (_filled(officeAddress)) 'office_address': officeAddress!.trim(),
      if (_filled(officePhone)) 'office_phone': officePhone!.trim(),
      if (_filled(work)) 'work': work!,
      if (_filled(addressFound)) 'address_found': addressFound!,
      if (_filled(house)) 'house': house!,
      if (_filled(customerPhysicalMeet))
        'customer_physical_meet': customerPhysicalMeet!,
    };
    final files = <String, File>{
      if (picture != null) 'picture': picture,
      if (idCardFrontSide != null) 'id_card_front_side': idCardFrontSide,
      if (idCardBackSide != null) 'id_card_back_side': idCardBackSide,
      if (selfieWithCustomer != null)
        'selfie_with_customer': selfieWithCustomer,
    };

    await _post(
      ApiEndpoints.sellerStoreCustomer,
      data,
      files,
      fallback: 'Failed to save customer.',
    );
  }

  /// Update an existing customer. `name`, `email`, `phone` are read-only.
  /// When [verified] is false, send [notVerifiedReason] and omit doc fields.
  Future<void> updateCustomer({
    required String customerUuid,
    String? fatherName,
    String? cnicNo,
    required String status,
    required String cityId,
    required String areaId,
    required String address,
    String? residencePhone,
    String? officeAddress,
    String? officePhone,
    required bool verified,
    String? notVerifiedReason,
    String? work,
    String? addressFound,
    String? house,
    String? customerPhysicalMeet,
    File? picture,
    File? idCardFrontSide,
    File? idCardBackSide,
    File? selfieWithCustomer,
  }) async {
    final data = <String, String>{
      if (_filled(fatherName)) 'father_name': fatherName!.trim(),
      if (_filled(cnicNo)) 'cnic_no': cnicNo!.trim(),
      'status': status,
      'city_id': cityId,
      'area_id': areaId,
      'address': address,
      if (_filled(residencePhone)) 'residence_phone': residencePhone!.trim(),
      if (_filled(officeAddress)) 'office_address': officeAddress!.trim(),
      if (_filled(officePhone)) 'office_phone': officePhone!.trim(),
      'verified': verified ? '1' : '0',
      if (!verified && _filled(notVerifiedReason))
        'not_verified_reason': notVerifiedReason!.trim(),
      if (verified && _filled(work)) 'work': work!,
      if (verified && _filled(addressFound)) 'address_found': addressFound!,
      if (verified && _filled(house)) 'house': house!,
      if (verified && _filled(customerPhysicalMeet))
        'customer_physical_meet': customerPhysicalMeet!,
    };
    final files = <String, File>{
      if (picture != null) 'picture': picture,
      if (verified && idCardFrontSide != null)
        'id_card_front_side': idCardFrontSide,
      if (verified && idCardBackSide != null)
        'id_card_back_side': idCardBackSide,
      if (verified && selfieWithCustomer != null)
        'selfie_with_customer': selfieWithCustomer,
    };

    await _post(
      ApiEndpoints.sellerCustomerUpdate(customerUuid),
      data,
      files,
      fallback: 'Failed to update customer.',
    );
  }

  Future<void> _post(
    String endpoint,
    Map<String, String> data,
    Map<String, File> files, {
    required String fallback,
  }) async {
    final token = await SellerSessionManager.getToken();
    final response = files.isEmpty
        ? await _network.postRequest(endpoint, data, token: token)
        : await _network.postMultipartRequest(
            endpoint,
            data,
            files,
            token: token,
          );
    if (response['success'] != true) {
      throw Exception(response['message'] ?? fallback);
    }
  }

  bool _filled(String? v) => v != null && v.trim().isNotEmpty;

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
