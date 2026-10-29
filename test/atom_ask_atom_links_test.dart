import 'package:atompro/data/atom_account.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ask Atom's website links open app screens, not the browser.
void main() {
  AskAtomAction link(String url) => AskAtomAction.fromJson({'label': 'x', 'url': url});

  test('website pages the app has stay in the app', () {
    expect(link('https://atomshop.pk/shop?atompay=1').type, 'shop');
    expect(link('https://atomshop.pk/installment-calculator').type, 'shop');
    expect(link('https://atomshop.pk/faqs').type, 'faqs');
    expect(link('https://atomshop.pk/custom-order-calculator').type, 'custom_order');
    expect(link('https://atomshop.pk/make-offer').type, 'offer');
    expect(link('https://wa.me/923331214955').type, 'whatsapp');
  });

  test('a product link searches the app for it by name', () {
    final a = link('https://atomshop.pk/apple-iphone-17-pro');
    expect(a.type, 'search');
    expect(a.searchText, 'apple iphone 17 pro');
  });

  test('other sites and website-only pages open in the browser', () {
    expect(link('https://atompay.shop').type, 'url');
    expect(link('https://atomshop.pk/smart-seller').type, 'url');
  });
}
