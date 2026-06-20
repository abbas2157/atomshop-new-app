import 'package:atompro/core/auth/seller_session_manager.dart';
import 'package:atompro/core/network/api_endpoints.dart';
import 'package:atompro/core/network/network_manager.dart';
import 'package:atompro/core/network/network_provider.dart';
import 'package:atompro/features/seller/notification_settings/model/seller_notification_settings_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sellerNotificationSettingsRepositoryProvider =
    Provider<SellerNotificationSettingsRepository>((ref) {
      return SellerNotificationSettingsRepository(ref.watch(networkManagerProvider));
    });

class SellerNotificationSettingsRepository {
  final NetworkManager _network;

  SellerNotificationSettingsRepository(this._network);

  Future<SellerNotificationSettings> getSettings() async {
    final token = await SellerSessionManager.getToken();
    final response = await _network.getRequest(
      ApiEndpoints.sellerNotificationSettings,
      token: token,
    );
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to load notification settings.');
    }
    return SellerNotificationSettings.fromResponse(Map<String, dynamic>.from(response));
  }

  Future<Map<String, bool>> toggleSetting({
    required String type,
    required bool enabled,
  }) async {
    final token = await SellerSessionManager.getToken();
    final response = await _network.postRequest(
      ApiEndpoints.sellerNotificationSettingsToggle,
      {'type': type, 'enabled': enabled},
      token: token,
    );
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to update notification preference.');
    }
    final data = response['data'] is Map
        ? Map<String, dynamic>.from(response['data'])
        : <String, dynamic>{};
    final prefsRaw = data['preferences'] is Map
        ? Map<String, dynamic>.from(data['preferences'])
        : <String, dynamic>{};
    return prefsRaw.map((k, v) => MapEntry(k, v == true));
  }
}
