import 'package:atompro/data/atom_models.dart';
import 'package:atompro/responsive/atom_responsive.dart';
import 'package:atompro/utils/atom_format.dart';
import 'package:flutter_test/flutter_test.dart';

/// Unit tests for the app v2 foundation: formatting, defensive parsing of the
/// API shapes, and the responsive grid maths.
void main() {
  group('AtomFormat', () {
    test('rupees use thousands separators and no decimals', () {
      expect(AtomFormat.rupees(119999), 'Rs. 119,999');
      expect(AtomFormat.rupees(1984.6), 'Rs. 1,985');
      expect(AtomFormat.rupees(0), 'Rs. 0');
      expect(AtomFormat.rupees(null), 'Rs. —');
    });

    test('dates are d M Y', () {
      expect(AtomFormat.date(DateTime(2026, 11, 5)), '05 Nov 2026');
    });

    test('parses amounts sent as formatted strings or numbers', () {
      expect(AtomFormat.parseAmount('80,000'), 80000);
      expect(AtomFormat.parseAmount(39467), 39467);
      expect(AtomFormat.parseAmount(''), isNull);
      expect(AtomFormat.parseAmount(null), isNull);
    });
  });

  group('models', () {
    test('ProductCard reads the app v2 plan fields', () {
      final p = ProductCard.fromJson({
        'id': 139,
        'title': 'MacBook Air',
        'price': '80,000',
        'picture': 'https://atomshop.pk/x.webp',
        'brand': 'Apple',
        'category': 'Laptops',
        'cash_price': 399999,
        'monthly_from': 39467,
        'atompay': false,
      });
      expect(p.id, 139);
      expect(p.cashPrice, 399999);
      expect(p.monthlyFrom, 39467);
      expect(p.atompay, isFalse);
    });

    test('ProductCard tolerates rows from before the plan fields existed', () {
      final p = ProductCard.fromJson({'id': '7', 'title': 'Old row'});
      expect(p.id, 7);
      expect(p.monthlyFrom, isNull);
      expect(p.atompay, isFalse);
    });

    test('AppConfig keeps only filled social links and parses plans', () {
      final c = AppConfig.fromJson({
        'contact': {'phone': '+923302277522', 'whatsapp': '+923331214955', 'whatsapp_url': 'https://wa.me/923331214955'},
        'social': {'facebook': 'https://facebook.com/atomshoppk', 'tiktok': null},
        'apps': {'atombrand': {'android': null, 'ios': null}},
        'plans': {'min_advance_percent': 20, 'max_advance_percent': 60, 'advance_options': [20, 30, 40, 50], 'months': [3, 6, 12], 'markup_percent': 4},
        'atompay': {'months': 3, 'processing_fee_percent': 3},
        'version': {'latest': '2.0.0', 'min': '1.5.0'},
      });
      expect(c.social.keys, ['facebook']);
      expect(c.months, [3, 6, 12]);
      expect(c.maxAdvancePercent, 60);
      expect(c.advanceOptions, [20, 30, 40, 50]);
      expect(c.markupPercent, 4.0);
      expect(c.minVersion, '1.5.0');
      expect(c.storeLinks['atombrand']?['android'], isNull);
    });

    test('atomList ignores non-list data', () {
      expect(atomList(null), isEmpty);
      expect(atomList({'a': 1}), isEmpty);
      expect(atomList([{'id': 1}, 'x']).length, 1);
    });
  });

  group('responsive grid', () {
    test('two columns on phones, more on tablets, capped', () {
      expect(atomGridColumns(350), 2);
      expect(atomGridColumns(700), 4);
      expect(atomGridColumns(2000), 6);
      expect(atomGridColumns(200), 2, reason: 'never fewer than two');
    });
  });
}
