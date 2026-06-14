import 'package:atompro/features/customer/notifications/model/app_notification_model.dart';
import 'package:atompro/features/seller/notifications/repository/seller_notifications_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sellerNotificationsProvider =
    NotifierProvider<SellerNotificationsNotifier, NotificationsState>(
  SellerNotificationsNotifier.new,
);

class SellerNotificationsNotifier extends Notifier<NotificationsState> {
  @override
  NotificationsState build() {
    Future(_initCount);
    return const NotificationsState();
  }

  SellerNotificationsRepository get _repo =>
      ref.read(sellerNotificationsRepositoryProvider);

  Future<void> _initCount() async {
    try {
      final count = await _repo.fetchUnreadCount();
      state = state.copyWith(unreadCount: count, initialized: true);
    } catch (_) {
      state = state.copyWith(initialized: true);
    }
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repo.fetchPage(1);
      state = state.copyWith(
        items: result.items,
        unreadCount: result.unreadCount,
        currentPage: 1,
        lastPage: result.lastPage,
        isLoading: false,
        initialized: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final result = await _repo.fetchPage(state.currentPage + 1);
      state = state.copyWith(
        items: [...state.items, ...result.items],
        currentPage: state.currentPage + 1,
        lastPage: result.lastPage,
        isLoadingMore: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> markRead(int id) async {
    final idx = state.items.indexWhere((n) => n.id == id);
    if (idx != -1 && !state.items[idx].isRead) {
      final updated = List<AppNotification>.from(state.items);
      updated[idx] = updated[idx].copyWith(
        isRead: true,
        readAt: DateTime.now().toIso8601String(),
      );
      state = state.copyWith(
        items: updated,
        unreadCount: (state.unreadCount - 1).clamp(0, 9999),
      );
    }
    try {
      await _repo.markRead(id);
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    state = state.copyWith(
      items: state.items.map((n) => n.copyWith(isRead: true)).toList(),
      unreadCount: 0,
    );
    try {
      await _repo.markAllRead();
    } catch (_) {}
  }

  Future<void> refreshCount() async {
    try {
      final count = await _repo.fetchUnreadCount();
      state = state.copyWith(unreadCount: count);
    } catch (_) {}
  }
}
