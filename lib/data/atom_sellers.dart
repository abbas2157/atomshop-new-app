import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/atom_format.dart';
import 'atom_http.dart';
import 'atom_models.dart';

/// Verified sellers on Atomshop (`api/app/sellers`, `api/app/sellers/top-rated`;
/// atomshop docs/trd/2026-10-29-app-sellers-api.md). Public, no token. Only
/// public card fields come back: never CNIC, email, phone or address.

int _int(Object? v, [int fallback = 0]) => AtomFormat.parseAmount(v) ?? fallback;
String _str(Object? v) => v == null ? '' : v.toString();
Map<String, dynamic> _map(Object? v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

/// One page of a paginated list: `{current_page, last_page, per_page, total, has_more}`.
class AtomPagination {
  const AtomPagination({required this.currentPage, required this.lastPage, required this.perPage, required this.total, required this.hasMore});

  /// A single page holding [count] items (an answer without pagination).
  const AtomPagination.single(int count) : this(currentPage: 1, lastPage: 1, perPage: count, total: count, hasMore: false);

  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final bool hasMore;

  /// The page to ask for next, or null on the last page.
  int? get nextPage => hasMore ? currentPage + 1 : null;

  factory AtomPagination.fromJson(Object? v, {int fallbackCount = 0}) {
    final j = _map(v);
    if (j.isEmpty) return AtomPagination.single(fallbackCount);
    final current = _int(j['current_page'], 1);
    final last = _int(j['last_page'], current);
    return AtomPagination(
      currentPage: current,
      lastPage: last,
      perPage: _int(j['per_page'], fallbackCount),
      total: _int(j['total'], fallbackCount),
      hasMore: j['has_more'] is bool ? j['has_more'] as bool : current < last,
    );
  }
}

class SellerPlace {
  const SellerPlace(this.id, this.title);

  final int id;
  final String title;

  static SellerPlace? fromJson(Object? v) {
    final j = _map(v);
    final id = AtomFormat.parseAmount(j['id']);
    return id == null ? null : SellerPlace(id, _str(j['title']));
  }
}

class Seller {
  const Seller({
    required this.id,
    required this.name,
    required this.owner,
    required this.businessType,
    required this.picture,
    required this.initial,
    required this.city,
    required this.area,
    required this.location,
    required this.topRated,
    required this.atomshopShips,
    required this.ordersDone,
    required this.memberSince,
    required this.memberSinceLabel,
    required this.whatsappUrl,
  });

  final int id;

  /// Business name.
  final String name;
  final String owner;

  /// "Sole Proprietor"…
  final String businessType;

  /// Empty when the seller has no photo: show [initial] instead.
  final String picture;
  final String initial;
  final SellerPlace? city;
  final SellerPlace? area;

  /// "Johar Town, Lahore", or empty.
  final String location;
  final bool topRated;

  /// Atomshop delivers this seller's orders.
  final bool atomshopShips;
  final int ordersDone;

  /// "2026-05".
  final String memberSince;

  /// "May 2026".
  final String memberSinceLabel;

  /// Empty when the seller has no WhatsApp: hide "Chat with seller".
  final String whatsappUrl;

  factory Seller.fromJson(Map<String, dynamic> j) {
    final name = _str(j['name']).trim();
    final sent = _str(j['initial']).trim();
    return Seller(
      id: _int(j['id']),
      name: name,
      owner: _str(j['owner']),
      businessType: _str(j['business_type']),
      picture: _str(j['picture']),
      initial: sent.isNotEmpty ? sent : (name.isEmpty ? '?' : name.substring(0, 1).toUpperCase()),
      city: SellerPlace.fromJson(j['city']),
      area: SellerPlace.fromJson(j['area']),
      location: _str(j['location']),
      topRated: j['top_rated'] == true,
      atomshopShips: j['atomshop_ships'] == true,
      ordersDone: _int(j['orders_done']),
      memberSince: _str(j['member_since']),
      memberSinceLabel: _str(j['member_since_label']),
      whatsappUrl: _str(j['whatsapp_url']),
    );
  }
}

class SellersPage {
  const SellersPage(this.sellers, this.pagination);

  final List<Seller> sellers;
  final AtomPagination pagination;

  factory SellersPage.fromJson(Object? data) {
    final j = _map(data);
    final sellers = atomList(j['sellers']).map(Seller.fromJson).toList(growable: false);
    return SellersPage(sellers, AtomPagination.fromJson(j['pagination'], fallbackCount: sellers.length));
  }
}

/// How the directory is ordered.
enum SellerSort {
  top('top', 'Top rated first'),
  orders('orders', 'Most orders'),
  newest('newest', 'Newest');

  const SellerSort(this.apiName, this.label);

  final String apiName;
  final String label;
}

class AtomSellersApi {
  const AtomSellersApi(this._http);

  final AtomHttp _http;

  Future<List<Seller>> topRated({int limit = 6}) async =>
      atomList(await _http.get('app/sellers/top-rated', query: {'limit': limit})).map(Seller.fromJson).toList(growable: false);

  Future<SellersPage> sellers({
    int? cityId,
    int? areaId,
    String q = '',
    bool topRated = false,
    SellerSort sort = SellerSort.top,
    int page = 1,
    int perPage = 15,
  }) async =>
      SellersPage.fromJson(await _http.get('app/sellers', query: {
        'city_id': ?cityId,
        'area_id': ?areaId,
        if (q.trim().isNotEmpty) 'q': q.trim(),
        if (topRated) 'top_rated': 1,
        'sort': sort.apiName,
        'page': page,
        'per_page': perPage,
      }));
}

final atomSellersApiProvider = Provider<AtomSellersApi>((ref) => AtomSellersApi(ref.watch(atomHttpProvider)));
