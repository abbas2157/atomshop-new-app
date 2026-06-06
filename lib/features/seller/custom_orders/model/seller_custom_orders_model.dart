import 'dart:convert';

class SellerCustomOrdersQuery {
  final int page;
  final String? status;
  final String? keyword;
  final String? minPrice;
  final String? maxPrice;
  final String? startDate;
  final String? endDate;

  const SellerCustomOrdersQuery({
    this.page = 1,
    this.status,
    this.keyword,
    this.minPrice,
    this.maxPrice,
    this.startDate,
    this.endDate,
  });

  SellerCustomOrdersQuery copyWith({
    int? page,
    String? status,
    String? keyword,
    String? minPrice,
    String? maxPrice,
    String? startDate,
    String? endDate,
    bool clearStatus = false,
    bool clearKeyword = false,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
    bool clearStartDate = false,
    bool clearEndDate = false,
  }) {
    return SellerCustomOrdersQuery(
      page: page ?? this.page,
      status: clearStatus ? null : (status ?? this.status),
      keyword: clearKeyword ? null : (keyword ?? this.keyword),
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
    );
  }

  Map<String, String> toQueryParameters() {
    final params = <String, String>{'page': page.toString()};
    void add(String key, String? value) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) params[key] = trimmed;
    }

    add('status', status);
    add('keyword', keyword);
    add('min_price', minPrice);
    add('max_price', maxPrice);
    add('start_date', startDate);
    add('end_date', endDate);
    return params;
  }

  @override
  bool operator ==(Object other) {
    return other is SellerCustomOrdersQuery &&
        other.page == page &&
        other.status == status &&
        other.keyword == keyword &&
        other.minPrice == minPrice &&
        other.maxPrice == maxPrice &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode => Object.hash(
    page,
    status,
    keyword,
    minPrice,
    maxPrice,
    startDate,
    endDate,
  );
}

class SellerCustomOrdersResponse {
  final List<SellerCustomOrder> orders;
  final SellerCustomOrdersPagination pagination;
  final Map<String, int> statuses;

  const SellerCustomOrdersResponse({
    required this.orders,
    required this.pagination,
    required this.statuses,
  });

  factory SellerCustomOrdersResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final orders = data['orders'] as Map<String, dynamic>? ?? {};
    final rawItems = orders['data'] as List? ?? const [];
    final rawStatuses = data['statuses'] as Map? ?? const {};

    return SellerCustomOrdersResponse(
      orders: rawItems
          .whereType<Map>()
          .map(
            (item) =>
                SellerCustomOrder.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
      pagination: SellerCustomOrdersPagination.fromJson(orders),
      statuses: rawStatuses.map(
        (key, value) => MapEntry(key.toString(), _asInt(value)),
      ),
    );
  }
}

class SellerCustomOrdersPagination {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final int? from;
  final int? to;

  const SellerCustomOrdersPagination({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    this.from,
    this.to,
  });

  bool get hasPrevious => currentPage > 1;
  bool get hasNext => currentPage < lastPage;

  factory SellerCustomOrdersPagination.fromJson(Map<String, dynamic> json) {
    return SellerCustomOrdersPagination(
      currentPage: _asInt(json['current_page'], fallback: 1),
      lastPage: _asInt(json['last_page'], fallback: 1),
      perPage: _asInt(json['per_page']),
      total: _asInt(json['total']),
      from: json['from'] == null ? null : _asInt(json['from']),
      to: json['to'] == null ? null : _asInt(json['to']),
    );
  }
}

/// Lightweight customer info carried on the list-level order payload.
class SellerCustomOrderListUser {
  final int id;
  final String name;
  final String phone;

  const SellerCustomOrderListUser({
    required this.id,
    required this.name,
    required this.phone,
  });

  factory SellerCustomOrderListUser.fromJson(Map<String, dynamic> json) {
    return SellerCustomOrderListUser(
      id: _asInt(json['id']),
      name: _text(json['name'], fallback: 'Customer'),
      phone: _text(json['phone']),
    );
  }

