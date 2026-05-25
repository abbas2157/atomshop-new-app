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
  });

  String get formattedTotalDealPrice => _money(totalDealPrice);
  String get formattedAdvancePrice => _money(advancePrice);
  String get formattedCreatedAt => _date(createdAt);

  factory SellerCustomOrder.fromJson(Map<String, dynamic> json) {
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

  factory SellerCustomOrderProduct.fromJson(Map<String, dynamic> json) {
    return SellerCustomOrderProduct(
      id: _asInt(json['id']),
      title: _text(json['title'], fallback: 'Untitled Product'),
      prNumber: _text(json['pr_number'], fallback: 'No PR number'),
      price: _asInt(json['price']),
      advancePrice: _asInt(json['advance_price']),
      picture: _text(json['picture'], fallback: 'No image'),
      categoryId: _text(json['category_id']),
      brandId: _text(json['brand_id']),
      customFields: _text(json['custom_fields']),
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

  const SellerCustomOrderStatusHistory({
    required this.id,
    required this.status,
    required this.role,
    required this.orderType,
    required this.createdAt,
    required this.comment,
  });

  String get formattedCreatedAt => _date(createdAt);

  factory SellerCustomOrderStatusHistory.fromJson(Map<String, dynamic> json) {
    return SellerCustomOrderStatusHistory(
      id: _asInt(json['id']),
      status: _text(json['status'], fallback: 'Unknown'),
      role: _text(json['role']),
      orderType: _text(json['order_type']),
      createdAt: _text(json['created_at']),
      comment: _payloadComment(json['payload']),
    );
  }
}

class SellerCustomOrderInstalment {
  final int id;
  final String status;
  final int amount;
  final String dueDate;

  const SellerCustomOrderInstalment({
    required this.id,
    required this.status,
    required this.amount,
    required this.dueDate,
  });

  String get formattedAmount => _money(amount);

  factory SellerCustomOrderInstalment.fromJson(Map<String, dynamic> json) {
    return SellerCustomOrderInstalment(
      id: _asInt(json['id']),
      status: _text(json['status']),
      amount: _asInt(json['amount'] ?? json['instalment_price']),
      dueDate: _text(json['due_date'] ?? json['date']),
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
  final SellerCustomOrderCustomer customer;

  const SellerCustomOrderUser({
    required this.id,
    required this.uuid,
    required this.name,
    required this.email,
    required this.phone,
    required this.status,
    required this.joinedThrough,
    required this.customer,
  });

  factory SellerCustomOrderUser.fromJson(Map<String, dynamic> json) {
    return SellerCustomOrderUser(
      id: _asInt(json['id']),
      uuid: _text(json['uuid']),
      name: _text(json['name'], fallback: 'Customer'),
      email: _text(json['email']),
      phone: _text(json['phone']),
      status: _text(json['status'], fallback: 'Unknown'),
      joinedThrough: _text(json['joined_through']),
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
    required this.cnicNo,
    required this.fatherName,
    required this.residencePhone,
    required this.officeAddress,
    required this.officePhone,
    required this.verified,
    required this.type,
    required this.portal,
  });

  factory SellerCustomOrderCustomer.fromJson(Map<String, dynamic> json) {
    return SellerCustomOrderCustomer(
      id: _asInt(json['id']),
      identifier: _text(json['identifier']),
      address: _text(json['address']),
      cityId: _asInt(json['city_id']),
      areaId: _asInt(json['area_id']),
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
  final String name;
  final String email;
  final String phone;
  final String status;

  const SellerRecoveryUser({
    required this.name,
    required this.email,
    required this.phone,
    required this.status,
  });

  factory SellerRecoveryUser.fromJson(Map<String, dynamic> json) {
    return SellerRecoveryUser(
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
  if (value.isEmpty || value == 'Not available') return 'Not available';
  return value.replaceFirst('T', ' ').replaceFirst('.000000Z', '');
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

String _payloadComment(dynamic payload) {
  final raw = payload?.toString();
  if (raw == null || raw.trim().isEmpty || raw == 'null') {
    return 'Not available';
  }

  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map && decoded['comment'] != null) {
      return _text(decoded['comment']);
    }
  } catch (_) {
    // Keep the raw payload if it is not JSON.
  }

  return raw;
}
