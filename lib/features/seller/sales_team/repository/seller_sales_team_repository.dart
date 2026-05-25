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

  Future<SellerSalesTeamResponse> getMembers({int page = 1}) async {
    final response = await _get('${ApiEndpoints.sellerSalesTeam}?page=$page');
    return SellerSalesTeamResponse.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  Future<SellerSalesTeamEditData> getMemberEdit(String memberUuid) async {
    final response = await _get(ApiEndpoints.sellerSalesTeamEdit(memberUuid));
    return SellerSalesTeamEditData.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  Future<SellerSalesTeamPerformance> getPerformance(String memberUuid) async {
    final response = await _get(
      ApiEndpoints.sellerSalesTeamPerformance(memberUuid),
    );
    return SellerSalesTeamPerformance.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  Future<void> storeMember({
    required String name,
    required String email,
    required String phone,
    required String memberType,
    required String cityId,
    required String areaId,
    required bool active,
  }) async {
    final response = await _post(ApiEndpoints.sellerStoreSalesTeamMember, {
      'name': name,
      'email': email,
      'phone': phone,
      'member_type': memberType,
      'city_id': cityId,
      'area_id': areaId,
      'status': active ? '1' : '0',
    });

    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to add team member.');
    }
  }

  Future<void> updateMember({
    required String memberUuid,
    required String name,
    required String phone,
    required String memberType,
    required String cityId,
    required String areaId,
    required bool active,
  }) async {
    final response =
        await _post(ApiEndpoints.sellerSalesTeamUpdate(memberUuid), {
          'name': name,
          'phone': phone,
          'member_type': memberType,
          'city_id': cityId,
          'area_id': areaId,
          'status': active ? '1' : '0',
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
