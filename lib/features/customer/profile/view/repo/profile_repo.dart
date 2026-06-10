import 'dart:io';

import 'package:atompro/core/auth/session_manager.dart';
import 'package:atompro/core/network/api_endpoints.dart';
import 'package:atompro/core/network/network_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_repo.g.dart';

@riverpod
ProfileRepository profileRepository(Ref ref) {
  return ProfileRepository(NetworkManager.create());
}

class ProfileRepository {
  final NetworkManager _network;
  ProfileRepository(this._network);

  Future<Map<String, dynamic>> updateProfile({
    required String userUuid,
    String? name,
    String? phone,
    String? email,
    String? address,
    int? cityId,
    int? areaId,
  }) async {
    final body = <String, dynamic>{'user_id': userUuid};
    if (name != null) body['name'] = name;
    if (phone != null) body['phone'] = phone;
    if (email != null) body['email'] = email;
    if (address != null) body['address'] = address;
    if (cityId != null) body['city_id'] = cityId;
    if (areaId != null) body['area_id'] = areaId;
    final token = await SessionManager.getToken();
    return await _network.postRequest(
      ApiEndpoints.updateProfile,
      body,
      token: token,
    );
  }

  /// Fetch current profile picture URL. Returns null on error or no picture.
  Future<String?> getProfilePicture(String uuid) async {
    try {
      final token = await SessionManager.getToken();
      final response = await _network.getRequest(
        ApiEndpoints.customerProfile(uuid),
        token: token,
      );
      if (response['success'] == true) {
        final data = response['data'] is Map
            ? Map<String, dynamic>.from(response['data'])
            : <String, dynamic>{};
        final customer = data['customer'] is Map
            ? Map<String, dynamic>.from(data['customer'])
            : <String, dynamic>{};
        final url = customer['picture']?.toString().trim();
        if (url == null || url.isEmpty || url == 'null') return null;
        return url;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Upload a new profile picture. Returns the full picture URL on success.
  Future<String> uploadProfilePicture({
    required String userUuid,
    required File imageFile,
  }) async {
    final token = await SessionManager.getToken();
    final response = await _network.postMultipartRequest(
      ApiEndpoints.customerProfileUpload,
      {'user_id': userUuid},
      {'profile_image': imageFile},
      token: token,
    );
    if (response['success'] == true) {
      final data = response['data'] is Map
          ? Map<String, dynamic>.from(response['data'])
          : <String, dynamic>{};
      return data['picture_url']?.toString() ?? '';
    }
    throw Exception(response['message'] ?? 'Failed to upload picture.');
  }
}
