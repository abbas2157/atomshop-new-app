import 'package:atompro/data/atom_brands.dart';
import 'package:flutter_test/flutter_test.dart';

/// Brand partners and brand pages (api/app/brand-partners, api/app/brands/{slug}).
void main() {
  final brand = {
    'id': 36,
    'title': 'OXY',
    'slug': 'oxy',
    'logo': null,
    'initial': 'O',
    'is_partner': true,
    'atompay_whole_brand': false,
    'listed_count': 10,
  };

  test('a brand partner reads its card and falls back to the initial', () {
    final b = BrandPartner.fromJson(brand);
    expect(b.key, 'oxy');
    expect(b.logo, isEmpty);
    expect(b.initial, 'O');
    expect(b.isPartner, isTrue);
    expect(b.listedCount, 10);
    expect(BrandPartner.fromJson({'id': 5, 'title': 'haier'}).initial, 'H');
    expect(BrandPartner.fromJson({'id': 5, 'title': 'haier'}).key, '5');
  });

  test('a brand page reads the profile, stats, categories and products', () {
    final page = BrandPage.fromJson({
      'brand': {
        ...brand,
        'store_title': 'OXY official store on Atomshop',
        'intro': '',
        'tagline': 'Smart TVs for every home',
        'website': 'https://oxy.pk',
        'promos': [
          {'tag': 'New', 'heading': 'Summer range is here', 'text': ''},
          {'tag': '', 'heading': '', 'text': ''},
        ],
        'share_url': 'https://atomshop.pk/brand/oxy',
      },
      'stats': {'products': 10, 'categories': 1, 'plan_months': '3–12'},
      'categories': [
        {'id': 4, 'title': 'Smart TV', 'slug': 'Smart-tv', 'count': 10},
      ],
      'featured': [],
      'products': [
        {'id': 166, 'title': 'OXY 4318L (BB) Gold', 'category': 'Smart TV', 'cash_price': 72000, 'monthly_from': 7104, 'atompay': true, 'in_stock': false},
      ],
      'pagination': {'current_page': 1, 'last_page': 1, 'per_page': 15, 'total': 10, 'has_more': false},
    });
    expect(page.brand.storeTitle, 'OXY official store on Atomshop');
    // No intro: the tagline stands in.
    expect(page.brand.intro, 'Smart TVs for every home');
    // Empty promos are dropped.
    expect(page.brand.promos, hasLength(1));
    expect(page.planMonths, '3–12');
    expect(page.categories.single.count, 10);
    final p = page.products.single;
    expect(p.brand, 'OXY');
    expect(p.inStock, isFalse);
    expect(p.monthlyFrom, 7104);
    expect(page.pagination.hasMore, isFalse);
  });
}
