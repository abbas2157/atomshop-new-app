import '../utils/atom_format.dart';

/// Plain immutable models for app v2. Parsing is defensive: the API mixes
/// numbers and formatted strings, and older snapshot rows can miss fields.

int _int(Object? v, [int fallback = 0]) => AtomFormat.parseAmount(v) ?? fallback;
String _str(Object? v) => v?.toString() ?? '';

List<Map<String, dynamic>> atomList(Object? data) =>
    data is List ? data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(growable: false) : const [];

/// A product as shown on a card (home rows, shop grid, brand page).
class ProductCard {
  const ProductCard({
    required this.id,
    required this.title,
    required this.picture,
    required this.brand,
    required this.category,
    required this.cashPrice,
    required this.monthlyFrom,
    required this.atompay,
    this.inStock = true,
  });

  final int id;
  final String title;
  final String picture;
  final String brand;
  final String category;
  final int? cashPrice;

  /// "From Rs. X/mo", worked out on the server (12 months, 20% advance).
  final int? monthlyFrom;
  final bool atompay;

  /// False for a sold-out product (shop lists include them, marked).
  final bool inStock;

  factory ProductCard.fromJson(Map<String, dynamic> j) => ProductCard(
        id: _int(j['id']),
        title: _str(j['title']),
        picture: _str(j['picture']),
        brand: _str(j['brand']),
        category: _str(j['category']),
        cashPrice: j['cash_price'] == null ? null : _int(j['cash_price']),
        monthlyFrom: j['monthly_from'] == null ? null : _int(j['monthly_from']),
        atompay: j['atompay'] == true,
        inStock: j['in_stock'] != false,
      );
}

/// Category or brand tile (both come from the admin's App setup lists).
class CatalogueItem {
  const CatalogueItem({required this.id, required this.title, required this.slug, required this.picture, this.productCount});

  final int id;
  final String title;
  final String slug;
  final String picture;
  final int? productCount;

  factory CatalogueItem.fromJson(Map<String, dynamic> j) => CatalogueItem(
        id: _int(j['id']),
        title: _str(j['title']),
        slug: _str(j['slug']),
        picture: _str(j['picture'] ?? j['category_picture'] ?? j['brand_picture']),
        productCount: j['pr_count'] == null ? null : _int(j['pr_count']),
      );
}

/// Home banner slide (admin → App setup → Sliders).
class HomeSlide {
  const HomeSlide({required this.id, required this.title, required this.tagline, required this.picture});

  final int id;
  final String title;
  final String tagline;
  final String picture;

  factory HomeSlide.fromJson(Map<String, dynamic> j) =>
      HomeSlide(id: _int(j['id']), title: _str(j['title']), tagline: _str(j['tagline']), picture: _str(j['picture']));
}

/// Public settings from GET api/app/config. Never hard-code these in the app.
class AppConfig {
  const AppConfig({
    required this.phone,
    required this.whatsapp,
    required this.whatsappUrl,
    required this.email,
    required this.officeAddress,
    required this.deliveryArea,
    required this.social,
    required this.storeLinks,
    required this.minAdvancePercent,
    required this.maxAdvancePercent,
    required this.advanceOptions,
    required this.months,
    required this.markupPercent,
    required this.atompayMonths,
    required this.atompayFeePercent,
    required this.latestVersion,
    required this.minVersion,
    this.pages = const {},
    this.maintenance = false,
    this.maintenanceMessage = '',
    this.maintenanceUntil,
  });

  final String phone;
  final String whatsapp;
  final String whatsappUrl;
  final String email;
  final String officeAddress;
  final String deliveryArea;

  /// facebook / instagram / tiktok → url (missing ones are left out).
  final Map<String, String> social;

  /// e.g. storeLinks['atombrand']?['android'].
  final Map<String, Map<String, String?>> storeLinks;
  final int minAdvancePercent;
  final int maxAdvancePercent;
  final List<int> advanceOptions;

  /// The months checkout accepts (the admin calculator's list).
  final List<int> months;
  final double markupPercent;
  final int atompayMonths;
  final num atompayFeePercent;
  final String latestVersion;
  final String minVersion;

  /// Content page slug → its page on the website (fallback links).
  final Map<String, String> pages;

  /// The server is in maintenance: the app shows only the maintenance
  /// screen (backend prompt: `maintenance {enabled, message, until}`).
  final bool maintenance;
  final String maintenanceMessage;

  /// When maintenance should end, only if the server says.
  final DateTime? maintenanceUntil;

  factory AppConfig.fromJson(Map<String, dynamic> j) {
    final contact = Map<String, dynamic>.from(j['contact'] as Map? ?? const {});
    final plans = Map<String, dynamic>.from(j['plans'] as Map? ?? const {});
    final atompay = Map<String, dynamic>.from(j['atompay'] as Map? ?? const {});
    final version = Map<String, dynamic>.from(j['version'] as Map? ?? const {});
    final social = <String, String>{};
    (j['social'] as Map? ?? const {}).forEach((k, v) {
      if (v != null && v.toString().isNotEmpty) social[k.toString()] = v.toString();
    });
    final stores = <String, Map<String, String?>>{};
    (j['apps'] as Map? ?? const {}).forEach((k, v) {
      final m = v as Map? ?? const {};
      stores[k.toString()] = {'android': m['android']?.toString(), 'ios': m['ios']?.toString()};
    });

    return AppConfig(
      phone: _str(contact['phone']),
      whatsapp: _str(contact['whatsapp']),
      whatsappUrl: _str(contact['whatsapp_url']),
      email: _str(contact['email']),
      officeAddress: _str(contact['office_address']),
      deliveryArea: _str(j['delivery_area']),
      social: social,
      storeLinks: stores,
      minAdvancePercent: _int(plans['min_advance_percent'], 20),
      maxAdvancePercent: _int(plans['max_advance_percent'], 60),
      advanceOptions: (plans['advance_options'] as List? ?? const [20, 30, 40, 50]).map((e) => _int(e)).toList(growable: false),
      months: (plans['months'] as List? ?? const [3, 6, 9, 12]).map((e) => _int(e)).toList(growable: false),
      markupPercent: (plans['markup_percent'] as num?)?.toDouble() ?? 4,
      atompayMonths: _int(atompay['months'], 3),
      atompayFeePercent: (atompay['processing_fee_percent'] as num?) ?? 3,
      latestVersion: _str(version['latest']),
      minVersion: _str(version['min']),
      maintenance: (j['maintenance'] as Map?)?['enabled'] == true,
      maintenanceMessage: _str((j['maintenance'] as Map?)?['message']),
      maintenanceUntil: DateTime.tryParse(_str((j['maintenance'] as Map?)?['until'])),
      pages: {
        for (final e in (j['pages'] as Map? ?? const {}).entries)
          if (e.value != null && e.value.toString().isNotEmpty) e.key.toString(): e.value.toString(),
      },
    );
  }
}
