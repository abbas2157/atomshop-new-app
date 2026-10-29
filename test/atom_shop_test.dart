import 'package:atompro/data/atom_product_detail.dart';
import 'package:atompro/data/atom_shop.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shop answer (server TRD 2026-10-29-app-shop-api) and the old one.
void main() {
  final sample = {
    'products': [
      {
        'id': 81,
        'title': 'OXY Inverter AC 1.5 Ton',
        'slug': 'oxy-inverter-ac-1-5-ton',
        'price': '30,000',
        'picture': 'https://atomshop.pk/p.jpg',
        'category': 'Air Conditioner',
        'brand': 'OXY',
        'category_id': 4,
        'brand_id': 9,
        'cash_price': 150000,
        'monthly_from': 16000,
        'monthly_months': 12,
        'atompay': false,
        'in_stock': false,
        'status': 'Out of Stock',
        'something_new': 1,
      },
    ],
    'pagination': {'current_page': 1, 'last_page': 2, 'per_page': 15, 'total': 18, 'has_more': true},
    'filters': {
      'categories': [
        {'id': 4, 'title': 'Air Conditioner', 'count': 6},
      ],
      'brands': [
        {'id': 9, 'title': 'OXY', 'picture': 'https://atomshop.pk/b.png', 'count': 18},
      ],
      'price': {'min': 15000, 'max': 350000},
      'months': [3, 6, 9, 12],
      'sort': ['latest', 'price_asc', 'price_desc', 'monthly'],
    },
  };

  test('reads products, pages and the filter lists', () {
    final page = ShopPage.fromData(sample);
    final p = page.products.single;
    expect(p.cashPrice, 150000);
    expect(p.monthlyFrom, 16000);
    expect(p.inStock, isFalse);
    expect(page.pagination.total, 18);
    expect(page.pagination.hasMore, isTrue);
    expect(page.filters.brands.single.count, 18);
    expect(page.filters.minPrice, 15000);
    expect(page.filters.sorts, ShopSort.values);
  });

  test('the old flat list still reads, as one page without filters', () {
    final page = ShopPage.fromData([
      {'id': 1, 'title': 'A'},
      {'id': 2, 'title': 'B'},
    ]);
    expect(page.products.length, 2);
    expect(page.pagination.hasMore, isFalse);
    expect(page.filters.isEmpty, isTrue);
  });

  test('has_more is worked out when the server leaves it out', () {
    expect(ShopPagination.fromJson({'current_page': 1, 'last_page': 3}).hasMore, isTrue);
    expect(ShopPagination.fromJson({'current_page': 3, 'last_page': 3}).hasMore, isFalse);
  });

  test('the query becomes the API parameters', () {
    const q = ShopQuery(q: ' iphone ', categoryIds: {1, 2}, atompay: true, inStock: true, minPrice: 1000, sort: ShopSort.priceAsc);
    final params = q.params(2, perPage: 20);
    expect(params['q'], 'iphone');
    expect(params['category_id']!.split(',').toSet(), {'1', '2'});
    expect(params['atompay'], '1');
    expect(params['stock'], '1');
    expect(params['min_price'], '1000');
    expect(params.containsKey('max_price'), isFalse);
    expect(params['sort'], 'price_asc');
    expect(params['page'], '2');
    expect(q.filterCount, 5);
    expect(q, const ShopQuery(q: ' iphone ', categoryIds: {2, 1}, atompay: true, inStock: true, minPrice: 1000, sort: ShopSort.priceAsc));
  });

  test('a sold-out product page knows it', () {
    final p = ProductDetail.fromJson({'id': 5, 'title': 'X', 'plan': <String, dynamic>{}, 'in_stock': false, 'status': 'Out of Stock'});
    expect(p.inStock, isFalse);
    expect(ProductDetail.fromJson({'id': 5, 'title': 'X', 'plan': <String, dynamic>{}}).inStock, isTrue);
  });
}
