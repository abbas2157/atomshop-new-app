import 'dart:io';

import 'package:atompro/core/auth/seller_session_manager.dart';
import 'package:atompro/core/network/api_endpoints.dart';
import 'package:atompro/core/network/network_manager.dart';
import 'package:atompro/core/network/network_provider.dart';
import 'package:atompro/features/seller/profile/model/seller_profile_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sellerProfileRepositoryProvider = Provider<SellerProfileRepository>((
  ref,
) {
  return SellerProfileRepository(ref.watch(networkManagerProvider));
});

class SellerProfileRepository {
  final NetworkManager _network;

  SellerProfileRepository(this._network);

  Future<SellerProfileBundle> getProfileBundle() async {
    final results = await Future.wait([
      getProfile(),
      getSellerInfo(),
      getBusinessInfo(),
    ]);

    return SellerProfileBundle(
      profile: results[0] as SellerProfileUser,
      sellerInfo: results[1] as SellerProfileSeller,
      businessInfo: results[2] as SellerBusinessInfo,
    );
  }

  Future<SellerProfileUser> getProfile() async {
    final response = await _get(ApiEndpoints.sellerProfile);
    return SellerProfileUser.fromResponse(Map<String, dynamic>.from(response));
  }

  Future<SellerProfileSeller> getSellerInfo() async {
    final response = await _get(ApiEndpoints.sellerInfo);
    return SellerProfileSeller.fromResponse(
      Map<String, dynamic>.from(response),
    );
  }

  Future<SellerBusinessInfo> getBusinessInfo() async {
    final response = await _get(ApiEndpoints.sellerBusinessInfo);
    return SellerBusinessInfo.fromResponse(Map<String, dynamic>.from(response));
  }

  Future<void> updateUserInfo({
    required String name,
    required String email,
    required String phone,
  }) async {
    await _post(
      ApiEndpoints.sellerProfileUpdate,
      {'name': name, 'email': email, 'phone': phone},
      fallbackMessage: 'Failed to update profile.',
    );
  }

  Future<void> updateSellerInfo({
    required String name,
    required String cnicNumber,
    required String website,
    required String feeChargeType,
  }) async {
    await _post(ApiEndpoints.sellerInfo, {
      'name': name,
      'cnic_number': cnicNumber,
      'website': website,
      'fee_charge_type': feeChargeType,
    }, fallbackMessage: 'Failed to update seller info.');
  }

  Future<void> updateBusinessInfo({
    required String businessName,
    required String investmentCapacity,
    required String previousExperience,
    required String cityId,
    required String address,
    required List<int> areaIds,
  }) async {
    await _post(
      ApiEndpoints.sellerBusinessInfo,
      {
        'business_name': businessName,
        'investment_capacity': investmentCapacity,
        'previous_experience': previousExperience,
        'city_id': cityId,
        'address': address,
        'area_id': areaIds,
      },
      fallbackMessage: 'Failed to update business info.',
    );
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    await _post(
      ApiEndpoints.sellerChangePassword,
      {
        'current_password': currentPassword,
        'new_password': newPassword,
        'confirm_new_password': confirmNewPassword,
      },
      fallbackMessage: 'Failed to change password.',
    );
  }

  Future<void> updateProfilePicture(File image) async {
    final token = await SellerSessionManager.getToken();
    final response = await _network.postMultipartRequest(
      ApiEndpoints.sellerProfilePictureUpdate,
      const {},
      {'picture': image},
      token: token,
    );

    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to update picture.');
    }
  }

  Future<dynamic> _get(String endpoint) async {
    final token = await SellerSessionManager.getToken();
    final response = await _network.getRequest(endpoint, token: token);
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to load profile.');
    }
    return response;
  }

  Future<void> _post(
    String endpoint,
    Map<String, dynamic> data, {
    required String fallbackMessage,
  }) async {
    final token = await SellerSessionManager.getToken();
    final response = await _network.postRequest(endpoint, data, token: token);
    if (response['success'] != true) {
      throw Exception(response['message'] ?? fallbackMessage);
    }
  }
}
