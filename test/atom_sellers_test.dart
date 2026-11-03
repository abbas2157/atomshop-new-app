import 'package:atompro/data/atom_http.dart';
import 'package:atompro/data/atom_sellers.dart';
import 'package:atompro/design/atom_theme.dart';
import 'package:atompro/screens/sellers/atom_seller_widgets.dart';
import 'package:atompro/state/atom_sellers_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verified sellers directory (api/app/sellers, api/app/sellers/top-rated).
void main() {
  final sample = {
    'id': 7,
    'name': 'Zaka Brothers',
    'owner': 'Zaka Ullah',
    'business_type': 'Sole Proprietor',
    'picture': null,
    'initial': 'Z',
    'city': {'id': 1, 'title': 'Lahore'},
    'area': {'id': 12, 'title': 'Johar Town'},
    'location': 'Johar Town, Lahore',
    'top_rated': true,
    'atomshop_ships': true,
    'orders_done': 37,
    'member_since': '2026-05',
    'member_since_label': 'May 2026',
    'whatsapp_url': 'https://wa.me/923001234567',
    'something_new': 'ignored',
  };

  test('a seller reads every field and ignores unknown ones', () {
    final s = Seller.fromJson(sample);
    expect(s.id, 7);
    expect(s.name, 'Zaka Brothers');
    expect(s.owner, 'Zaka Ullah');
    expect(s.businessType, 'Sole Proprietor');
    expect(s.picture, isEmpty);
    expect(s.initial, 'Z');
    expect(s.city?.title, 'Lahore');
    expect(s.area?.id, 12);
    expect(s.location, 'Johar Town, Lahore');
    expect(s.topRated, isTrue);
    expect(s.atomshopShips, isTrue);
    expect(s.ordersDone, 37);
    expect(s.memberSinceLabel, 'May 2026');
    expect(s.whatsappUrl, 'https://wa.me/923001234567');
    expect(sellerFacts(s), '37 orders done · Member since May 2026');
  });

  test('missing fields fall back safely', () {
    final s = Seller.fromJson({'id': 3, 'name': 'ali traders', 'city': null, 'area': null, 'whatsapp_url': null});
    expect(s.initial, 'A');
    expect(s.city, isNull);
    expect(s.whatsappUrl, isEmpty);
    expect(s.topRated, isFalse);
    expect(s.ordersDone, 0);
  });

  test('a sellers page reads its pagination', () {
    final page = SellersPage.fromJson({
      'sellers': [sample, sample],
      'pagination': {'current_page': 1, 'last_page': 3, 'per_page': 2, 'total': 5, 'has_more': true},
    });
    expect(page.sellers, hasLength(2));
    expect(page.pagination.total, 5);
    expect(page.pagination.hasMore, isTrue);
    expect(page.pagination.nextPage, 2);

    final last = AtomPagination.fromJson({'current_page': 3, 'last_page': 3, 'per_page': 2, 'total': 5, 'has_more': false});
    expect(last.nextPage, isNull);

    // No has_more: worked out from the pages.
    expect(AtomPagination.fromJson({'current_page': 1, 'last_page': 2}).hasMore, isTrue);
    // No pagination at all: one page.
    expect(AtomPagination.fromJson(null, fallbackCount: 4).total, 4);
  });

  Future<void> pumpStrip(WidgetTester tester, Future<List<Seller>> Function() load) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [topRatedSellersProvider.overrideWith((ref) => load())],
      child: MaterialApp(theme: AtomTheme.light(), home: const Scaffold(body: HomeTopSellersStrip())),
    ));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('the Home strip shows nothing until the server has sellers', (tester) async {
    await pumpStrip(tester, () async => throw const AtomApiException('This is not available in the app yet. Please try again later.', statusCode: 404));
    expect(find.text('Top rated sellers'), findsNothing);

    await pumpStrip(tester, () async => const <Seller>[]);
    expect(find.text('Top rated sellers'), findsNothing);
  });

  testWidgets('the Home strip lists top rated sellers', (tester) async {
    await pumpStrip(tester, () async => [Seller.fromJson(sample)]);
    expect(find.text('Top rated sellers'), findsOneWidget);
    expect(find.text('Zaka Brothers'), findsOneWidget);
    expect(find.text('See all'), findsOneWidget);
  });

  // ── Seller shops (docs/trd/2026-11-03-seller-shop-pages.md) ─────────────

  final terms = SellerTerms.fromJson({'rate': 4, 'months': [3, 6, 9, 12], 'default_months': 12, 'advance': [20, 30, 40, 50], 'default_advance': 20})!;

  test("the plan matches the server's worked example", () {
    final q = terms.quote(price: 118500, advancePercent: 20, months: 12);
    expect(q.advance, 23700);
    expect(q.financed, 94800);
    expect(q.markup, 45504);
    expect(q.monthly, 11692);
    expect(q.total, 164004);
    expect(terms.rateLabel, '4% a month');
  });

  test('the advance rounds up to a whole rupee', () {
    // 30% of 99,999 is 29,999.7.
    expect(terms.quote(price: 99999, advancePercent: 30, months: 3).advance, 30000);
  });

  test('terms fall back to offered values and need months and advance', () {
    final t = SellerTerms.fromJson({'rate': 2.5, 'months': [6, 12], 'default_months': 9, 'advance': [30], 'default_advance': 20})!;
    expect(t.defaultMonths, 12);
    expect(t.defaultAdvance, 30);
    expect(t.rateLabel, '2.5% a month');
    expect(SellerTerms.fromJson(null), isNull);
    expect(SellerTerms.fromJson({'rate': 4, 'months': [], 'advance': [20]}), isNull);
  });

  test('a seller with a shop reads its shop fields and offers no WhatsApp', () {
    final s = Seller.fromJson({
      ...sample,
      'whatsapp_url': null,
      'has_shop': true,
      'slug': 'zaka-brothers-4',
      'shop_url': 'https://atomshop.pk/sellers/zaka-brothers-4',
      'logo': 'https://atomshop.pk/logo.jpg',
    });
    expect(s.hasShop, isTrue);
    expect(s.key, 'zaka-brothers-4');
    expect(s.image, 'https://atomshop.pk/logo.jpg');
    expect(s.shareUrl, 'https://atomshop.pk/sellers/zaka-brothers-4');
    expect(s.whatsappUrl, isEmpty);
    // No slug: the id is the address.
    expect(Seller.fromJson({'id': 9, 'name': 'X'}).key, '9');
  });

  test('a seller profile reads stats, areas, terms, filters and items', () {
    final p = SellerProfile.fromJson({
      'seller': {...sample, 'has_shop': true, 'slug': 'zaka-brothers-4'},
      'stats': {'products': 8, 'deals_done': 40, 'member_since': '2025-04', 'areas': 474},
      'areas': [
        {'id': 274, 'title': 'Abdalian Housing Society'},
      ],
      'delivers_to_area': true,
      'terms': {'rate': 4, 'months': [3, 6, 9, 12], 'default_months': 12, 'advance': [20, 30, 40, 50], 'default_advance': 20},
      'filters': {
        'categories': [
          {'id': 4, 'title': 'Smart TV'},
        ],
        'brands': [
          {'id': 36, 'title': 'OXY'},
        ],
      },
      'products': [
        {
          'id': 68,
          'title': 'Haier Refrigerator HRF-336',
          'price': 118500,
          'monthly_from': 11692,
          'available': 2,
          'catalogue_product_id': null,
          'seller': null,
          'variants': [
            {'stock_variant_id': 91, 'name': 'Silver', 'price': 118500, 'available': 2},
          ],
        },
      ],
    });
    expect(p.productCount, 8);
    expect(p.dealsDone, 40);
    expect(p.areaCount, 474);
    expect(p.areas.single.title, 'Abdalian Housing Society');
    expect(p.deliversToArea, isTrue);
    expect(p.terms?.defaultMonths, 12);
    expect(p.categories.single.title, 'Smart TV');
    expect(p.brands.single.id, 36);
    final item = p.products.single;
    expect(item.fewLeft, isTrue);
    expect(item.catalogueProductId, isNull);
    expect(item.seller, isNull);
    expect(item.variants.single.stockVariantId, 91);

    // No area sent: unknown, not "doesn't deliver".
    expect(SellerProfile.fromJson({'seller': sample, 'delivers_to_area': null}).deliversToArea, isNull);
  });

  test('sellers near the buyer list items and nearby catalogue products', () {
    final near = SellersNear.fromJson({
      'products': [
        {'id': 68, 'title': 'Fridge', 'price': 1000, 'available': 5, 'seller': sample, 'variants': []},
      ],
      'catalogue_product_ids': [163, 157],
    });
    expect(near.products.single.seller?.name, 'Zaka Brothers');
    expect(near.catalogueProductIds, {163, 157});
  });

  test('a stock order receipt reads cash and installment answers', () {
    final cash = StockOrderReceipt.fromJson(
      {'order_uuid': 'u', 'order_id': 512, 'mode': 'cash', 'product': 'Fridge · Silver', 'total': 118500, 'advance': 0, 'months': 0, 'monthly': null, 'held_hours': 48},
      sellerName: 'Zaka Brothers',
    );
    expect(cash.installment, isFalse);
    expect(cash.monthly, isNull);
    expect(cash.heldHours, 48);
    final plan = StockOrderReceipt.fromJson({'mode': 'installment', 'months': 12, 'monthly': 11692, 'advance': 23700, 'total': 164004}, sellerName: 'Z');
    expect(plan.installment, isTrue);
    expect(plan.monthly, 11692);
    expect(plan.heldHours, 48);
  });
}
