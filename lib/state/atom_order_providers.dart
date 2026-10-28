import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/session_manager.dart';
import '../data/atom_order.dart';
import 'atom_cache.dart';

/// Cities and areas for the delivery address. Cities rarely change; an
/// area list is kept briefly per city.
final citiesProvider = FutureProvider.autoDispose<List<AtomPlace>>((ref) {
  ref.cacheFor(AtomCacheTime.catalogue);
  return ref.watch(atomOrderApiProvider).cities();
});

final areasProvider = FutureProvider.autoDispose.family<List<AtomPlace>, int>((ref, cityId) {
  ref.cacheFor(AtomCacheTime.catalogue);
  return ref.watch(atomOrderApiProvider).areas(cityId);
});

/// What a signed-in customer already gave us, to fill the order form.
/// For guests, only the delivery area they picked.
class OrderPrefill {
  const OrderPrefill({this.name = '', this.phone = '', this.email = '', this.cityId, this.areaId, this.address = ''});

  final String name;
  final String phone;
  final String email;
  final int? cityId;
  final int? areaId;
  final String address;
}

final orderPrefillProvider = FutureProvider.autoDispose<OrderPrefill>((ref) async {
  final cityId = int.tryParse(await SessionManager.getCityId() ?? '');
  final areaId = int.tryParse(await SessionManager.getAreaId() ?? '');
  // A guest may have picked a delivery area (account → Delivery area).
  if (!await SessionManager.isLoggedIn()) return OrderPrefill(cityId: cityId, areaId: areaId);
  final email = await SessionManager.getEmail() ?? '';
  return OrderPrefill(
    name: await SessionManager.getUserName() ?? '',
    phone: await SessionManager.getPhone() ?? '',
    // Accounts made without an email carry a placeholder on atomshop.pk.
    email: email.toLowerCase().endsWith('@atomshop.pk') ? '' : email,
    cityId: cityId,
    areaId: areaId,
    address: await SessionManager.getAddress() ?? '',
  );
});
