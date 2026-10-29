import 'package:atompro/data/atom_order.dart';
import 'package:atompro/data/atom_product_detail.dart';
import 'package:flutter_test/flutter_test.dart';

/// POST api/app/orders answers and how its errors read.
void main() {
  test('reads the order receipt', () {
    final r = OrderReceipt.fromJson({
      'order_uuid': '9b1d-uuid',
      'order_id': 48261,
      'mode': 'installment',
      'type': 'atomshop',
      'product': 'Galaxy A56 5G',
      'storage': '256GB',
      'colour': null,
      'months': 12,
      'advance': 24000,
      'monthly': 10360,
      'total': 160319,
      'area': 'Johar Town',
      'atompay_url': null,
      'phone': '03001234567',
    });

    expect(r.id, 48261);
    expect(r.mode, PayMode.installment);
    expect(r.colour, isEmpty);
    expect(r.monthly, 10360);
    expect(r.atompayUrl, isEmpty);
  });

  test('cash orders have no monthly figure', () {
    final r = OrderReceipt.fromJson({'order_id': 1, 'mode': 'cash', 'months': 1, 'advance': 50000, 'monthly': null, 'total': 50000});
    expect(r.mode, PayMode.cash);
    expect(r.monthly, isNull);
  });

  test('pay modes use the API names', () {
    expect(PayMode.values.map((m) => m.apiName), ['installment', 'atompay', 'cash']);
  });

  test('error messages drop the Exception prefix; network failures read plainly', () {
    expect(atomErrorMessage(Exception('That installment tenure is not available.')), 'That installment tenure is not available.');
    expect(atomErrorMessage(Exception('Network Error: connection refused')), 'You seem to be offline. Check your internet connection and try again.');
  });
}
