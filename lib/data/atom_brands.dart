import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/atom_format.dart';
import 'atom_http.dart';
import 'atom_models.dart';
import 'atom_sellers.dart';

/// Brand partners and brand pages, the same as the website's
/// (`api/app/brand-partners`, `api/app/brands/{slug or id}`; atomshop
/// docs/trd/2026-11-03-seller-shop-pages.md). Public, no token.

int _int(Object? v, [int fallback = 0]) => AtomFormat.parseAmount(v) ?? fallback;
String _str(Object? v) => v == null ? '' : v.toString();
Map<String, dynamic> _map(Object? v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

/// A brand card (partners list) and the top of a brand page.
class BrandPartner {
  const BrandPartner({
    required this.id,
    required this.title,
    required this.slug,
    required this.logo,
    required this.initial,
    required this.isPartner,
    required this.atompayWholeBrand,
    required this.listedCount,
  });

  final int id;
  final String title;
  final String slug;

  /// Empty: show [initial] in a coloured square.
  final String logo;
  final String initial;
  final bool isPartner;

  /// Every product of the brand is on AtomPay.
  final bool atompayWholeBrand;
  final int? listedCount;

  /// What to ask `app/brands/{key}` for.
  String get key => slug.isNotEmpty ? slug : '$id';

  factory BrandPartner.fromJson(Map<String, dynamic> j) {
    final title = _str(j['title']).trim();
    final sent = _str(j['initial']).trim();
    return BrandPartner(
      id: _int(j['id']),
      title: title,
      slug: _str(j['slug']),
      logo: _str(j['logo']),
      initial: sent.isNotEmpty ? sent : (title.isEmpty ? '?' : title.substring(0, 1).toUpperCase()),
      isPartner: j['is_partner'] == true,
      atompayWholeBrand: j['atompay_whole_brand'] == true,
      listedCount: AtomFormat.parseAmount(j['listed_count']),
    );
  }
}

class BrandPromo {
  const BrandPromo({required this.tag, required this.heading, required this.text});

  final String tag;
  final String heading;
  final String text;

  factory BrandPromo.fromJson(Map<String, dynamic> j) => BrandPromo(tag: _str(j['tag']), heading: _str(j['heading']), text: _str(j['text']));
}

/// The brand's own store details.
class BrandProfile {
  const BrandProfile({
    required this.card,
    required this.banner,
    required this.storeTitle,
    required this.intro,
    required this.website,
    required this.supportEmail,
    required this.supportPhone,
    required this.promos,
    required this.shareUrl,
  });

  final BrandPartner card;
  final String banner;

  /// "OXY official store on Atomshop".
  final String storeTitle;
  final String intro;
  final String website;
  final String supportEmail;
  final String supportPhone;
  final List<BrandPromo> promos;
  final String shareUrl;

  factory BrandProfile.fromJson(Map<String, dynamic> j) {
    final card = BrandPartner.fromJson(j);
    final store = _str(j['store_title']);
    final intro = _str(j['intro']);
    return BrandProfile(
      card: card,
      banner: _str(j['banner']),
      storeTitle: store.isNotEmpty ? store : card.title,
      intro: intro.isNotEmpty ? intro : _str(j['tagline']),
      website: _str(j['website']),
      supportEmail: _str(j['support_email']),
      supportPhone: _str(j['support_phone']),
      promos: atomList(j['promos']).map(BrandPromo.fromJson).where((p) => p.heading.isNotEmpty || p.text.isNotEmpty).toList(growable: false),
      shareUrl: _str(j['share_url']),
    );
  }
}

class BrandCategory {
  const BrandCategory({required this.id, required this.title, required this.count});

  final int id;
  final String title;
  final int count;

  factory BrandCategory.fromJson(Map<String, dynamic> j) => BrandCategory(id: _int(j['id']), title: _str(j['title']), count: _int(j['count']));
}

/// One page of `app/brands/{key}`.
class BrandPage {
  const BrandPage({
    required this.brand,
    required this.productCount,
    required this.categoryCount,
    required this.planMonths,
    required this.categories,
    required this.featured,
    required this.products,
    required this.pagination,
  });

  final BrandProfile brand;
  final int productCount;
  final int categoryCount;

  /// "3–12".
  final String planMonths;
  final List<BrandCategory> categories;
  final List<ProductCard> featured;
  final List<ProductCard> products;
  final AtomPagination pagination;

  factory BrandPage.fromJson(Object? data) {
    final j = _map(data);
    final brand = BrandProfile.fromJson(_map(j['brand']));
    final stats = _map(j['stats']);
    // Brand pages send no brand on each product; the card shows it.
    List<ProductCard> cards(Object? v) =>
        atomList(v).map((p) => ProductCard.fromJson({...p, 'brand': p['brand'] ?? brand.card.title})).toList(growable: false);
    final products = cards(j['products']);
    return BrandPage(
      brand: brand,
      productCount: _int(stats['products']),
      categoryCount: _int(stats['categories']),
      planMonths: _str(stats['plan_months']),
      categories: atomList(j['categories']).map(BrandCategory.fromJson).toList(growable: false),
      featured: cards(j['featured']),
      products: products,
      pagination: AtomPagination.fromJson(j['pagination'], fallbackCount: products.length),
    );
  }
}

/// What a brand page is filtered by.
class BrandQuery {
  const BrandQuery({this.categoryId, this.sort = ShopSort.latest, this.atompayOnly = false, this.inStockOnly = false});

  final int? categoryId;
  final ShopSort sort;
  final bool atompayOnly;
  final bool inStockOnly;
}

class AtomBrandsApi {
  const AtomBrandsApi(this._http);

  final AtomHttp _http;

  Future<List<BrandPartner>> partners() async =>
      atomList(_map(await _http.get('app/brand-partners'))['brands']).map(BrandPartner.fromJson).toList(growable: false);

  Future<BrandPage> page(String key, BrandQuery query, {int page = 1, int perPage = 20}) async =>
      BrandPage.fromJson(await _http.get('app/brands/${Uri.encodeComponent(key)}', query: {
        'category_id': ?query.categoryId,
        'sort': query.sort.apiName,
        if (query.atompayOnly) 'atompay': 1,
        if (query.inStockOnly) 'stock': 1,
        'page': page,
        'per_page': perPage,
      }));
}

final atomBrandsApiProvider = Provider<AtomBrandsApi>((ref) => AtomBrandsApi(ref.watch(atomHttpProvider)));
