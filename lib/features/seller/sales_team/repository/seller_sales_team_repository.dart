import 'package:atompro/core/auth/seller_session_manager.dart';
import 'package:atompro/core/network/api_endpoints.dart';
import 'package:atompro/core/network/network_manager.dart';
import 'package:atompro/core/network/network_provider.dart';
import 'package:atompro/features/seller/sales_team/model/seller_sales_team_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sellerSalesTeamRepositoryProvider = Provider<SellerSalesTeamRepository>((
  ref,
) {
  return SellerSalesTeamRepository(ref.watch(networkManagerProvider));
});

class SellerSalesTeamRepository {
  final NetworkManager _network;

  SellerSalesTeamRepository(this._network);

  /// [status] 1/0, [memberType] sale/recovery, [query] → ?q=.
  Future<SellerSalesTeamResponse> getMembers({
    int page = 1,
    int? status,
    String? memberType,
    String? query,
  }) async {
    final params = <String, String>{'page': '$page'};
    if (status != null) params['status'] = '$status';
    if (memberType != null && memberType.isNotEmpty) {
      params['member_type'] = memberType;
    }
    if (query != null && query.trim().isNotEmpty) params['q'] = query.trim();
    final qs = Uri(queryParameters: params).query;
    final response = await _get('${ApiEndpoints.sellerSalesTeam}?$qs');
    return SellerSalesTeamResponse.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  /// [salesTeamUuid] = `salesTeam.uuid` (NOT the user uuid).
  Future<SellerSalesTeamEditData> getMemberEdit(String salesTeamUuid) async {
    final response = await _get(
      ApiEndpoints.sellerSalesTeamEdit(salesTeamUuid),
    );
    return SellerSalesTeamEditData.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  /// [userUuid] = `salesTeam.user.uuid`.
  Future<SellerSalesTeamPerformance> getPerformance(
    String userUuid, {
    int page = 1,
  }) async {
    final response = await _get(
      '${ApiEndpoints.sellerSalesTeamPerformance(userUuid)}?page=$page',
    );
    return SellerSalesTeamPerformance.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  Future<void> storeMember({
    required String name,
    required String email,
    required String phone,
    required bool active,
    required String memberType,
    required String memberRole,
    required String cityId,
    required String areaId,
    String? address,
    bool amosAssistantManager = false,
  }) async {
    final response = await _post(ApiEndpoints.sellerStoreSalesTeamMember, {
      'name': name,
      'email': email,
      'phone': phone,
      'status': active ? '1' : '0',
      'member_type': memberType,
      'member_role': memberRole,
      'city_id': cityId,
      'area_id': areaId,
      if (address != null && address.trim().isNotEmpty) 'address': address.trim(),
      if (amosAssistantManager) 'amos_assistant_manager': '1',
    });

    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to add team member.');
    }
  }

  /// [userUuid] = `salesTeam.user.uuid`. `email`/`phone` are locked (not sent).
  Future<void> updateMember({
    required String userUuid,
    required String name,
    required bool active,
    required String memberType,
    required String memberRole,
    required String cityId,
    required String areaId,
    String? address,
    bool amosAssistantManager = false,
  }) async {
    final response =
        await _post(ApiEndpoints.sellerSalesTeamUpdate(userUuid), {
          'name': name,
          'status': active ? '1' : '0',
          'member_type': memberType,
          'member_role': memberRole,
          'city_id': cityId,
          'area_id': areaId,
          if (address != null && address.trim().isNotEmpty)
            'address': address.trim(),
          if (amosAssistantManager) 'amos_assistant_manager': '1',
        });

    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to update team member.');
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