  static SellerCustomOrderListUser get empty =>
      const SellerCustomOrderListUser(id: 0, name: 'Customer', phone: '');
}

class SellerCustomOrder {
  final int id;
  final String uuid;
  final int productId;
  final int totalDealPrice;
  final int advancePrice;
  final int tenure;
  final int userId;
  final String portal;
  final String status;
  final String createdAt;
  final SellerCustomOrderProduct product;
  final SellerCustomOrderListUser user;

  const SellerCustomOrder({
    required this.id,
    required this.uuid,
    required this.productId,
    required this.totalDealPrice,
    required this.advancePrice,
    required this.tenure,
    required this.userId,
    required this.portal,
    required this.status,
    required this.createdAt,
    required this.product,
    required this.user,
  });

  String get formattedTotalDealPrice => _money(totalDealPrice);
  String get formattedAdvancePrice => _money(advancePrice);
  String get formattedCreatedAt => _date(createdAt);

  factory SellerCustomOrder.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    return SellerCustomOrder(
      id: _asInt(json['id']),
      uuid: _text(json['uuid']),
      productId: _asInt(json['product_id']),
      totalDealPrice: _asInt(json['total_deal_price']),
      advancePrice: _asInt(json['advance_price']),
      tenure: _asInt(json['tenure']),
      userId: _asInt(json['user_id']),
      portal: _text(json['portal'], fallback: 'Unknown'),
      status: _text(json['status'], fallback: 'Unknown'),
      createdAt: _text(json['created_at']),
      product: SellerCustomOrderProduct.fromJson(
        json['custom_order_product'] as Map<String, dynamic>? ?? {},
      ),
      user: rawUser is Map
          ? SellerCustomOrderListUser.fromJson(
              Map<String, dynamic>.from(rawUser),
            )
          : SellerCustomOrderListUser.empty,
    );
  }
}

class SellerCustomOrderProduct {
  final int id;
  final String title;
  final String prNumber;
  final int price;
  final int advancePrice;
  final String picture;
  final String categoryId;
  final String brandId;
  final String customFields;

  const SellerCustomOrderProduct({
    required this.id,
    required this.title,
    required this.prNumber,
    required this.price,
    required this.advancePrice,
    required this.picture,
    required this.categoryId,
    required this.brandId,
    required this.customFields,
  });

  String get formattedPrice => _money(price);
  String get formattedAdvancePrice => _money(advancePrice);

  /// Parses custom_fields which can be:
  ///   - null / "Not available"  → empty map
  ///   - array [{title, value}]  → {title: value}
  ///   - object {key: value}     → {key: value}
  Map<String, String> get customFieldsMap {
    if (customFields == 'Not available' || customFields.isEmpty) return const {};
    try {
      final decoded = jsonDecode(customFields);
      if (decoded is List) {
        final map = <String, String>{};
        for (final item in decoded) {
          if (item is Map) {
            final title = item['title']?.toString() ?? '';
            final value = item['value']?.toString() ?? '';
            if (title.isNotEmpty) map[title] = value;
          }
        }
        return map;
      }
      if (decoded is Map) {
        return decoded.map(
          (k, v) => MapEntry(k.toString(), v?.toString() ?? 'N/A'),
        );
      }
      return const {};
    } catch (_) {
      return const {};
    }
  }

  factory SellerCustomOrderProduct.fromJson(Map<String, dynamic> json) {
    // Preserve raw custom_fields (array or object) as JSON string for parsing.
    final rawCf = json['custom_fields'];
    return SellerCustomOrderProduct(
      id: _asInt(json['id']),
      title: _text(json['title'], fallback: 'Untitled Product'),
      prNumber: _text(json['pr_number'], fallback: 'No PR number'),
      price: _asInt(json['price']),
      advancePrice: _asInt(json['advance_price']),
      picture: _text(json['picture'], fallback: 'No image'),
      categoryId: _text(json['category_id']),
      brandId: _text(json['brand_id']),
      customFields: rawCf == null ? 'Not available' : jsonEncode(rawCf),
    );
  }
}

