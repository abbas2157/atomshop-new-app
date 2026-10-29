import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/network_manager.dart';
import '../core/network/network_provider.dart';
import 'atom_models.dart';

/// The shop: `GET api/products` with filters and pages (server TRD
/// docs/trd/2026-10-29-app-shop-api.md). Only Brand Partner products.
///
/// The server before that change answered with a flat list and no pages;
/// that answer is still read (one page, no filter lists) so the app works on
/// both sides of the deploy.

int _int(Object? v, [int fallback = 0]) => v is num ? v.round() : int.tryParse('$v'.replaceAll(RegExp(r'[^0-9-]'), '')) ?? fallback;
Map<String, dynamic> _map(Object? v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
String _str(Object? v) => v == null ? '' : v.toString();

/// Server sort names.
enum ShopSort { latest, priceAsc, priceDesc, monthly }

extension ShopSortX on ShopSort {
  String get api => switch (this) {
        ShopSort.latest => 'latest',
        ShopSort.priceAsc => 'price_asc',
        ShopSort.priceDesc => 'price_desc',
        ShopSort.monthly => 'monthly',
      };

  String get label => switch (this) {
        ShopSort.latest => 'Newest',
        ShopSort.priceAsc => 'Price: low to high',
        ShopSort.priceDesc => 'Price: high to low',
        ShopSort.monthly => 'Lowest monthly',
      };

  static ShopSort? fromApi(String s) => ShopSort.values.where((v) => v.api == s).firstOrNull;
}

/// What the shop asks for. Any change except [page] starts again at page 1.
class ShopQuery {
  const ShopQuery({
    this.q = '',
    this.categoryIds = const {},
    this.brandIds = const {},
    this.minPrice,
    this.maxPrice,
    this.atompay = false,
    this.inStock = false,
    this.sort = ShopSort.latest,
  });

  final String q;
  final Set<int> categoryIds;
  final Set<int> brandIds;
  final int? minPrice;
  final int? maxPrice;
  final bool atompay;
  final bool inStock;
  final ShopSort sort;

  /// Filters the customer set (search and sort aside).
  int get filterCount => categoryIds.length + brandIds.length + (minPrice != null || maxPrice != null ? 1 : 0) + (atompay ? 1 : 0) + (inStock ? 1 : 0);

  bool get isEmpty => q.trim().isEmpty && filterCount == 0;

  ShopQuery copyWith({
    String? q,
    Set<int>? categoryIds,
    Set<int>? brandIds,
    int? Function()? minPrice,
    int? Function()? maxPrice,
    bool? atompay,
    bool? inStock,
    ShopSort? sort,
  }) =>
      ShopQuery(
        q: q ?? this.q,
        categoryIds: categoryIds ?? this.categoryIds,
        brandIds: brandIds ?? this.brandIds,
        minPrice: minPrice != null ? minPrice() : this.minPrice,
        maxPrice: maxPrice != null ? maxPrice() : this.maxPrice,
        atompay: atompay ?? this.atompay,
        inStock: inStock ?? this.inStock,
        sort: sort ?? this.sort,
      );

  /// Query string for [page].
  Map<String, String> params(int page, {int perPage = 20}) => {
        if (q.trim().isNotEmpty) 'q': q.trim(),
        if (categoryIds.isNotEmpty) 'category_id': categoryIds.join(','),
        if (brandIds.isNotEmpty) 'brand_id': brandIds.join(','),
        if (minPrice != null) 'min_price': '$minPrice',
        if (maxPrice != null) 'max_price': '$maxPrice',
        if (atompay) 'atompay': '1',
        if (inStock) 'stock': '1',
        'sort': sort.api,
        'page': '$page',
        'per_page': '$perPage',
      };

  @override
  bool operator ==(Object other) =>
      other is ShopQuery &&
      other.q == q &&
      _sameSet(other.categoryIds, categoryIds) &&
      _sameSet(other.brandIds, brandIds) &&
      other.minPrice == minPrice &&
      other.maxPrice == maxPrice &&
      other.atompay == atompay &&
      other.inStock == inStock &&
      other.sort == sort;

  @override
  int get hashCode => Object.hash(q, Object.hashAllUnordered(categoryIds), Object.hashAllUnordered(brandIds), minPrice, maxPrice, atompay, inStock, sort);

  static bool _sameSet(Set<int> a, Set<int> b) => a.length == b.length && a.containsAll(b);
}

class ShopPagination {
  const ShopPagination({required this.currentPage, required this.lastPage, required this.perPage, required this.total, required this.hasMore});

  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final bool hasMore;

  factory ShopPagination.fromJson(Map<String, dynamic> j) {
    final current = _int(j['current_page'], 1);
    final last = _int(j['last_page'], current);
    return ShopPagination(
      currentPage: current,
      lastPage: last,
      perPage: _int(j['per_page'], 15),
      total: _int(j['total']),
      hasMore: j['has_more'] is bool ? j['has_more'] as bool : current < last,
    );
  }
}

/// A category or brand in the filter sheet.
class ShopFilterOption {
  const ShopFilterOption({required this.id, required this.title, required this.count, this.picture = ''});

  final int id;
  final String title;
  final int count;
  final String picture;

  factory ShopFilterOption.fromJson(Map<String, dynamic> j) =>
      ShopFilterOption(id: _int(j['id']), title: _str(j['title']), count: _int(j['count']), picture: _str(j['picture']));
}

/// The whole Brand Partner catalogue, whatever is applied, so the filter
/// sheet does not shrink while filters are ticked.
class ShopFilters {
  const ShopFilters({required this.categories, required this.brands, required this.minPrice, required this.maxPrice, required this.months, required this.sorts});

  static const none = ShopFilters(categories: [], brands: [], minPrice: null, maxPrice: null, months: [], sorts: []);

  final List<ShopFilterOption> categories;
  final List<ShopFilterOption> brands;
  final int? minPrice;
  final int? maxPrice;
  final List<int> months;
  final List<ShopSort> sorts;

  bool get isEmpty => categories.isEmpty && brands.isEmpty && minPrice == null;

  factory ShopFilters.fromJson(Map<String, dynamic> j) {
    final price = _map(j['price']);
    return ShopFilters(
      categories: [for (final c in atomList(j['categories'])) ShopFilterOption.fromJson(c)],
      brands: [for (final b in atomList(j['brands'])) ShopFilterOption.fromJson(b)],
      minPrice: price['min'] == null ? null : _int(price['min']),
      maxPrice: price['max'] == null ? null : _int(price['max']),
      months: [for (final m in (j['months'] is List ? j['months'] as List : const [])) _int(m)],
      sorts: [for (final s in (j['sort'] is List ? j['sort'] as List : const [])) ?ShopSortX.fromApi('$s')],
    );
  }
}

class ShopPage {
  const ShopPage({required this.products, required this.pagination, required this.filters});

  final List<ProductCard> products;
  final ShopPagination pagination;
  final ShopFilters filters;

  /// `data` of `GET api/products`: the object, or the old flat list.
  factory ShopPage.fromData(Object? data) {
    if (data is List) {
      final products = [for (final p in atomList(data)) ProductCard.fromJson(p)];
      return ShopPage(
        products: products,
        pagination: ShopPagination(currentPage: 1, lastPage: 1, perPage: products.length, total: products.length, hasMore: false),
        filters: ShopFilters.none,
      );
    }
    final j = _map(data);
    final products = [for (final p in atomList(j['products'])) ProductCard.fromJson(p)];
    return ShopPage(
      products: products,
      pagination: j['pagination'] is Map
          ? ShopPagination.fromJson(_map(j['pagination']))
          : ShopPagination(currentPage: 1, lastPage: 1, perPage: products.length, total: products.length, hasMore: false),
      filters: j['filters'] is Map ? ShopFilters.fromJson(_map(j['filters'])) : ShopFilters.none,
    );
  }
}

class AtomShopApi {
  const AtomShopApi(this._network);

  final NetworkManager _network;

  Future<ShopPage> page(ShopQuery query, {int page = 1, int perPage = 20}) async {
    final params = query.params(page, perPage: perPage);
    final qs = params.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&');
    final res = await _network.getRequest('products?$qs');
    return ShopPage.fromData(res is Map ? res['data'] : null);
  }
}

final atomShopApiProvider = Provider<AtomShopApi>((ref) => AtomShopApi(ref.watch(networkManagerProvider)));
