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

  /// Update user profile — all fields optional except user_id.
  /// Endpoint: PATCH /api/user/update  (replace with your real endpoint)
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

    // ⚠️  Replace ApiEndpoints.updateProfile with your real endpoint constant
    return await _network.postRequest(
      ApiEndpoints.updateProfile,
      body,
      token: token,
    );
  }
}
