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
    this.hasShop = false,
    this.slug = '',
    this.shopUrl = '',
    this.logo = '',
    this.about = '',
    this.shareUrl = '',
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

  /// Empty when the seller has no WhatsApp: hide "Chat with seller". Always
  /// empty for a seller with a shop (orders go through Atomshop).
  final String whatsappUrl;

  /// Sells their own stock on Atomshop: the profile lists products and
  /// takes orders.
  final bool hasShop;

  /// Profile address for `app/sellers/{slug}`; the id works too.
  final String slug;

  /// The shop on the website, empty without a shop.
  final String shopUrl;

  /// Profile only: shop logo (empty: [picture], then [initial]), about text
  /// and the page to share.
  final String logo;
  final String about;
  final String shareUrl;

  /// What to ask `app/sellers/{key}` for.
  String get key => slug.isNotEmpty ? slug : '$id';

  /// The best picture to show: the shop logo, else the owner's photo.
  String get image => logo.isNotEmpty ? logo : picture;

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
      hasShop: j['has_shop'] == true,
      slug: _str(j['slug']),
      shopUrl: _str(j['shop_url']),
      logo: _str(j['logo']),
      about: _str(j['about']),
      shareUrl: _str(j['share_url'] ?? j['shop_url']),
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

// ── Seller shops (atomshop docs/trd/2026-11-03-seller-shop-pages.md) ──────

List<int> _ints(Object? v) => v is List ? v.map((e) => AtomFormat.parseAmount(e)).whereType<int>().toList(growable: false) : const [];

/// One option of a seller's item (a colour, a size…), ordered by its id.
class SellerVariant {
  const SellerVariant({required this.stockVariantId, required this.name, required this.price, required this.available});

  final int stockVariantId;
  final String name;
  final int price;
  final int available;

  factory SellerVariant.fromJson(Map<String, dynamic> j) =>
      SellerVariant(stockVariantId: _int(j['stock_variant_id']), name: _str(j['name']), price: _int(j['price']), available: _int(j['available']));
}

/// An item a seller has in stock (seller profile, `app/sellers-near`).
class SellerItem {
  const SellerItem({
    required this.id,
    required this.title,
    required this.description,
    required this.photo,
    required this.url,
    required this.category,
    required this.brand,
    required this.price,
    required this.monthlyFrom,
    required this.available,
    required this.catalogueProductId,
    required this.seller,
    required this.variants,
  });

  final int id;
  final String title;
  final String description;
  final String photo;

  /// The item's page on the website (share).
  final String url;
  final String category;
  final String brand;

  /// The lowest variant price.
  final int price;
  final int? monthlyFrom;
  final int available;

  /// The same product in the Atomshop catalogue, if any.
  final int? catalogueProductId;

  /// Filled in `app/sellers-near` only.
  final Seller? seller;
  final List<SellerVariant> variants;

  /// "Only 2 left" at 2 or fewer.
  bool get fewLeft => available > 0 && available <= 2;

  factory SellerItem.fromJson(Map<String, dynamic> j) {
    final seller = _map(j['seller']);
    return SellerItem(
      id: _int(j['id']),
      title: _str(j['title']),
      description: _str(j['description']),
      photo: _str(j['photo']),
      url: _str(j['url']),
      category: _str(j['category']),
      brand: _str(j['brand']),
      price: _int(j['price']),
      monthlyFrom: AtomFormat.parseAmount(j['monthly_from']),
      available: _int(j['available']),
      catalogueProductId: AtomFormat.parseAmount(j['catalogue_product_id']),
      seller: seller.isEmpty ? null : Seller.fromJson(seller),
      variants: atomList(j['variants']).map(SellerVariant.fromJson).toList(growable: false),
    );
  }
}

/// A seller's monthly plan for one price, worked out as the server does
/// (the TRD's plan maths) so the figures follow the buyer's choices live.
/// The server recalculates when the order is placed.
class SellerPlanQuote {
  const SellerPlanQuote({required this.price, required this.advance, required this.months, required this.markup, required this.monthly});

  final int price;
  final int advance;
  final int months;
  final int markup;
  final int monthly;

  int get financed => price - advance;
  int get total => price + markup;
}

/// The seller's own plan: markup [rate] percent a month on the amount after
/// the advance, for one of [months], with one of the [advance] percentages.
class SellerTerms {
  const SellerTerms({required this.rate, required this.months, required this.defaultMonths, required this.advance, required this.defaultAdvance});

  final num rate;
  final List<int> months;
  final int defaultMonths;
  final List<int> advance;
  final int defaultAdvance;

