import 'package:atompro/data/atom_account.dart';
import 'package:atompro/data/atom_product_detail.dart';
import 'package:atompro/state/atom_app_version.dart';
import 'package:atompro/utils/atom_validators.dart';
import 'package:flutter_test/flutter_test.dart';

/// Update checks, shared form rules, Ask Atom answers and share links.
void main() {
  group('compareVersions', () {
    test('orders semantic versions', () {
      expect(compareVersions('1.9.9', '2.0.0'), lessThan(0));
      expect(compareVersions('2.0.0', '2.0.0'), 0);
      expect(compareVersions('2.1.0', '2.0.9'), greaterThan(0));
      expect(compareVersions('2.0', '2.0.0'), 0);
      expect(compareVersions('2.0.0+25', '2.0.0'), 0);
    });

    test('unknown versions never force an update', () {
      expect(compareVersions('2.0.0', ''), 0);
      expect(compareVersions('abc', '9.0.0'), 0);
    });
  });

  group('validators', () {
    test('names are letters and spaces only', () {
      expect(validatePersonName('Muhammad Ali'), isNull);
      expect(validatePersonName('M. Ali'), isNotNull);
      expect(validatePersonName('  '), isNotNull);
    });

    test('phones take 10 to 13 digits in any format', () {
      expect(validatePhone('0300 1234567'), isNull);
      expect(validatePhone('+92 300 1234567'), isNull);
      expect(validatePhone('12345'), isNotNull);
    });

    test('login is a phone or an email', () {
      expect(validateLogin('ali@example.com'), isNull);
      expect(validateLogin('03001234567'), isNull);
      expect(validateLogin('ali@'), isNotNull);
      expect(validateOptionalEmail(''), isNull);
      expect(validateNewPassword('short'), isNotNull);
    });
  });

  group('Ask Atom', () {
    test('reads the deployed answer shape', () {
      final r = AskAtomReply.fromJson({
        'answer': '<p>Hi</p>',
        'text': 'Sellers on Atomshop offer the **iPhone 16**.',
        'actions': [
          {'label': 'Chat on WhatsApp', 'url': 'https://wa.me/923331214955'},
          {'label': 'Custom order', 'url': 'https://atomshop.pk/custom-order-calculator'},
          {'label': 'Phones', 'url': 'https://atomshop.pk/category/mobile-phone'},
          {'label': 'iPhone 16', 'url': 'https://atomshop.pk/iphone-16'},
        ],
        'related': {'title': 'Related questions', 'questions': ['What documents do I need?']},
        'session': 'abc.def',
      });

      expect(r.answer, contains('**iPhone 16**'));
      expect(r.actions.map((a) => a.type), ['whatsapp', 'custom_order', 'category', 'url']);
      expect(r.actions[2].id, 1);
      expect(r.related, ['What documents do I need?']);
      expect(r.session, 'abc.def');
    });

    test('falls back to the HTML answer without tags', () {
      expect(AskAtomReply.fromJson({'answer': '<p>Hello</p>'}).answer, 'Hello');
    });
  });

  test('product share link comes from url, else slug', () {
    Map<String, dynamic> base(Map<String, dynamic> extra) => {'id': 1, 'title': 'Galaxy A56', 'plan': <String, dynamic>{}, ...extra};

    expect(ProductDetail.fromJson(base({'url': 'https://atomshop.pk/galaxy-a56'})).webUrl, 'https://atomshop.pk/galaxy-a56');
    expect(ProductDetail.fromJson(base({'slug': 'galaxy-a56'})).webUrl, 'https://atomshop.pk/galaxy-a56');
    expect(ProductDetail.fromJson(base({})).webUrl, isEmpty);
  });
}
