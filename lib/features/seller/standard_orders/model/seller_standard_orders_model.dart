import 'dart:convert';

class SellerStandardOrdersResponse {
  final List<SellerStandardOrder> orders;
  final SellerStandardOrdersPagination pagination;

  const SellerStandardOrdersResponse({
    required this.orders,
    required this.pagination,
  });

  int get pendingCount => orders
      .where((order) => order.status.toLowerCase().contains('pending'))
      .length;

  factory SellerStandardOrdersResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'])
        : <String, dynamic>{};
    return SellerStandardOrdersResponse(
      orders: (data['data'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                SellerStandardOrder.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
      pagination: SellerStandardOrdersPagination.fromJson(data),
    );
  }
}

class SellerStandardOrdersPagination {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final int? from;
  final int? to;

  const SellerStandardOrdersPagination({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    this.from,
    this.to,
  });

  bool get hasPrevious => currentPage > 1;
  bool get hasNext => currentPage < lastPage;

  factory SellerStandardOrdersPagination.fromJson(Map<String, dynamic> json) {
    return SellerStandardOrdersPagination(
      currentPage: _asInt(json['current_page'], fallback: 1),
      lastPage: _asInt(json['last_page'], fallback: 1),
      perPage: _asInt(json['per_page']),
      total: _asInt(json['total']),
      from: json['from'] == null ? null : _asInt(json['from']),
      to: json['to'] == null ? null : _asInt(json['to']),
    );
  }
}

class SellerStandardOrder {
  final int id;
  final String uuid;
  final int cartId;
  final int userId;
  final int totalDealPrice;
  final int advancePrice;
  final int instalmentTenure;
  final String portal;
  final String status;
  final String createdAt;

  const SellerStandardOrder({
    required this.id,
    required this.uuid,
    required this.cartId,
    required this.userId,
    required this.totalDealPrice,
    required this.advancePrice,
    required this.instalmentTenure,
    required this.portal,
    required this.status,
    required this.createdAt,
  });

  String get formattedTotalDealPrice => _money(totalDealPrice);
  String get formattedAdvancePrice => _money(advancePrice);
  String get formattedCreatedAt => _date(createdAt);

  factory SellerStandardOrder.fromJson(Map<String, dynamic> json) {
    return SellerStandardOrder(
      id: _asInt(json['id']),
      uuid: _text(json['uuid']),
      cartId: _asInt(json['cart_id']),
      userId: _asInt(json['user_id']),
      totalDealPrice: _asInt(json['total_deal_price']),
      advancePrice: _asInt(json['advance_price']),
      instalmentTenure: _asInt(json['instalment_tenure']),
      portal: _text(json['portal'], fallback: 'Unknown'),
      status: _text(json['status'], fallback: 'Unknown'),
      createdAt: _text(json['created_at'], fallback: ''),
    );
  }
}

class SellerStandardOrderDetails {
  final SellerStandardOrder order;
  final List<SellerStandardOrderStatusHistory> statusHistory;
  final List<SellerStandardOrderInstalment> instalments;
  final SellerStandardOrderUser user;

  const SellerStandardOrderDetails({
    required this.order,
    required this.statusHistory,
    required this.instalments,
    required this.user,
  });

  factory SellerStandardOrderDetails.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'])
        : <String, dynamic>{};
    return SellerStandardOrderDetails(
      order: SellerStandardOrder.fromJson(
        data['order'] is Map
            ? Map<String, dynamic>.from(data['order'])
            : <String, dynamic>{},
      ),
      statusHistory: (data['order_change_status'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => SellerStandardOrderStatusHistory.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(growable: false),
      instalments: (data['order_instalments'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => SellerStandardOrderInstalment.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(growable: false),
      user: SellerStandardOrderUser.fromJson(
        data['user'] is Map
            ? Map<String, dynamic>.from(data['user'])
            : <String, dynamic>{},
      ),
    );
  }
}

class SellerStandardOrderStatusHistory {
  final int id;
  final String status;
  final String role;
  final String orderType;
  final String createdAt;
  final String comment;

  const SellerStandardOrderStatusHistory({
    required this.id,
    required this.status,
    required this.role,
    required this.orderType,
    required this.createdAt,
    required this.comment,
  });

  String get formattedCreatedAt => _date(createdAt);

  factory SellerStandardOrderStatusHistory.fromJson(Map<String, dynamic> json) {
    return SellerStandardOrderStatusHistory(
      id: _asInt(json['id']),
      status: _text(json['status'], fallback: 'Unknown'),
      role: _text(json['role']),
      orderType: _text(json['order_type']),
      createdAt: _text(json['created_at'], fallback: ''),
      comment: _payloadComment(json['payload']),
    );
  }
}

class SellerStandardOrderInstalment {
  final int id;
  final String month;
  final int installmentPrice;
  final int installmentPaidPrice;
  final String installmentDate;
  final String paymentMethod;
  final String type;
  final String status;

  const SellerStandardOrderInstalment({
    required this.id,
    required this.month,
    required this.installmentPrice,
    required this.installmentPaidPrice,
    required this.installmentDate,
    required this.paymentMethod,
    required this.type,
    required this.status,
  });

  String get formattedPrice => _money(installmentPrice);
  String get formattedPaidPrice => _money(installmentPaidPrice);

  factory SellerStandardOrderInstalment.fromJson(Map<String, dynamic> json) {
    return SellerStandardOrderInstalment(
      id: _asInt(json['id']),
      month: _text(json['month']),
      installmentPrice: _asInt(json['installment_price']),
      installmentPaidPrice: _asInt(json['installment_paid_price']),
      installmentDate: _text(json['installment_date']),
      paymentMethod: _text(json['payment_method']),
      type: _text(json['type']),
      status: _text(json['status'], fallback: 'Unknown'),
    );
  }
}

class SellerStandardOrderUser {
  final int id;
  final String uuid;
  final String name;
  final String email;
  final String phone;
  final String status;
  final String joinedThrough;
  final SellerStandardOrderCustomer customer;

  const SellerStandardOrderUser({
    required this.id,
    required this.uuid,
    required this.name,
    required this.email,
    required this.phone,
    required this.status,
    required this.joinedThrough,
    required this.customer,
  });

  factory SellerStandardOrderUser.fromJson(Map<String, dynamic> json) {
    return SellerStandardOrderUser(
      id: _asInt(json['id']),
      uuid: _text(json['uuid']),
      name: _text(json['name'], fallback: 'Customer'),
      email: _text(json['email']),
      phone: _text(json['phone']),
      status: _text(json['status'], fallback: 'Unknown'),
      joinedThrough: _text(json['joined_through']),
      customer: SellerStandardOrderCustomer.fromJson(
        json['customer'] is Map
            ? Map<String, dynamic>.from(json['customer'])
            : <String, dynamic>{},
      ),
    );
  }
}

class SellerStandardOrderCustomer {
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
  final String portal;

  const SellerStandardOrderCustomer({
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
    required this.portal,
  });

  factory SellerStandardOrderCustomer.fromJson(Map<String, dynamic> json) {
    return SellerStandardOrderCustomer(
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
      portal: _text(json['portal']),
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

String _date(dynamic value) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty || text == 'null' || text == 'Not available') {
    return 'Not available';
  }
  return text.replaceFirst('T', ' ').replaceFirst('.000000Z', '');
}

String _money(int value) => 'Rs ${_withCommas(value)}';

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
    // Keep raw payload if backend sends plain text.
  }

  return raw;
}