  static SellerTerms? fromJson(Object? v) {
    final j = _map(v);
    if (j.isEmpty) return null;
    final months = _ints(j['months']);
    final advance = _ints(j['advance']);
    if (months.isEmpty || advance.isEmpty) return null;
    final m = _int(j['default_months'], months.last);
    final a = _int(j['default_advance'], advance.first);
    return SellerTerms(
      rate: j['rate'] is num ? j['rate'] as num : (num.tryParse(_str(j['rate'])) ?? 0),
      months: months,
      defaultMonths: months.contains(m) ? m : months.last,
      advance: advance,
      defaultAdvance: advance.contains(a) ? a : advance.first,
    );
  }

  /// advance = ceil(price × advance% / 100); markup = round(financed × rate
  /// / 100 × months); monthly = round((financed + markup) / months).
  SellerPlanQuote quote({required int price, required int advancePercent, required int months}) {
    final advance = (price * advancePercent + 99) ~/ 100;
    final financed = price - advance;
    final markup = (financed * rate / 100 * months).round();
    return SellerPlanQuote(
      price: price,
      advance: advance,
      months: months,
      markup: markup,
      monthly: months <= 0 ? 0 : ((financed + markup) / months).round(),
    );
  }

  /// "4% a month", "2.5% a month".
  String get rateLabel => '${rate == rate.roundToDouble() ? rate.round() : rate}% a month';
}

class SellerFilterOption {
  const SellerFilterOption(this.id, this.title);

  final int id;
  final String title;

  factory SellerFilterOption.fromJson(Map<String, dynamic> j) => SellerFilterOption(_int(j['id']), _str(j['title']));
}

/// How a seller's products (and a brand's) are ordered.
enum ShopSort {
  latest('latest', 'Latest'),
  monthly('monthly', 'Lowest monthly'),
  priceAsc('price_asc', 'Price: low to high'),
  priceDesc('price_desc', 'Price: high to low');

  const ShopSort(this.apiName, this.label);

  final String apiName;
  final String label;
}

/// What a seller profile is filtered by. A record-like value, so it can key
/// a provider family.
class SellerProfileQuery {
  const SellerProfileQuery({required this.key, this.areaId, this.q = '', this.categoryId, this.brandId, this.sort = ShopSort.latest});

  final String key;
  final int? areaId;
  final String q;
  final int? categoryId;
  final int? brandId;
  final ShopSort sort;

  SellerProfileQuery copyWith({String? q, int? Function()? categoryId, int? Function()? brandId, ShopSort? sort}) => SellerProfileQuery(
        key: key,
        areaId: areaId,
        q: q ?? this.q,
        categoryId: categoryId == null ? this.categoryId : categoryId(),
        brandId: brandId == null ? this.brandId : brandId(),
        sort: sort ?? this.sort,
      );

  bool get filtered => q.isNotEmpty || categoryId != null || brandId != null;

  @override
  bool operator ==(Object other) =>
      other is SellerProfileQuery &&
      other.key == key &&
      other.areaId == areaId &&
      other.q == q &&
      other.categoryId == categoryId &&
      other.brandId == brandId &&
      other.sort == sort;

  @override
  int get hashCode => Object.hash(key, areaId, q, categoryId, brandId, sort);
}

/// `GET app/sellers/{slug or id}`.
class SellerProfile {
  const SellerProfile({
    required this.seller,
    required this.productCount,
    required this.dealsDone,
    required this.areaCount,
    required this.areas,
    required this.deliversToArea,
    required this.terms,
    required this.categories,
    required this.brands,
    required this.products,
  });

  final Seller seller;
  final int productCount;
  final int dealsDone;
  final int areaCount;
  final List<SellerPlace> areas;

  /// For the area asked about; null when none was sent.
  final bool? deliversToArea;

  /// Null without a shop.
  final SellerTerms? terms;
  final List<SellerFilterOption> categories;
  final List<SellerFilterOption> brands;
  final List<SellerItem> products;

  factory SellerProfile.fromJson(Object? data) {
    final j = _map(data);
    final stats = _map(j['stats']);
    final filters = _map(j['filters']);
    final areas = (j['areas'] is List ? j['areas'] as List : const []).map(SellerPlace.fromJson).whereType<SellerPlace>().toList(growable: false);
    return SellerProfile(
      seller: Seller.fromJson(_map(j['seller'])),
      productCount: _int(stats['products']),
      dealsDone: _int(stats['deals_done']),
      areaCount: _int(stats['areas'], areas.length),
      areas: areas,
      deliversToArea: j['delivers_to_area'] is bool ? j['delivers_to_area'] as bool : null,
      terms: SellerTerms.fromJson(j['terms']),
      categories: atomList(filters['categories']).map(SellerFilterOption.fromJson).toList(growable: false),
      brands: atomList(filters['brands']).map(SellerFilterOption.fromJson).toList(growable: false),
      products: atomList(j['products']).map(SellerItem.fromJson).toList(growable: false),
    );
  }
}

