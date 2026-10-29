import '../utils/atom_format.dart';
import 'atom_models.dart';

/// Product page data from GET api/products/{id}.
///
/// Every money figure comes from the server's `plan` block (the website's
/// InstallmentPlanService). The app only looks figures up; it never works out
/// markup, advance or monthly amounts itself.

int _int(Object? v, [int fallback = 0]) => AtomFormat.parseAmount(v) ?? fallback;
int? _intOrNull(Object? v) => v == null ? null : AtomFormat.parseAmount(v);
String _str(Object? v) => v?.toString() ?? '';
Map<String, dynamic> _map(Object? v) => v is Map ? Map<String, dynamic>.from(v) : const {};

/// Thrown when the API answers "Product not found." (it does so with a 200).
class ProductNotFound implements Exception {
  const ProductNotFound(this.id);

  final int id;

  @override
  String toString() => 'Product $id is not available.';
}

/// Storage option ("memories" in the API). [price] is the full cash price
/// for this storage, and the key into [ProductPlan.quotes].
class StorageOption {
  const StorageOption({required this.id, required this.title, required this.price});

  final int id;
  final String title;
  final int price;

  factory StorageOption.fromJson(Map<String, dynamic> j) =>
      StorageOption(id: _int(j['id']), title: _str(j['title']), price: _int(j['variation_price']));
}

/// Colour option. The API sends a name only, so the app shows text chips.
class ColourOption {
  const ColourOption({required this.id, required this.title});

  final int id;
  final String title;

  factory ColourOption.fromJson(Map<String, dynamic> j) => ColourOption(id: _int(j['id']), title: _str(j['title']));
}

/// One row of the server's plan table: a price at an advance % over a number
/// of months.
class PlanQuote {
  const PlanQuote({
    required this.advancePercent,
    required this.months,
    required this.advance,
    required this.financed,
    required this.monthly,
    required this.total,
  });

  final int advancePercent;
  final int months;
  final int advance;
  final int financed;
  final int monthly;
  final int total;

  factory PlanQuote.fromJson(Map<String, dynamic> j) => PlanQuote(
        advancePercent: _int(j['advance_percent']),
        months: _int(j['months']),
        advance: _int(j['advance']),
        financed: _int(j['financed']),
        monthly: _int(j['monthly']),
        total: _int(j['total']),
      );
}

/// AtomPay for one price: no advance, 0% markup. The last month takes the
/// rounding, so the months add up to [total].
class AtompayQuote {
  const AtompayQuote({required this.months, required this.monthly, required this.lastMonthly, required this.total, required this.processingFee});

  final int months;
  final int monthly;
  final int lastMonthly;
  final int total;

  /// Shown next to the plan; not part of [total].
  final int processingFee;

  factory AtompayQuote.fromJson(Map<String, dynamic> j) => AtompayQuote(
        months: _int(j['months']),
        monthly: _int(j['monthly']),
        lastMonthly: _int(j['last_monthly'], _int(j['monthly'])),
        total: _int(j['total']),
        processingFee: _int(j['processing_fee']),
      );
}

/// The `plan` block of the product page.
class ProductPlan {
  const ProductPlan({
    required this.cashPrice,
    required this.monthlyFrom,
    required this.atompay,
    required this.minAdvancePercent,
    required this.maxAdvancePercent,
    required this.months,
    required this.advanceOptions,
    required this.markupPercent,
    required this.quotes,
    required this.atompayQuotes,
  });

  /// Base cash price of the product.
  final int cashPrice;
  final int? monthlyFrom;
  final bool atompay;
  final int minAdvancePercent;
  final int maxAdvancePercent;

  /// The months checkout accepts (the admin calculator's list).
  final List<int> months;
  final List<int> advanceOptions;
  final double markupPercent;

  /// Price (base and each storage) → every advance × months row for it.
  final Map<int, List<PlanQuote>> quotes;

  /// Price (base and each storage) → AtomPay figures; empty when the
  /// product is not AtomPay-eligible.
  final Map<int, AtompayQuote> atompayQuotes;

  /// Advance choices inside the band checkout accepts.
  List<int> get advanceChoices =>
      advanceOptions.where((a) => a >= minAdvancePercent && a <= maxAdvancePercent).toList(growable: false);

  AtompayQuote? atompayFor(int price) => atompayQuotes[price];

  /// The row for [price] at [advancePercent] over [months], or null when the
  /// server did not quote it.
  PlanQuote? quote({required int price, required int advancePercent, required int months}) {
    for (final q in quotes[price] ?? const <PlanQuote>[]) {
      if (q.advancePercent == advancePercent && q.months == months) return q;
    }
    return null;
  }

