import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'atom_session.dart';

/// Where the customer wants delivery: picked on "Choose your delivery area"
/// (guests) or from the account (signed in). Ids go with orders; titles are
/// what Home shows ("Delivering to Johar Town, Lahore").
class DeliveryArea {
  const DeliveryArea({required this.cityId, required this.cityTitle, required this.areaId, required this.areaTitle});

  final int cityId;
  final String cityTitle;
  final int areaId;
  final String areaTitle;

  String get label => [areaTitle, cityTitle].where((s) => s.isNotEmpty).join(', ');
}

/// Same secure-storage keys as the session (`city_id`, `area_id`), so the
/// order form and the account read one value; titles sit next to them.
abstract final class DeliveryAreaKeys {
  static const cityId = 'city_id';
  static const areaId = 'area_id';
  static const cityTitle = 'city_title';
  static const areaTitle = 'area_title';
}

final deliveryAreaProvider = AsyncNotifierProvider<DeliveryAreaNotifier, DeliveryArea?>(DeliveryAreaNotifier.new);

class DeliveryAreaNotifier extends AsyncNotifier<DeliveryArea?> {
  static const _storage = FlutterSecureStorage();

  @override
  Future<DeliveryArea?> build() async {
    // Signing in or out changes the saved area (the account's, or none).
    ref.watch(atomSignedInProvider);
    final cityId = int.tryParse(await _storage.read(key: DeliveryAreaKeys.cityId) ?? '');
    final areaId = int.tryParse(await _storage.read(key: DeliveryAreaKeys.areaId) ?? '');
    if (cityId == null || areaId == null) return null;
    return DeliveryArea(
      cityId: cityId,
      cityTitle: await _storage.read(key: DeliveryAreaKeys.cityTitle) ?? '',
      areaId: areaId,
      areaTitle: await _storage.read(key: DeliveryAreaKeys.areaTitle) ?? '',
    );
  }

  Future<void> save(DeliveryArea area) async {
    await _storage.write(key: DeliveryAreaKeys.cityId, value: '${area.cityId}');
    await _storage.write(key: DeliveryAreaKeys.areaId, value: '${area.areaId}');
    await _storage.write(key: DeliveryAreaKeys.cityTitle, value: area.cityTitle);
    await _storage.write(key: DeliveryAreaKeys.areaTitle, value: area.areaTitle);
    state = AsyncData(area);
  }
}
