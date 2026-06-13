import 'package:atompro/core/auth/seller_session_manager.dart';
import 'package:atompro/core/network/api_endpoints.dart';
import 'package:atompro/core/network/network_manager.dart';
import 'package:atompro/core/network/network_provider.dart';
import 'package:atompro/features/customer/notifications/model/app_notification_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sellerNotificationsRepositoryProvider =
    Provider<SellerNotificationsRepository>((ref) {
  return SellerNotificationsRepository(ref.watch(networkManagerProvider));
});

class SellerNotificationsRepository {
  final NetworkManager _network;

  SellerNotificationsRepository(this._network);

  Future<({List<AppNotification> items, int unreadCount, int lastPage})>
      fetchPage(int page) async {
    final token = await SellerSessionManager.getToken();
    final response = await _network.getRequest(
      '${ApiEndpoints.sellerNotifications}?page=$page',
      token: token,
    );
    final d = response['data'] as Map;
    final paginator = d['notifications'] as Map;
    return (
      items: (paginator['data'] as List)
          .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      unreadCount: (d['unread_count'] as num).toInt(),
      lastPage: (paginator['last_page'] as num).toInt(),
    );
  }

  Future<int> fetchUnreadCount() async {
    final token = await SellerSessionManager.getToken();
    final response = await _network.getRequest(
      ApiEndpoints.sellerNotificationsCount,
      token: token,
    );
    return (response['data']['count'] as num).toInt();
  }

  Future<void> markRead(int id) async {
    final token = await SellerSessionManager.getToken();
    await _network.postRequest(
      ApiEndpoints.sellerNotificationRead(id),
      {},
      token: token,
    );
  }

  Future<void> markAllRead() async {
    final token = await SellerSessionManager.getToken();
    await _network.postRequest(
      ApiEndpoints.sellerNotificationsReadAll,
      {},
      token: token,
    );
  }
}