  factory ProductPlan.fromJson(Map<String, dynamic> j) {
    // Both are maps keyed by price; an empty collection arrives as [] and
    // atompay_quotes is null for products that are not eligible.
    Map<int, T> byPrice<T>(Object? raw, T Function(Object? value) parse) {
      final out = <int, T>{};
      if (raw is Map) {
        raw.forEach((price, value) {
          final key = AtomFormat.parseAmount(price);
          if (key != null) out[key] = parse(value);
        });
      }
      return out;
    }
    List<int> ints(Object? v, List<int> fallback) => v is List ? v.map((e) => _int(e)).toList(growable: false) : fallback;

    return ProductPlan(
      cashPrice: _int(j['cash_price']),
      monthlyFrom: _intOrNull(j['monthly_from']),
      atompay: j['atompay'] == true,
      minAdvancePercent: _int(j['min_advance_percent'], 20),
      maxAdvancePercent: _int(j['max_advance_percent'], 60),
      months: ints(j['months'], const []),
      advanceOptions: ints(j['advance_options'], const []),
      markupPercent: (j['markup_percent'] as num?)?.toDouble() ?? 0,
      quotes: byPrice(j['quotes'], (rows) => atomList(rows).map(PlanQuote.fromJson).toList(growable: false)),
      atompayQuotes: byPrice(j['atompay_quotes'], (v) => AtompayQuote.fromJson(_map(v))),
    );
  }
}

class ProductDetail {
  const ProductDetail({
    required this.id,
    required this.title,
    required this.picture,
    required this.gallery,
    required this.category,
    required this.brand,
    required this.storages,
    required this.colours,
    required this.shortDescription,
    required this.longDescription,
    required this.plan,
    this.webUrl = '',
    this.inStock = true,
  });

  final int id;
  final String title;

  /// The product's page on the website (for sharing), or empty when the
  /// server sends neither `url` nor `slug`.
  final String webUrl;
  final String picture;

  /// Main picture first, then gallery pictures, without repeats.
  final List<String> gallery;
  final CatalogueItem? category;
  final CatalogueItem? brand;
  final List<StorageOption> storages;
  final List<ColourOption> colours;
  final String shortDescription;
  final String longDescription;
  final ProductPlan plan;

  /// False when sold out ("Out of Stock"): the page opens but cannot order.
  final bool inStock;

  /// Cash price for the chosen storage (or the base price without storages).
  int priceFor(StorageOption? storage) => storage?.price ?? plan.cashPrice;

  factory ProductDetail.fromJson(Map<String, dynamic> j) {
    final id = _int(j['id']);
    final title = _str(j['title']).trim();
    if (title.isEmpty) throw ProductNotFound(id);

    final picture = _str(j['picture']);
    final pictures = <String>[
      if (picture.isNotEmpty) picture,
      for (final g in atomList(j['gallery'])) _str(g['url']),
    ].where((u) => u.isNotEmpty).toSet().toList(growable: false);

    CatalogueItem? item(Object? v) {
      final m = _map(v);
      return m.isEmpty ? null : CatalogueItem.fromJson(m);
    }

    return ProductDetail(
      id: id,
      title: title,
      picture: picture,
      gallery: pictures,
      category: item(j['category']),
      brand: item(j['brand']),
      storages: atomList(j['memories']).map(StorageOption.fromJson).where((s) => s.price > 0).toList(growable: false),
      colours: atomList(j['colors']).map(ColourOption.fromJson).toList(growable: false),
      shortDescription: _plainText(_str(j['short_description'])),
      longDescription: _plainText(_str(j['long_description'])),
      plan: ProductPlan.fromJson(_map(j['plan'])),
      webUrl: _webUrl(j),
      inStock: j['in_stock'] != false && _str(j['status']) != 'Out of Stock',
    );
  }

  static String _webUrl(Map<String, dynamic> j) {
    final url = _str(j['url']);
    if (url.startsWith('http')) return url;
    final slug = _str(j['slug']).trim();
    return slug.isEmpty ? '' : 'https://atomshop.pk/$slug';
  }
}

enum PayMode { installment, atompay, cash }

/// What the customer picked on the product page, handed to the order screen.
class ProductOrderChoice {
  const ProductOrderChoice({
    required this.product,
    required this.mode,
    required this.price,
    this.storage,
    this.colour,
    this.quote,
    this.atompay,
  });

  final ProductDetail product;
  final PayMode mode;
  final int price;
  final StorageOption? storage;
  final ColourOption? colour;

  /// Set for [PayMode.installment].
  final PlanQuote? quote;

  /// Set for [PayMode.atompay].
  final AtompayQuote? atompay;
}

/// Admin-typed description as plain text: HTML tags dropped, entities such
/// as `&amp;` decoded, Windows line breaks and runs of blank lines tidied.
String _plainText(String raw) {
  const entities = {
    '&amp;': '&',
    '&nbsp;': ' ',
    '&quot;': '"',
    '&#39;': "'",
    '&apos;': "'",
    '&lt;': '<',
    '&gt;': '>',
    '&ndash;': '–',
    '&mdash;': '—',
    '&rsquo;': '’',
    '&lsquo;': '‘',
    '&rdquo;': '”',
    '&ldquo;': '“',
  };
  var t = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  t = t
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</(p|div|li|h\d)>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '');
  for (final e in entities.entries) {
    t = t.replaceAll(e.key, e.value);
  }
  t = t.replaceAllMapped(RegExp(r'&#(\d+);'), (m) => String.fromCharCode(int.parse(m.group(1)!)));
  return t.replaceAll(RegExp(r'[ \t]+\n'), '\n').replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
}
