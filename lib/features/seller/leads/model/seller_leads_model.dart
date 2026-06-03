enum SellerLeadScope {
  mine('My Leads', 'Mine'),
  other('Other Leads', 'Other');

  final String label;
  final String shortLabel;

  const SellerLeadScope(this.label, this.shortLabel);
}

class SellerLeadsQuery {
  final SellerLeadScope scope;
  final int page;
  final String? status;

  const SellerLeadsQuery({
    this.scope = SellerLeadScope.mine,
    this.page = 1,
    this.status,
  });

  SellerLeadsQuery copyWith({
    SellerLeadScope? scope,
    int? page,
    String? status,
    bool clearStatus = false,
  }) {
    return SellerLeadsQuery(
      scope: scope ?? this.scope,
      page: page ?? this.page,
      status: clearStatus ? null : (status ?? this.status),
    );
  }

  Map<String, String> toQueryParameters() {
    final params = <String, String>{'page': page.toString()};
    final trimmed = status?.trim();
    if (trimmed != null && trimmed.isNotEmpty) params['status'] = trimmed;
    return params;
  }

  @override
  bool operator ==(Object other) {
    return other is SellerLeadsQuery &&
        other.scope == scope &&
        other.page == page &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(scope, page, status);
}

class SellerLeadsBundle {
  final SellerLeadsResponse leads;
  final Map<String, int> statusCounts;
  final int newLeadsCount;

  const SellerLeadsBundle({
    required this.leads,
    required this.statusCounts,
    required this.newLeadsCount,
  });
}

class SellerLeadsResponse {
  final List<SellerLead> leads;
  final SellerLeadsPagination pagination;

  const SellerLeadsResponse({required this.leads, required this.pagination});

  factory SellerLeadsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'])
        : <String, dynamic>{};
    return SellerLeadsResponse(
      leads: (data['data'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => SellerLead.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false),
      pagination: SellerLeadsPagination.fromJson(data),
    );
  }
}

class SellerLeadsPagination {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final int? from;
  final int? to;

  const SellerLeadsPagination({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    this.from,
    this.to,
  });

  bool get hasPrevious => currentPage > 1;
  bool get hasNext => currentPage < lastPage;

  factory SellerLeadsPagination.fromJson(Map<String, dynamic> json) {
    return SellerLeadsPagination(
      currentPage: _asInt(json['current_page'], fallback: 1),
      lastPage: _asInt(json['last_page'], fallback: 1),
      perPage: _asInt(json['per_page']),
      total: _asInt(json['total']),
      from: json['from'] == null ? null : _asInt(json['from']),
      to: json['to'] == null ? null : _asInt(json['to']),
    );
  }
}

class SellerLead {
  final int id;
  final String uuid;
  final String productTitle;
  final String fullName;
  final String phone;
  final bool availableOnWhatsapp;
  final String cityTitle;
  final int cityId;
  final String areaTitle;
  final int areaId;
  final String address;
  final String portal;
  final String reason;
  final int sellerId;
  final String status;
  final String type;
  final String featureImage;
  final String createdAt;
  final String updatedAt;

  const SellerLead({
    required this.id,
    required this.uuid,
    required this.productTitle,
    required this.fullName,
    required this.phone,
    required this.availableOnWhatsapp,
    required this.cityTitle,
    required this.cityId,
    required this.areaTitle,
    required this.areaId,
    required this.address,
    required this.portal,
    required this.reason,
    required this.sellerId,
    required this.status,
    required this.type,
    required this.featureImage,
    required this.createdAt,
    required this.updatedAt,
  });

  /// "Johar Town, Lahore" — either part omitted when unavailable
  String get location {
    final area = areaTitle == 'Not available' ? '' : areaTitle;
    final city = cityTitle == 'Not available' ? '' : cityTitle;
    if (area.isNotEmpty && city.isNotEmpty) return '$area, $city';
    return area.isNotEmpty ? area : city;
  }

  String get formattedCreatedAt => _date(createdAt);

  factory SellerLead.fromJson(Map<String, dynamic> json) {
    // city and area come as nested objects: {"id": 1, "title": "Lahore"}
    final cityObj = json['city'];
    final areaObj = json['area'];
    return SellerLead(
      id: _asInt(json['id']),
      uuid: _text(json['uuid']),
      productTitle: _text(json['product_title'], fallback: 'Product lead'),
      fullName: _text(json['full_name'], fallback: 'Lead'),
      phone: _text(json['phone']),
      availableOnWhatsapp: json['available_on_whatsapp']?.toString() == '1',
      cityTitle: cityObj is Map
          ? _text(cityObj['title'])
          : _text(cityObj),
      cityId: _asInt(json['city_id']),
      areaTitle: areaObj is Map
          ? _text(areaObj['title'])
          : _text(areaObj),
      areaId: _asInt(json['area_id']),
      address: _text(json['address']),
      portal: _text(json['portal']),
      reason: _text(json['reason']),
      sellerId: _asInt(json['seller_id']),
      status: _text(json['status'], fallback: 'New Lead'),
      type: _text(json['type']),
      featureImage: _text(json['feaure_image'] ?? json['feature_image']),
      createdAt: _text(json['created_at']),
      updatedAt: _text(json['updated_at']),
    );
  }
}

const sellerLeadStatuses = <String>[
  'New Lead',
  'Contacted',
  'Follow-up',
  'No Response',
  'Won',
  'Lost',
];

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

String _date(String value) {
  if (value.isEmpty || value == 'Not available') return 'N/A';
  try {
    final dt = DateTime.parse(value).toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  } catch (_) {
    return value.split('T').first;
  }
}
