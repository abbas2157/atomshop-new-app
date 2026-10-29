import 'package:atompro/data/atom_account.dart';
import 'package:atompro/data/atom_http.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers like the live `account/my-orders` and `payment-history`.
class _FakeHttp extends AtomHttp {
  @override
  Future<dynamic> post(String path, [Map<String, dynamic>? body]) async => switch (path) {
        'account/my-orders' => {
            'customer': {'city': 'Lahore', 'area': 'Johar Town', 'address': '12 Main Rd', 'verified': '1', 'cnic_no': '3520212345671'},
            'orders': [
              {
                'id': 41,
                'uuid': 'o-1',
                'status': 'Delivered',
                'total_deal_price': 130000,
                'advance_price': 30000,
                'tenure': 2,
                'created_at': '2026-09-01 10:00:00',
                'product': {'title': 'iPhone 16', 'price': 120000, 'picture': 'https://atomshop.pk/public/images/p.jpg'},
                'installments': [
                  {'id': 1, 'month': 'Advance', 'installment_price': 30000, 'installment_paid_price': 30000, 'installment_date': '2026-09-01', 'status': 'Paid', 'payment_method': 'Cash'},
                  {'id': 2, 'month': '1st Month', 'installment_price': 50000, 'installment_paid_price': 50000, 'installment_date': '2026-10-01', 'status': 'Paid', 'payment_method': 'Bank'},
                  {'id': 3, 'month': '2nd Month', 'installment_price': 50000, 'installment_paid_price': 0, 'installment_date': '2099-11-01', 'status': 'Unpaid', 'payment_method': null},
                ],
              },
              {
                'id': 2158,
                'uuid': 'o-3',
                'status': 'Pending',
                'total_deal_price': 473999,
                'advance_price': 0,
                'tenure': 3,
                'created_at': '2026-10-29 11:00:00',
                'product': {'title': 'Apple Iphone 17 Pro', 'price': 473999, 'picture': 'https://atomshop.pk/public/images/i.jpg'},
                // Made up by the server before delivery, with a markup that
                // disagrees with the total.
                'installments': [
                  {'id': null, 'month': '1st Month', 'installment_price': 176960, 'installment_paid_price': 0, 'installment_date': null, 'status': 'Unpaid', 'payment_method': null},
                  {'id': null, 'month': '2nd Month', 'installment_price': 176960, 'installment_paid_price': 0, 'installment_date': null, 'status': 'Unpaid', 'payment_method': null},
                  {'id': null, 'month': '3rd Month', 'installment_price': 176960, 'installment_paid_price': 0, 'installment_date': null, 'status': 'Unpaid', 'payment_method': null},
                ],
              },
              {
                'id': 42,
                'uuid': 'o-2',
                'status': 'Varification',
                'total_deal_price': 60000,
                'advance_price': 12000,
                'tenure': 6,
                'created_at': '2026-10-20 10:00:00',
                'product': {'title': 'Honda CD 70', 'price': 50000, 'picture': 'https://atomshop.pk/public'},
                'installments': [],
              },
            ],
          },
        'account/payment-history' => [
            {'id': 2, 'installment_price': '50,000', 'payment_date': 'Oct 01, 2026', 'payment_method': 'Bank', 'receipet': 'https://atomshop.pk/public/r/2.jpg', 'status': 'Paid'},
            {'id': 1, 'installment_price': '30,000', 'payment_date': 'Sep 01, 2026', 'payment_method': 'Cash', 'receipet': '-', 'status': 'Paid'},
          ],
        _ => throw AtomApiException('unexpected $path', statusCode: 404),
      };

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async =>
      path == 'notifications' ? {'notifications': {'data': [], 'current_page': 1, 'last_page': 1}, 'unread_count': 2} : throw AtomApiException('unexpected $path', statusCode: 404);
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({'token': 't-${DateTime.now().microsecondsSinceEpoch}', 'user_uuid': 'u-1', 'user_name': 'Mudassar'});
    AtomAccountApi.forgetOrders();
  });

  final api = AtomAccountApi(_FakeHttp());

  test('summary adds up the server installment rows', () async {
    final s = await api.summary();
    expect(s.orders, 3);
    expect(s.activePlans, 1);
    expect(s.paid, 80000);
    expect(s.unpaid, 50000);
    expect(s.nextDue?.amount, 50000);
    expect(s.unreadNotifications, 2);
    expect(s.cnicMasked, '35202-•••••••-1');
  });

  test('orders, tabs and custom orders', () async {
    expect((await api.orders()).orders.map((o) => o.uuid), ['o-3', 'o-2', 'o-1']);
    expect((await api.orders(status: 'completed')).orders, isEmpty);
    final card = (await api.orders(status: 'active')).orders.firstWhere((o) => o.uuid == 'o-1');
    expect(card.monthly, 50000);
    expect(card.paidMonths, 1);
    expect(card.outstanding, 50000);
    expect(card.statusLabel, 'Delivered');
    expect((await api.installments('pending')).plans.map((p) => p.statusLabel), ['Pending', 'Verification']);
    expect((await api.installments('active')).plans.single.uuid, 'o-1');
    expect((await api.customOrders()).single.product, 'Honda CD 70');
    expect((await api.order('o-1')).deliveryLine, '12 Main Rd, Johar Town, Lahore');
  });

  test('payments match their orders and receipts keep the office file', () async {
    final page = await api.payments();
    expect(page.paid, 80000);
    expect(page.advance, 30000);
    expect(page.payments.first.label, '1st Month');
    expect(page.payments.first.product, 'iPhone 16');
    final r = await api.receipt(2);
    expect(r.pdfUrl, 'https://atomshop.pk/public/r/2.jpg');
    expect((await api.receipt(1)).pdfUrl, isEmpty);
  });

  test('a schedule made up before delivery follows the order total', () async {
    final o = (await api.orders()).orders.firstWhere((o) => o.uuid == 'o-3');
    expect(o.schedule.map((r) => r.amount), [157999, 157999, 158001]);
    expect(o.outstanding, 473999);
    expect(o.monthly, 157999);
  });
}
