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
}
