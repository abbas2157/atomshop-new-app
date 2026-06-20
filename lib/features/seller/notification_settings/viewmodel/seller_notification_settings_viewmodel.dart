import 'package:atompro/features/seller/notification_settings/model/seller_notification_settings_model.dart';
import 'package:atompro/features/seller/notification_settings/repository/seller_notification_settings_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sellerNotificationSettingsProvider = NotifierProvider<
    SellerNotificationSettingsNotifier,
    AsyncValue<SellerNotificationSettings>>(SellerNotificationSettingsNotifier.new);

class SellerNotificationSettingsNotifier
    extends Notifier<AsyncValue<SellerNotificationSettings>> {
  @override
  AsyncValue<SellerNotificationSettings> build() {
    _load();
    return const AsyncValue.loading();
  }

  Future<void> refresh() => _load();

  Future<void> _load() async {
    state = const AsyncValue.loading();
    try {
      final settings = await ref
          .read(sellerNotificationSettingsRepositoryProvider)
          .getSettings();
      state = AsyncValue.data(settings);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  /// Optimistically toggles [type] to [enabled], confirms via API, then syncs
  /// server preferences. Reverts on failure and rethrows for the UI to snack.
  Future<void> toggle(String type, bool enabled) async {
    final prev = state;
    state = prev.whenData((s) => s.copyWithToggle(type, enabled));
    try {
      final prefs = await ref
          .read(sellerNotificationSettingsRepositoryProvider)
          .toggleSetting(type: type, enabled: enabled);
      state = state.whenData((s) => s.copyWithPreferences(prefs));
    } catch (e) {
      state = prev;
      rethrow;
    }
  }
}