/// `GET app/sellers/{slug or id}/products/{id}`.
class SellerItemPage {
  const SellerItemPage({required this.seller, required this.item, required this.terms, required this.deliversToArea, required this.more});

  final Seller seller;
  final SellerItem item;
  final SellerTerms? terms;
  final bool? deliversToArea;

  /// Up to 6 other items from this seller.
  final List<SellerItem> more;

  factory SellerItemPage.fromJson(Object? data) {
    final j = _map(data);
    return SellerItemPage(
      seller: Seller.fromJson(_map(j['seller'])),
      item: SellerItem.fromJson(_map(j['product'])),
      terms: SellerTerms.fromJson(j['terms']),
      deliversToArea: j['delivers_to_area'] is bool ? j['delivers_to_area'] as bool : null,
      more: atomList(j['more']).map(SellerItem.fromJson).toList(growable: false),
    );
  }
}

/// `GET app/sellers-near`: sellers' items for the buyer's area, and the
/// catalogue products a nearby seller has in stock.
class SellersNear {
  const SellersNear({required this.products, required this.catalogueProductIds});

  static const empty = SellersNear(products: [], catalogueProductIds: {});

  final List<SellerItem> products;
  final Set<int> catalogueProductIds;

  factory SellersNear.fromJson(Object? data) {
    final j = _map(data);
    return SellersNear(
      products: atomList(j['products']).map(SellerItem.fromJson).toList(growable: false),
      catalogueProductIds: _ints(j['catalogue_product_ids']).toSet(),
    );
  }
}

/// What `POST app/stock-orders` saved.
class StockOrderReceipt {
  const StockOrderReceipt({
    required this.uuid,
    required this.id,
    required this.installment,
    required this.product,
    required this.total,
    required this.advance,
    required this.months,
    required this.monthly,
    required this.heldHours,
    required this.sellerName,
  });

  final String uuid;
  final int id;
  final bool installment;
  final String product;
  final int total;
  final int advance;
  final int months;
  final int? monthly;
  final int heldHours;

  /// From the screen that placed it (the answer has no seller).
  final String sellerName;

  factory StockOrderReceipt.fromJson(Object? data, {required String sellerName}) {
    final j = _map(data);
    return StockOrderReceipt(
      uuid: _str(j['order_uuid']),
      id: _int(j['order_id']),
      installment: _str(j['mode']) == 'installment',
      product: _str(j['product']),
      total: _int(j['total']),
      advance: _int(j['advance']),
      months: _int(j['months']),
      monthly: AtomFormat.parseAmount(j['monthly']),
      heldHours: _int(j['held_hours'], 48),
      sellerName: sellerName,
    );
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

  Future<SellerProfile> profile(SellerProfileQuery query) async =>
      SellerProfile.fromJson(await _http.get('app/sellers/${Uri.encodeComponent(query.key)}', query: {
        'area_id': ?query.areaId,
        if (query.q.trim().isNotEmpty) 'q': query.q.trim(),
        'category_id': ?query.categoryId,
        'brand_id': ?query.brandId,
        'sort': query.sort.apiName,
      }));

  Future<SellerItemPage> item(String sellerKey, int itemId, {int? areaId}) async =>
      SellerItemPage.fromJson(await _http.get('app/sellers/${Uri.encodeComponent(sellerKey)}/products/$itemId', query: {'area_id': ?areaId}));

  Future<SellersNear> near(int areaId, {int limit = 20}) async =>
      SellersNear.fromJson(await _http.get('app/sellers-near', query: {'area_id': areaId, 'limit': limit}));

  /// Orders one unit of a seller's item. [months] and [advancePercent] only
  /// for an installment order.
  Future<StockOrderReceipt> order({
    required String sellerName,
    required int stockVariantId,
    required int areaId,
    required bool installment,
    int? months,
    int? advancePercent,
    required String fullName,
    required String phone,
    required String email,
    required String address,
  }) async =>
      StockOrderReceipt.fromJson(
        await _http.post('app/stock-orders', {
          'stock_variant_id': stockVariantId,
          'area_id': areaId,
          'mode': installment ? 'installment' : 'cash',
          if (installment) 'months': months,
          if (installment) 'advance_percent': advancePercent,
          'full_name': fullName,
          'phone': phone,
          if (email.isNotEmpty) 'email': email,
          'address': address,
        }),
        sellerName: sellerName,
      );
}

final atomSellersApiProvider = Provider<AtomSellersApi>((ref) => AtomSellersApi(ref.watch(atomHttpProvider)));
