import 'package:atompro/data/atom_site_pages.dart';
import 'package:flutter_test/flutter_test.dart';

/// The website's policy and FAQ text bundled for when the server page is missing.
void main() {
  test('privacy and terms are one document, as on the website', () {
    final privacy = atomSitePage('privacy')!;
    expect(atomSitePage('terms'), same(privacy));
    expect(privacy.sections.length, 10);
    expect(privacy.sections.first.heading, 'Acceptance of terms');
  });

  test('returns has every clause', () {
    expect(atomSitePage('refund')!.sections.map((s) => s.heading), contains('No exchanges & cancellations'));
  });

  test('FAQs keep the website groups and use the server AtomPay fee', () {
    final faqs = atomSitePage('faqs', atompayFeePercent: 4)!;
    expect(faqs.faqGroups.map((g) => g.title), ['Shopping', 'Payments & plans', 'AtomPay', 'Delivery & returns', 'Partners']);
    expect(faqs.faqGroups.fold<int>(0, (n, g) => n + g.items.length), 29);
    final markup = faqs.faqGroups[2].items.firstWhere((i) => i.$1 == 'Is there a markup with AtomPay?').$2;
    expect(markup, contains('A 4% processing fee'));
  });

  test('unknown pages have no bundled copy', () {
    expect(atomSitePage('about'), isNull);
  });
}
