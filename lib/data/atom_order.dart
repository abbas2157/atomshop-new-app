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

/// One month of the AtomPay plan on the Key Fact Statement.
class KeyFactsInstalment {
  const KeyFactsInstalment({required this.number, required this.due, required this.amount});

  final int number;

  /// "1 month after delivery": the dates are set on the day of delivery.
  final String due;
  final int amount;

  factory KeyFactsInstalment.fromJson(Map<String, dynamic> j) =>
      KeyFactsInstalment(number: _int(j['number']), due: _str(j['due']), amount: _int(j['amount']));
}

/// The AtomPay Key Fact Statement for one product and storage choice, from
/// GET api/app/atompay/kfs-preview (server doc
/// docs/customer-app-atompay-kfs.md). The customer reads it and ticks the
/// box before an AtomPay order; the order then sends [amountFinanced] so a
/// price change since is caught.
class KeyFacts {
  const KeyFacts({
    required this.version,
    required this.product,
    required this.sellerName,
    required this.sellerAddress,
    required this.cashPrice,
    required this.amountFinanced,
    required this.advance,
    required this.markupPercent,
    required this.processingFeePercent,
    required this.processingFee,
    required this.aprPercent,
    required this.months,
    required this.instalments,
    required this.dueDates,
    required this.totalRepayable,
    required this.deliveryCharges,
    required this.latePayment,
    required this.earlySettlement,
    required this.complaints,
  });

  final String version;
  final String product;
  final String sellerName;
  final String sellerAddress;
  final int cashPrice;
  final int amountFinanced;
  final int advance;
  final num markupPercent;
  final num processingFeePercent;
  final int processingFee;
  final num aprPercent;
  final int months;
  final List<KeyFactsInstalment> instalments;
  final String dueDates;
  final int totalRepayable;
  final String deliveryCharges;
  final String latePayment;
  final String earlySettlement;
  final String complaints;

  factory KeyFacts.fromJson(Map<String, dynamic> j) {
    final seller = j['seller'] is Map ? Map<String, dynamic>.from(j['seller'] as Map) : const <String, dynamic>{};
    num pct(Object? v) => v is num ? v : (num.tryParse('$v') ?? 0);
    return KeyFacts(
      version: _str(j['version']),
      product: _str(j['product']),
      sellerName: _str(seller['name']).isEmpty ? 'Atomshop' : _str(seller['name']),
      sellerAddress: _str(seller['address']),
      cashPrice: _int(j['cash_price']),
      amountFinanced: _int(j['amount_financed']),
      advance: _int(j['advance']),
      markupPercent: pct(j['markup_percent']),
      processingFeePercent: pct(j['processing_fee_percent']),
      processingFee: _int(j['processing_fee']),
      aprPercent: pct(j['apr_percent']),
      months: _int(j['months']),
      instalments: atomList(j['instalments']).map(KeyFactsInstalment.fromJson).toList(growable: false),
      dueDates: _str(j['due_dates']),
      totalRepayable: _int(j['total_repayable']),
      deliveryCharges: _str(j['delivery_charges']),
      latePayment: _str(j['late_payment']),
      earlySettlement: _str(j['early_settlement']),
      complaints: _str(j['complaints']),
    );
  }

  /// A percentage as the statement shows it: `0%`, `3%`, `18.5%`.
  static String percent(num value) {
    final fixed = value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
    return '$fixed%';
  }

  /// What an AtomPay order adds once the customer has ticked the box.
  Map<String, dynamic> get acceptance => {'accept_kfs': true, 'kfs_amount': amountFinanced};
}

/// True when the server refused an AtomPay order because the price moved
/// since the statement was shown: show the new statement and ask again.
bool isKeyFactsPriceChange(Object error) =>
    error is AtomApiException && error.statusCode == 422 && error.message.contains('Key Fact Statement');

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

  /// The AtomPay Key Fact Statement for [productId] and the storage choice,
  /// priced exactly as the order will be. Public: no token needed.
  Future<KeyFacts> keyFacts(int productId, {int? memoryId}) async {
    final res = await _network.getRequest(
      'app/atompay/kfs-preview?product_id=$productId${memoryId != null ? '&memory_id=$memoryId' : ''}',
    );
    final data = res is Map ? res['data'] : null;
    if (data is! Map) throw const AtomApiException('The Key Fact Statement could not be loaded. Please try again.');
    return KeyFacts.fromJson(Map<String, dynamic>.from(data));
  }

  /// Places the order. A signed-in customer's token makes it their order;
  /// a guest's order goes on the customer account for the phone. Throws with
  /// the server's message when it refuses (sold out, plan not offered).
  /// [requestId] stays the same for every retry of one order form, so the
  /// server returns the first order for a repeat instead of placing another.
  /// [acceptedKeyFacts] is the statement the customer ticked, for AtomPay.
  Future<OrderReceipt> place(ProductOrderChoice choice, OrderContact contact, {String requestId = '', KeyFacts? acceptedKeyFacts}) async {
    final quote = choice.quote;
    final res = await _network.postRequest('app/orders', {
      if (requestId.isNotEmpty) 'request_id': requestId,
      if (choice.mode == PayMode.atompay && acceptedKeyFacts != null) ...acceptedKeyFacts.acceptance,
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