class SellerCustomOrderDetails {
  final SellerCustomOrderDetailOrder order;
  final List<SellerCustomOrderStatusHistory> statusHistory;
  final List<SellerCustomOrderInstalment> instalments;
  final SellerCustomOrderUser user;
  final List<SellerRecoveryMember> recoveryMembers;
  final int outstandingPrincipal;

  const SellerCustomOrderDetails({
    required this.order,
    required this.statusHistory,
    required this.instalments,
    required this.user,
    required this.recoveryMembers,
    required this.outstandingPrincipal,
  });

  factory SellerCustomOrderDetails.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};

    return SellerCustomOrderDetails(
      order: SellerCustomOrderDetailOrder.fromJson(
        data['order'] as Map<String, dynamic>? ?? {},
      ),
      statusHistory: (data['order_change_status'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => SellerCustomOrderStatusHistory.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(growable: false),
      instalments: (data['order_instalments'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => SellerCustomOrderInstalment.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(growable: false),
      user: SellerCustomOrderUser.fromJson(
        data['user'] as Map<String, dynamic>? ?? {},
      ),
      recoveryMembers: (data['recoveryMembers'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                SellerRecoveryMember.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
      outstandingPrincipal: _asInt(data['outstanding_principal']),
    );
  }
}

class SellerCustomOrderDetailOrder {
  final int id;
  final String uuid;
  final int userId;
  final int productId;
  final int totalDealPrice;
  final int advancePrice;
  final int sourcingAgentFee;
  final int perMonthPercentage;
  final int tenure;
  final int areaId;
  final int cityId;
  final String portal;
  final String status;
  final String type;
  final String createdAt;
  final String updatedAt;
  final int settlementAmount;
  final bool dealClosed;
  final SellerCustomOrderProduct product;

  const SellerCustomOrderDetailOrder({
    required this.id,
    required this.uuid,
    required this.userId,
    required this.productId,
    required this.totalDealPrice,
    required this.advancePrice,
    required this.sourcingAgentFee,
    required this.perMonthPercentage,
    required this.tenure,
    required this.areaId,
    required this.cityId,
    required this.portal,
    required this.status,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    required this.settlementAmount,
    required this.dealClosed,
    required this.product,
  });

  String get formattedTotalDealPrice => _money(totalDealPrice);
  String get formattedAdvancePrice => _money(advancePrice);
  String get formattedSourcingAgentFee => _money(sourcingAgentFee);
  String get formattedSettlementAmount => _money(settlementAmount);
  String get formattedCreatedAt => _date(createdAt);
  String get formattedUpdatedAt => _date(updatedAt);

  factory SellerCustomOrderDetailOrder.fromJson(Map<String, dynamic> json) {
    return SellerCustomOrderDetailOrder(
      id: _asInt(json['id']),
      uuid: _text(json['uuid']),
      userId: _asInt(json['user_id']),
      productId: _asInt(json['product_id']),
      totalDealPrice: _asInt(json['total_deal_price']),
      advancePrice: _asInt(json['advance_price']),
      sourcingAgentFee: _asInt(json['sourcing_agent_fee']),
      perMonthPercentage: _asInt(json['per_month_percentage']),
      tenure: _asInt(json['tenure']),
      areaId: _asInt(json['area_id']),
      cityId: _asInt(json['city_id']),
      portal: _text(json['portal'], fallback: 'Unknown'),
      status: _text(json['status'], fallback: 'Unknown'),
      type: _text(json['type']),
      createdAt: _text(json['created_at']),
      updatedAt: _text(json['updated_at']),
      settlementAmount: _asInt(json['settlement_amount']),
      dealClosed: json['deal_close']?.toString() == '1',
      product: SellerCustomOrderProduct.fromJson(
        json['product'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class SellerCustomOrderStatusHistory {
  final int id;
  final String status;
  final String role;
  final String orderType;
  final String createdAt;
  final String comment;
  /// All key→value pairs from the payload JSON (excluding 'comment').
  final Map<String, String> payloadDetails;

  const SellerCustomOrderStatusHistory({
    required this.id,
    required this.status,
    required this.role,
    required this.orderType,
    required this.createdAt,
    required this.comment,
    required this.payloadDetails,
  });

  String get formattedCreatedAt => _date(createdAt);

  factory SellerCustomOrderStatusHistory.fromJson(Map<String, dynamic> json) {
    final raw = json['payload'];
    var comment = '';
    var details = <String, String>{};

    if (raw is String && raw.isNotEmpty && raw != '[]') {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          details = decoded.map(
            (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
          );
          comment = details.remove('comment') ?? '';
        }
      } catch (_) {}
    }

    return SellerCustomOrderStatusHistory(
      id: _asInt(json['id']),
      status: _text(json['status'], fallback: 'Unknown'),
      role: _text(json['role']),
      orderType: _text(json['order_type']),
      createdAt: _text(json['created_at']),
      comment: comment,
      payloadDetails: details,
    );
  }
}

class SellerCustomOrderInstalment {
  final int id;
  final String month;           // "Advance", "1st Month", etc. — card title
  final String type;            // "Advance" | "Instalment"
  final String status;          // "Paid" | "Unpaid"
  final int instalmentPrice;    // installment_price
  final int paidPrice;          // installment_paid_price
  final String instalmentDate;  // installment_date
  final String paidDate;        // installment_paid_date
  final String paymentMethod;   // payment_method

  const SellerCustomOrderInstalment({
    required this.id,
    required this.month,
    required this.type,
    required this.status,
    required this.instalmentPrice,
    required this.paidPrice,
    required this.instalmentDate,
    required this.paidDate,
    required this.paymentMethod,
  });

  String get formattedInstalmentPrice => _money(instalmentPrice);
  String get formattedPaidPrice => paidPrice > 0 ? _money(paidPrice) : '—';
  bool get isPaid => status.toLowerCase() == 'paid';

  factory SellerCustomOrderInstalment.fromJson(Map<String, dynamic> json) {
    return SellerCustomOrderInstalment(
      id: _asInt(json['id']),
      month: _text(json['month']),
      type: _text(json['type']),
      status: _text(json['status']),
      instalmentPrice: _asInt(json['installment_price']),
      paidPrice: _asInt(json['installment_paid_price']),
      instalmentDate: _text(json['installment_date']),
      paidDate: _text(json['installment_paid_date']),
      paymentMethod: _text(json['payment_method']),
    );
  }
}

class SellerCustomOrderUser {
  final int id;
  final String uuid;
  final String name;
  final String email;
  final String phone;
  final String status;
  final String joinedThrough;
  final String createdAt;
  final SellerCustomOrderCustomer customer;

  const SellerCustomOrderUser({
    required this.id,
    required this.uuid,
    required this.name,
    required this.email,
    required this.phone,
    required this.status,
    required this.joinedThrough,
    required this.createdAt,
    required this.customer,
  });

  String get formattedCreatedAt => _date(createdAt);

  factory SellerCustomOrderUser.fromJson(Map<String, dynamic> json) {
    return SellerCustomOrderUser(
      id: _asInt(json['id']),
      uuid: _text(json['uuid']),
      name: _text(json['name'], fallback: 'Customer'),
      email: _text(json['email']),
      phone: _text(json['phone']),
      status: _text(json['status'], fallback: 'Unknown'),
      joinedThrough: _text(json['joined_through']),
      createdAt: _text(json['created_at']),
      customer: SellerCustomOrderCustomer.fromJson(
        json['customer'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class SellerCustomOrderCustomer {
  final int id;
  final String identifier;
  final String address;
  final int cityId;
  final int areaId;
  final String cityTitle;
  final String areaTitle;
  final String cnicNo;
  final String fatherName;
  final String residencePhone;
  final String officeAddress;
  final String officePhone;
  final bool verified;
  final String type;
  final String portal;

  const SellerCustomOrderCustomer({
    required this.id,
    required this.identifier,
    required this.address,
    required this.cityId,
    required this.areaId,
    required this.cityTitle,
    required this.areaTitle,
    required this.cnicNo,
    required this.fatherName,
    required this.residencePhone,
    required this.officeAddress,
    required this.officePhone,
    required this.verified,
    required this.type,
    required this.portal,
  });

  /// Returns true when the API returned a real customer record (id > 0).
  bool get hasData => id > 0;

  factory SellerCustomOrderCustomer.fromJson(Map<String, dynamic> json) {
    final cityObj = json['city'];
    final areaObj = json['area'];
    return SellerCustomOrderCustomer(
      id: _asInt(json['id']),
      identifier: _text(json['identifier']),
      address: _text(json['address']),
      cityId: _asInt(json['city_id']),
      areaId: _asInt(json['area_id']),
      cityTitle: cityObj is Map ? _text(cityObj['title']) : _text(cityObj),
      areaTitle: areaObj is Map ? _text(areaObj['title']) : _text(areaObj),
      cnicNo: _text(json['cnic_no']),
      fatherName: _text(json['father_name']),
      residencePhone: _text(json['residence_phone']),
      officeAddress: _text(json['office_address']),
      officePhone: _text(json['office_phone']),
      verified: json['verified']?.toString() == '1',
      type: _text(json['type']),
      portal: _text(json['portal']),
    );
  }
}

class SellerRecoveryMember {
  final int id;
  final String uuid;
  final String address;
  final String memberType;
  final String memberRole;
  final bool active;
  final SellerRecoveryUser user;

  const SellerRecoveryMember({
    required this.id,
    required this.uuid,
    required this.address,
    required this.memberType,
    required this.memberRole,
    required this.active,
    required this.user,
  });

  factory SellerRecoveryMember.fromJson(Map<String, dynamic> json) {
    return SellerRecoveryMember(
      id: _asInt(json['id']),
      uuid: _text(json['uuid']),
      address: _text(json['address']),
      memberType: _text(json['member_type']),
      memberRole: _text(json['member_role']),
      active: json['status']?.toString() == '1',
      user: SellerRecoveryUser.fromJson(
        json['user'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class SellerRecoveryUser {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String status;

  const SellerRecoveryUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.status,
  });

  factory SellerRecoveryUser.fromJson(Map<String, dynamic> json) {
    return SellerRecoveryUser(
      id: _asInt(json['id']),
      name: _text(json['name'], fallback: 'Recovery member'),
      email: _text(json['email']),
      phone: _text(json['phone']),
      status: _text(json['status']),
    );
  }
}

class SellerCustomOrderGuarantor {
  final int id;
  final String name;
  final String phone;
  final String cnic;
  final String address;
  final String createdAt;
  final bool exists;

  const SellerCustomOrderGuarantor({
    required this.id,
    required this.name,
    required this.phone,
    required this.cnic,
    required this.address,
    required this.createdAt,
    required this.exists,
  });

  factory SellerCustomOrderGuarantor.empty() {
    return const SellerCustomOrderGuarantor(
      id: 0,
      name: 'Not available',
      phone: 'Not available',
      cnic: 'Not available',
      address: 'Not available',
      createdAt: 'Not available',
      exists: false,
    );
  }

  factory SellerCustomOrderGuarantor.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final raw = data is Map
        ? (data['guarantor'] is Map ? data['guarantor'] : data)
        : json;
    final map = Map<String, dynamic>.from(raw as Map);

    final hasUsefulData = ['name', 'phone', 'cnic', 'address'].any((key) {
      final value = map[key]?.toString().trim();
      return value != null && value.isNotEmpty && value != 'null';
    });

    if (!hasUsefulData) return SellerCustomOrderGuarantor.empty();

    return SellerCustomOrderGuarantor(
      id: _asInt(map['id']),
      name: _text(map['name'], fallback: 'Guarantor'),
      phone: _text(map['phone']),
      cnic: _text(map['cnic']),
      address: _text(map['address']),
      createdAt: _text(map['created_at']),
      exists: true,
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

String _money(int value) {
  return 'Rs ${_withCommas(value)}';
}

String _withCommas(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final remaining = text.length - i;
    buffer.write(text[i]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write(',');
  }
  return buffer.toString();
}

