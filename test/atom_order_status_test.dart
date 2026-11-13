import 'package:atompro/data/atom_account.dart';
import 'package:atompro/data/atom_http.dart';
import 'package:atompro/widgets/atom_surfaces.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _order(String uuid, String status, {required bool allPaid}) => {
      'id': uuid.hashCode,
      'uuid': uuid,
      'status': status,
      'total_deal_price': 100000,
      'advance_price': 20000,
      'tenure': 1,
      'created_at': '2026-09-01 10:00:00',
      'product': {'title': 'Phone $uuid', 'price': 90000, 'picture': 'https://atomshop.pk/public/images/p.jpg'},
      'installments': [
        {'id': 1, 'month': 'Advance', 'installment_price': 20000, 'installment_paid_price': 20000, 'installment_date': '2026-09-01', 'status': 'Paid'},
        {
          'id': 2,
          'month': '1st Month',
          'installment_price': 80000,
          'installment_paid_price': allPaid ? 80000 : 0,
          'installment_date': '2099-10-01',
          'status': allPaid ? 'Paid' : 'Unpaid',
        },
      ],
    };

class _FakeHttp extends AtomHttp {
  @override
  Future<dynamic> post(String path, [Map<String, dynamic>? body]) async => switch (path) {
        'account/my-orders' => {
            'customer': const <String, dynamic>{},
            'orders': [
              _order('paying', 'Installments', allPaid: false),
              // Every installment paid, the server not yet saying Completed.
              _order('settled', 'Installments', allPaid: true),
              _order('rejected', 'rejected', allPaid: false),
              _order('canceled', 'canceled', allPaid: false),
            ],
          },
        _ => throw AtomApiException('unexpected $path', statusCode: 404),
      };
}

void main() {
  test('OrderStatus reads every spelling the API uses', () {
    expect(OrderStatus.parse('Varification'), OrderStatus.verification);
    expect(OrderStatus.parse('Instalments'), OrderStatus.installments);
    expect(OrderStatus.parse('canceled'), OrderStatus.cancelled);
    expect(OrderStatus.parse(' Cancelled '), OrderStatus.cancelled);
    expect(OrderStatus.parse('On hold'), OrderStatus.unknown);
    expect(OrderStatus.rejected.isCancelled, isTrue);
    expect(OrderStatus.verification.isPending, isTrue);
    expect(OrderStatus.delivered.isClosed, isFalse);
  });

  group('orders and installments agree', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({'token': 't-${DateTime.now().microsecondsSinceEpoch}', 'user_uuid': 'u-1'});
      AtomAccountApi.forgetOrders();
    });

    final api = AtomAccountApi(_FakeHttp());

    test('a fully paid plan is finished on both screens', () async {
      final active = (await api.orders(status: 'active')).orders.map((o) => o.uuid);
      final done = (await api.orders(status: 'completed')).orders.map((o) => o.uuid);
      expect(active, ['paying']);
      expect(done, ['settled']);
      expect((await api.installments('active')).plans.map((p) => p.uuid), ['paying']);
      expect((await api.installments('completed')).plans.map((p) => p.uuid), ['settled']);
    });

    test('rejected and canceled orders count as cancelled', () async {
      final all = (await api.orders()).orders;
      expect(all.where((o) => o.state.isCancelled).map((o) => o.uuid).toSet(), {'rejected', 'canceled'});
    });
  });

  testWidgets('a rejected order gets the cancelled colour, an unknown status its own text', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Column(children: [AtomBadge.orderStatus('rejected'), AtomBadge.orderStatus('On hold')])));
    expect(find.text('Rejected'), findsOneWidget);
    expect(find.text('On hold'), findsOneWidget);
    final rejected = tester.widget<AtomBadge>(find.byType(AtomBadge).first);
    expect(rejected.tone, AtomTone.rose);
  });
}
