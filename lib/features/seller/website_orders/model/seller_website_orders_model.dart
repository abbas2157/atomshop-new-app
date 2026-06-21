import 'package:atompro/core/seller_plan_upgrade_exception.dart';

class SellerWebsiteOrdersQuery {
  final String? search;
  final int page;

  const SellerWebsiteOrdersQuery({this.search, this.page = 1});

  SellerWebsiteOrdersQuery copyWith({
    String? search,
    int? page,
    bool clearSearch = false,
  }) {
    return SellerWebsiteOrdersQuery(
      search: clearSearch ? null : (search ?? this.search),
      page: page ?? this.page,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SellerWebsiteOrdersQuery &&
      other.search == search &&
      other.page == page;

  @override
  int get hashCode => Object.hash(search, page);
}

class SellerWebsiteOrdersResponse {
  final List<SellerWebsiteOrder> orders;
  final SellerWebsiteOrdersPagination pagination;
  final Map<String, int> statuses;

  /// Non-null when the seller's plan doesn't include website orders. Carried as
  /// DATA (not a thrown error) so the provider settles into a stable AsyncData
  /// state — an AsyncError state was re-run on every rebuild, causing an
  /// infinite refetch loop. The screen renders the plan gate from this field.
  final SellerPlanUpgradeException? gate;

  const SellerWebsiteOrdersResponse({
    required this.orders,
    required this.pagination,
    this.statuses = const {},
    this.gate,
  });

  /// Empty response that carries the plan-gate exception as data.
  factory SellerWebsiteOrdersResponse.gated(SellerPlanUpgradeException gate) {
    return SellerWebsiteOrdersResponse(
      orders: const [],
      pagination: const SellerWebsiteOrdersPagination(
        currentPage: 1,
        lastPage: 1,
        total: 0,
      ),
      gate: gate,
    );
  }

  factory SellerWebsiteOrdersResponse.fromResponse(
    Map<String, dynamic> response,
  ) {
    final data = response['data'] is Map
        ? Map<String, dynamic>.from(response['data'])
        : <String, dynamic>{};
    final rawStatuses = data['statuses'] as Map? ?? const {};
    return SellerWebsiteOrdersResponse(
      orders: (data['data'] as List? ?? [])
          .whereType<Map>()
          .map((e) => SellerWebsiteOrder.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false),
      pagination: SellerWebsiteOrdersPagination.fromJson(data),
      statuses: rawStatuses.map(
        (k, v) => MapEntry(k.toString(), _asInt(v)),
      ),
    );
  }
}

class SellerWebsiteOrdersPagination {
  final int currentPage;
  final int lastPage;
  final int total;

  const SellerWebsiteOrdersPagination({
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  bool get hasPrevious => currentPage > 1;
  bool get hasNext => currentPage < lastPage;

  factory SellerWebsiteOrdersPagination.fromJson(Map<String, dynamic> json) {
    return SellerWebsiteOrdersPagination(
      currentPage: _asInt(json['current_page'], fallback: 1),
      lastPage: _asInt(json['last_page'], fallback: 1),
      total: _asInt(json['total']),
    );
  }
}

class SellerWebsiteOrder {
  final int id;
  final String uuid;
  final int totalDealPrice;
  final int advancePrice;
  final int tenure;
  final String status;
  final String createdAt;
  final String productTitle;
  final String productPrNumber;
  final String categoryTitle;
  final String brandTitle;
  final String customerName;
  final String customerPhone;
  final String cityTitle;
  final String areaTitle;
  final String portal;

  const SellerWebsiteOrder({
    required this.id,
    required this.uuid,
    required this.totalDealPrice,
    required this.advancePrice,
    required this.tenure,
    required this.status,
    required this.createdAt,
    required this.productTitle,
    required this.productPrNumber,
    required this.categoryTitle,
    required this.brandTitle,
    required this.customerName,
    required this.customerPhone,
    required this.cityTitle,
    required this.areaTitle,
    this.portal = 'Web',
  });

  String get formattedTotalDealPrice => _formatRs(totalDealPrice);
  String get formattedAdvancePrice => _formatRs(advancePrice);

  static String _formatRs(int amount) {
    if (amount == 0) return 'Rs 0';
    final s = amount.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return 'Rs $buf';
  }

  String get formattedDate {
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return createdAt.split('T').first;
    }
  }

  factory SellerWebsiteOrder.fromJson(Map<String, dynamic> json) {
    final product = (json['custom_order_product'] ?? json['CustomOrderProduct']) is Map
        ? Map<String, dynamic>.from(
            (json['custom_order_product'] ?? json['CustomOrderProduct']) as Map)
        : <String, dynamic>{};
    final category = product['category'] is Map
        ? Map<String, dynamic>.from(product['category'])
        : <String, dynamic>{};
    final brand = product['brand'] is Map
        ? Map<String, dynamic>.from(product['brand'])
        : <String, dynamic>{};
    final user = json['user'] is Map
        ? Map<String, dynamic>.from(json['user'])
        : <String, dynamic>{};
    final city = json['city'] is Map
        ? Map<String, dynamic>.from(json['city'])
        : <String, dynamic>{};
    final area = json['area'] is Map
        ? Map<String, dynamic>.from(json['area'])
        : <String, dynamic>{};

    return SellerWebsiteOrder(
      id: _asInt(json['id']),
      uuid: _text(json['uuid']),
      totalDealPrice: _asInt(json['total_deal_price']),
      advancePrice: _asInt(json['advance_price']),
      tenure: _asInt(json['tenure']),
      status: _text(json['status'], fallback: 'Pending'),
      createdAt: _text(json['created_at'], fallback: ''),
      productTitle: _text(product['title'], fallback: 'Product'),
      productPrNumber: _text(product['pr_number']),
      categoryTitle: _text(category['title'], fallback: ''),
      brandTitle: _text(brand['title'], fallback: ''),
      customerName: _text(user['name'], fallback: 'Customer'),
      customerPhone: _text(user['phone']),
      cityTitle: _text(city['title'], fallback: ''),
      areaTitle: _text(area['title'], fallback: ''),
      portal: _text(json['portal'], fallback: 'Web'),
    );
  }
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

String _text(dynamic value, {String fallback = 'Not available'}) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty || text == 'null') return fallback;
  return text;
}
