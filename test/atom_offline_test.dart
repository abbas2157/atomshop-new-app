import 'package:atompro/data/atom_account.dart';
import 'package:atompro/data/atom_http.dart';
import 'package:atompro/state/atom_outbox.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Api\Order\CustomOfferController::store: total = price
  // + (price - advance) * 0.04 * months + price * 0.01.
  test('custom order plan matches the server formula, offline', () async {
    final q = await AtomAccountApi(AtomHttp()).customQuote(price: 100000, advance: 20000, months: 12);
    expect(q.financed, 80000);
    expect(q.markup, 38400);
    expect(q.sourcingFee, 1000);
    expect(q.sourcingFeePercent, 1);
    expect(q.total, 139400);
    expect(q.monthly, 9950);
  });

  test('custom order plan rounds like the server', () async {
    final q = await AtomAccountApi(AtomHttp()).customQuote(price: 45999, advance: 9200, months: 5);
    // 36799 * 0.2 = 7359.8; 459.99 fee; 45999 + 7359.8 + 459.99 = 53818.79.
    expect(q.markup, 7360);
    expect(q.sourcingFee, 460);
    expect(q.total, 53819);
    expect(q.monthly, ((53819 - 9200) / 5).round());
  });

  test('an advance under the minimum is refused before any plan', () async {
    expect(
      () => AtomAccountApi(AtomHttp()).customQuote(price: 100000, advance: 10000, months: 12),
      throwsA(isA<AtomApiException>().having((e) => e.fieldError('advance'), 'advance', isNotNull)),
    );
  });

  test('an outbox item survives being saved and read back', () {
    final item = OutboxItem(
      id: 'abc',
      kind: OutboxKind.customOrder,
      createdAt: DateTime(2026, 10, 31, 14, 5),
      payload: const {'product_title': 'Honda CD 70', 'price': 180000, 'months': 12},
      files: const ['/data/offline/files/1.jpg'],
      owner: 'uuid-1',
    );
    final back = OutboxItem.fromJson(item.toJson())!;
    expect(back.kind, OutboxKind.customOrder);
    expect(back.payload['price'], 180000);
    expect(back.files, item.files);
    expect(back.owner, 'uuid-1');
    expect(back.refused, isFalse);
    expect(back.title, 'Custom order: Honda CD 70');
    expect(back.refusedWith('The phone field is required.').refused, isTrue);
  });
}
