import 'package:atompro/data/atom_http.dart';
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

  test('reads the AtomPay Key Fact Statement and its acceptance', () {
    final f = KeyFacts.fromJson({
      'version': 'kfs-2026-11',
      'product': 'Galaxy A16 · 128GB',
      'seller': {'name': 'Atomshop (Pvt) Ltd', 'address': null},
      'cash_price': 100000,
      'amount_financed': 100000,
      'advance': 0,
      'markup_percent': 0.0,
      'markup': 0,
      'processing_fee_percent': 3.0,
      'processing_fee': 3000,
      'apr_percent': 18.5,
      'months': 3,
      'instalments': [
        {'number': 1, 'due': '1 month after delivery', 'due_date': null, 'amount': 33333},
        {'number': 2, 'due': '2 months after delivery', 'due_date': null, 'amount': 33333},
        {'number': 3, 'due': '3 months after delivery', 'due_date': null, 'amount': 33334},
      ],
      'total_repayable': 100000,
      'late_payment': 'Rs. 500 per missed month, no interest',
    });

    expect(f.amountFinanced, 100000);
    expect(f.instalments.map((i) => i.amount), [33333, 33333, 33334]);
    expect(f.instalments.first.due, '1 month after delivery');
    expect(f.sellerAddress, isEmpty);
    expect(f.earlySettlement, isEmpty);
    expect(f.acceptance, {'accept_kfs': true, 'kfs_amount': 100000});
  });

  test('a seller with no name yet reads as Atomshop', () {
    expect(KeyFacts.fromJson({'seller': {'name': ''}}).sellerName, 'Atomshop');
    expect(KeyFacts.fromJson(const {}).sellerName, 'Atomshop');
  });

  test('percentages show without trailing zeros', () {
    expect(KeyFacts.percent(0.0), '0%');
    expect(KeyFacts.percent(3.0), '3%');
    expect(KeyFacts.percent(18.5), '18.5%');
    expect(KeyFacts.percent(12.25), '12.25%');
  });

  test('only a 422 about the statement asks to read it again', () {
    const changed = AtomApiException(
      'The price of this product has changed to Rs. 47,000. Please read the updated Key Fact Statement and agree to it again.',
      statusCode: 422,
    );
    expect(isKeyFactsPriceChange(changed), isTrue);
    expect(isKeyFactsPriceChange(const AtomApiException('That installment tenure is not available.', statusCode: 422)), isFalse);
    expect(isKeyFactsPriceChange(const AtomApiException('Please read the Key Fact Statement', statusCode: 500)), isFalse);
    expect(isKeyFactsPriceChange(Exception('Key Fact Statement')), isFalse);
  });

  test('pay modes use the API names', () {
    expect(PayMode.values.map((m) => m.apiName), ['installment', 'atompay', 'cash']);
  });

  test('error messages drop the Exception prefix; network failures read plainly', () {
    expect(atomErrorMessage(Exception('That installment tenure is not available.')), 'That installment tenure is not available.');
    expect(atomErrorMessage(Exception('Network Error: connection refused')), 'You seem to be offline. Check your internet connection and try again.');
  });
}
