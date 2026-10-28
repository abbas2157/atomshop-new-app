import 'package:atompro/data/atom_product_detail.dart';
import 'package:flutter_test/flutter_test.dart';

/// Parsing of GET api/products/{id} and the plan lookups the product page
/// relies on. Figures below are as the server sends them; the app only reads
/// them back.
void main() {
  Map<String, dynamic> row(int advance, int months, int a, int f, int m, int t) =>
      {'advance_percent': advance, 'months': months, 'advance': a, 'financed': f, 'monthly': m, 'total': t};

  Map<String, dynamic> payload() => {
        'id': 42,
        'title': 'Galaxy A56 5G',
        'price': '119,999',
        'picture': 'https://atomshop.pk/images/a56.png',
        'gallery': [
          {'id': 1, 'url': 'https://atomshop.pk/images/a56.png'},
          {'id': 2, 'url': 'https://atomshop.pk/images/a56-back.png'},
        ],
        'category': {'id': 3, 'title': 'Mobile phones', 'slug': 'mobile-phones', 'picture': 'images/cat.png'},
        'brand': {'id': 7, 'title': 'Samsung', 'slug': 'samsung', 'picture': 'images/samsung.png'},
        'memories': [
          {'id': 11, 'title': '128GB', 'variation_price': 104999, 'active': true},
          {'id': 12, 'title': '256GB', 'variation_price': '119999', 'active': false},
        ],
        'colors': [
          {'id': 5, 'title': 'Graphite', 'active': true},
        ],
        'short_description': ' 6.7" display ',
        'long_description': '',
        'plan': {
          'cash_price': 119999,
          'monthly_from': 11840,
          'atompay': true,
          'min_advance_percent': 20,
          'max_advance_percent': 40,
          'months': [3, 6, 12],
          'advance_options': [20, 30, 40, 50],
          'markup_percent': 4,
          'quotes': {
            '104999': [row(20, 6, 21000, 83999, 17360, 125159)],
            '119999': [row(20, 6, 24000, 95999, 19840, 143039), row(30, 12, 36000, 83999, 10360, 160319)],
          },
          'atompay_quotes': {
            '104999': {'months': 3, 'monthly': 34999, 'last_monthly': 35001, 'total': 104999, 'processing_fee': 3150},
            '119999': {'months': 3, 'monthly': 39999, 'last_monthly': 40001, 'total': 119999, 'processing_fee': 3600},
          },
        },
      };

  test('reads the product, options and plan block', () {
    final p = ProductDetail.fromJson(payload());

    expect(p.id, 42);
    expect(p.title, 'Galaxy A56 5G');
    expect(p.gallery, ['https://atomshop.pk/images/a56.png', 'https://atomshop.pk/images/a56-back.png']);
    expect(p.brand?.id, 7);
    expect(p.category?.title, 'Mobile phones');
    expect(p.storages.map((s) => s.price), [104999, 119999]);
    expect(p.colours.single.title, 'Graphite');
    expect(p.shortDescription, '6.7" display');
    expect(p.plan.atompay, isTrue);
    expect(p.plan.months, [3, 6, 12]);
    expect(p.plan.advanceOptions, [20, 30, 40, 50]);
    expect(p.plan.maxAdvancePercent, 40);
  });

  test('looks up a quote by price, advance and months', () {
    final p = ProductDetail.fromJson(payload());

    final q = p.plan.quote(price: 119999, advancePercent: 30, months: 12)!;
    expect(q.advance, 36000);
    expect(q.monthly, 10360);
    expect(q.total, 160319);

    expect(p.plan.quote(price: p.priceFor(p.storages.first), advancePercent: 20, months: 6)?.monthly, 17360);
    expect(p.plan.quote(price: 119999, advancePercent: 50, months: 3), isNull);
  });

  test('advance choices stay inside the band checkout accepts', () {
    expect(ProductDetail.fromJson(payload()).plan.advanceChoices, [20, 30, 40]);
  });

  test('AtomPay figures are looked up per storage price', () {
    final p = ProductDetail.fromJson(payload());

    final small = p.plan.atompayFor(p.priceFor(p.storages.first))!;
    expect(small.monthly, 34999);
    expect(small.lastMonthly, 35001);
    expect(small.processingFee, 3150);
    expect(p.plan.atompayFor(119999)?.total, 119999);
    expect(p.plan.atompayFor(1), isNull);
  });

  test('atompay_quotes is null for products that are not eligible', () {
    final json = payload();
    (json['plan'] as Map)
      ..['atompay'] = false
      ..['atompay_quotes'] = null;
    expect(ProductDetail.fromJson(json).plan.atompayQuotes, isEmpty);
  });

  test('base price is used when there is no storage option', () {
    final p = ProductDetail.fromJson(payload()..['memories'] = []);
    expect(p.storages, isEmpty);
    expect(p.priceFor(null), 119999);
  });

  test('an empty quotes list arrives as [] and parses to no quotes', () {
    final json = payload();
    (json['plan'] as Map)['quotes'] = [];
    expect(ProductDetail.fromJson(json).plan.quotes, isEmpty);
  });

  test('"Product not found." (data holds only the id) throws ProductNotFound', () {
    expect(() => ProductDetail.fromJson({'id': '42'}), throwsA(isA<ProductNotFound>()));
  });
}
