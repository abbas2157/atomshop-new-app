import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/session_manager.dart';
import '../core/network/network_manager.dart';
import '../core/network/network_provider.dart';
import '../utils/atom_format.dart';
import 'atom_http.dart';
import 'atom_models.dart';
import 'atom_offline_store.dart';
import 'atom_product_detail.dart';

/// Ordering a listed product: POST api/app/orders (server TRD
/// docs/trd/2026-10-28-app-product-order.md). The server prices the order
/// with the storefront's own checkout code; the app sends only choices.

int _int(Object? v, [int fallback = 0]) => AtomFormat.parseAmount(v) ?? fallback;
String _str(Object? v) => v?.toString() ?? '';

/// A city or an area for the delivery address.
class AtomPlace {
  const AtomPlace({required this.id, required this.title});

  final int id;
  final String title;

  factory AtomPlace.fromJson(Map<String, dynamic> j) => AtomPlace(id: _int(j['id']), title: _str(j['title']));
}

/// Delivery details typed on the order screen.
class OrderContact {
  const OrderContact({
    required this.fullName,
    required this.phone,
    required this.email,
    required this.cityId,
    required this.areaId,
    required this.address,
  });

  final String fullName;
  final String phone;
  final String email;
  final int cityId;
  final int areaId;
  final String address;
}

/// What the server saved, for the "Order placed" screen.
class OrderReceipt {
  const OrderReceipt({
    required this.uuid,
    required this.id,
    required this.mode,
    required this.product,
    required this.storage,
    required this.colour,
    required this.months,
    required this.advance,
    required this.monthly,
    required this.total,
    required this.area,
    required this.atompayUrl,
    required this.phone,
  });

  final String uuid;
  final int id;
  final PayMode mode;
  final String product;
  final String storage;
  final String colour;
  final int months;
  final int advance;
  final int? monthly;
  final int total;
  final String area;

  /// Set for AtomPay orders: where the customer completes their profile.
  final String atompayUrl;
  final String phone;

  factory OrderReceipt.fromJson(Map<String, dynamic> j) => OrderReceipt(
        uuid: _str(j['order_uuid']),
        id: _int(j['order_id']),
        mode: PayMode.values.firstWhere((m) => m.apiName == j['mode'], orElse: () => PayMode.installment),
        product: _str(j['product']),
        storage: _str(j['storage']),
        colour: _str(j['colour']),
        months: _int(j['months']),
        advance: _int(j['advance']),
        monthly: j['monthly'] == null ? null : _int(j['monthly']),
        total: _int(j['total']),
        area: _str(j['area']),
        atompayUrl: _str(j['atompay_url']),
        phone: _str(j['phone']),
      );
}

extension PayModeApi on PayMode {
  String get apiName => switch (this) {
        PayMode.installment => 'installment',
        PayMode.atompay => 'atompay',
        PayMode.cash => 'cash',
      };
}

class AtomOrderApi {
  const AtomOrderApi(this._network);

  final NetworkManager _network;

  /// Cities and areas are saved on the phone each time they load, and the
  /// saved list is used when offline, so the forms can be filled anywhere.
  Future<List<AtomPlace>> cities() => _places('cities', 'cities');

  Future<List<AtomPlace>> areas(int cityId) => _places('areas/$cityId', 'areas_$cityId');

  Future<List<AtomPlace>> _places(String endpoint, String key) async {
    try {
      final res = await _network.getRequest(endpoint);
      final rows = atomList(res is Map ? res['data'] : null);
      final places = _parse(rows);
      await AtomOfflineStore.write(key, [for (final p in places) {'id': p.id, 'title': p.title}]);
      return places;
    } on AtomApiException catch (e) {
      final saved = e.isOffline ? await AtomOfflineStore.read(key) : null;
      if (saved is! List) rethrow;
      return _parse(atomList(saved));
    }
  }

  List<AtomPlace> _parse(List<Map<String, dynamic>> rows) => rows.map(AtomPlace.fromJson).where((p) => p.id > 0).toList(growable: false);

  static const _placesSavedKey = 'places_saved_at';

  /// Saves every city's areas on the phone, one city at a time, at most
  /// once a week ([first] goes first: the customer's own city). Stops
  /// quietly when the connection drops; the next call carries on.
  Future<void> savePlacesForOffline({int? first}) async {
    final at = DateTime.tryParse('${await AtomOfflineStore.read(_placesSavedKey)}');
    if (at != null && DateTime.now().difference(at) < const Duration(days: 7)) return;
    try {
      final ids = [for (final c in await cities()) c.id];
      if (first != null && ids.remove(first)) ids.insert(0, first);
      for (final id in ids) {
        await areas(id);
      }
      await AtomOfflineStore.write(_placesSavedKey, DateTime.now().toIso8601String());
    } on AtomApiException {
      // Offline or the server is busy: try again later.
    }
  }

  /// Places the order. A signed-in customer's token makes it their order;
  /// a guest's order goes on the customer account for the phone. Throws with
  /// the server's message when it refuses (sold out, plan not offered).
  /// [requestId] stays the same for every retry of one order form, so the
  /// server can ignore a repeat (backend prompt: idempotent orders).
  Future<OrderReceipt> place(ProductOrderChoice choice, OrderContact contact, {String requestId = ''}) async {
    final quote = choice.quote;
    final res = await _network.postRequest('app/orders', {
      if (requestId.isNotEmpty) 'request_id': requestId,
      'product_id': choice.product.id,
      'mode': choice.mode.apiName,
      if (choice.mode == PayMode.installment && quote != null) ...{'months': quote.months, 'advance_percent': quote.advancePercent},
      if (choice.storage != null) 'memory_id': choice.storage!.id,
      if (choice.colour != null) 'color_id': choice.colour!.id,
      'full_name': contact.fullName,
      'phone': contact.phone,
      if (contact.email.isNotEmpty) 'email': contact.email,
      'city_id': contact.cityId,
      'area_id': contact.areaId,
      'address': contact.address,
    }, token: await SessionManager.getToken());
    final data = res is Map ? res['data'] : null;
    if (data is! Map) throw Exception('Your order could not be placed. Please try again.');
    return OrderReceipt.fromJson(Map<String, dynamic>.from(data));
  }
}

final atomOrderApiProvider = Provider<AtomOrderApi>((ref) => AtomOrderApi(ref.watch(networkManagerProvider)));

/// The order form's error sentence (same wording as everywhere else).
String atomErrorMessage(Object error) => atomMessage(error);
