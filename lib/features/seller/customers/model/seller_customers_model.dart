import 'package:atompro/core/seller_plan_upgrade_exception.dart';

enum SellerCustomerScope {
  all('All Area', 'All'),
  mine('My Customers', 'My'),
  other('Other Platform', 'Other');

  final String label;
  final String shortLabel;

  const SellerCustomerScope(this.label, this.shortLabel);
}

class SellerCustomersQuery {
  final SellerCustomerScope scope;
  final int page;

  const SellerCustomersQuery({
    this.scope = SellerCustomerScope.mine,
    this.page = 1,
  });

  SellerCustomersQuery copyWith({SellerCustomerScope? scope, int? page}) {
    return SellerCustomersQuery(
      scope: scope ?? this.scope,
      page: page ?? this.page,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SellerCustomersQuery &&
        other.scope == scope &&
        other.page == page;
  }

  @override
  int get hashCode => Object.hash(scope, page);
}

class SellerCustomersResponse {
  final List<SellerCustomer> customers;
  final SellerCustomersPagination pagination;

  /// Non-null when the plan doesn't include this feature — carried as data, not
  /// thrown, to avoid the AsyncError refetch loop. Screen renders the gate from it.
  final SellerPlanUpgradeException? gate;

  const SellerCustomersResponse({
    required this.customers,
    required this.pagination,
    this.gate,
  });

  factory SellerCustomersResponse.gated(SellerPlanUpgradeException gate) {
    return SellerCustomersResponse(
      customers: const [],
      pagination: const SellerCustomersPagination(
        currentPage: 1,
        lastPage: 1,
        perPage: 0,
        total: 0,
      ),
      gate: gate,
    );
  }

  factory SellerCustomersResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'])
        : <String, dynamic>{};
    final rawItems = data['data'] as List? ?? const [];

    return SellerCustomersResponse(
      customers: rawItems
          .whereType<Map>()
          .map(
            (item) => SellerCustomer.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
      pagination: SellerCustomersPagination.fromJson(data),
    );
  }
}

class SellerCustomersPagination {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final int? from;
  final int? to;

  const SellerCustomersPagination({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    this.from,
    this.to,
  });

  bool get hasPrevious => currentPage > 1;
  bool get hasNext => currentPage < lastPage;

  factory SellerCustomersPagination.fromJson(Map<String, dynamic> json) {
    return SellerCustomersPagination(
      currentPage: _asInt(json['current_page'], fallback: 1),
      lastPage: _asInt(json['last_page'], fallback: 1),
      perPage: _asInt(json['per_page']),
      total: _asInt(json['total']),
      from: json['from'] == null ? null : _asInt(json['from']),
      to: json['to'] == null ? null : _asInt(json['to']),
    );
  }
}

class SellerCustomer {
  final int id;
  final String uuid;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String status;
  final String joinedThrough;
  final String createdAt;
  final String lastLoginAt;
  final SellerCustomerProfile profile;
  final int customOrderCount;

  const SellerCustomer({
    required this.id,
    required this.uuid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    required this.joinedThrough,
    required this.createdAt,
    required this.lastLoginAt,
    required this.profile,
    this.customOrderCount = 0,
  });

  bool get verified => profile.verified;
  String get formattedCreatedAt => _date(createdAt);

  factory SellerCustomer.fromJson(Map<String, dynamic> json) {
    return SellerCustomer(
      id: _asInt(json['id']),
      uuid: _text(json['uuid']),
      name: _text(json['name'], fallback: 'Customer'),
      email: _text(json['email']),
      phone: _text(json['phone']),
      role: _text(json['role'], fallback: 'customer'),
      status: _text(json['status'], fallback: 'Unknown'),
      joinedThrough: _text(json['joined_through']),
      createdAt: _text(json['created_at']),
      lastLoginAt: _date(json['last_login_at']),
      customOrderCount: _asInt(json['custom_order_count']),
      profile: SellerCustomerProfile.fromJson(
        json['customer'] is Map
            ? Map<String, dynamic>.from(json['customer'])
            : <String, dynamic>{},
      ),
    );
  }
}

class SellerCustomerProfile {
  final int id;
  final String identifier;
  final String picture;
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
  final String notVerifiedReason;

  const SellerCustomerProfile({
    required this.id,
    required this.identifier,
    required this.picture,
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
    required this.notVerifiedReason,
  });

  int get completeness {
    final fields = [
      picture,
      address,
      cnicNo,
      fatherName,
      residencePhone,
    ];
    const skip = {'', 'Not available', 'Not Available', 'N/A'};
    final hasLocation = cityId > 0 && areaId > 0;
    final filled = fields.where((f) => !skip.contains(f)).length;
    return ((filled + (hasLocation ? 1 : 0)) * 100 ~/ (fields.length + 1));
  }

  List<String> get missingFields {
    final missing = <String>[];
    const skip = {'', 'Not available', 'Not Available', 'N/A'};
    if (skip.contains(picture)) missing.add('Profile photo');
    if (skip.contains(cnicNo)) missing.add('CNIC');
    if (skip.contains(fatherName)) missing.add('Father name');
    if (skip.contains(address)) missing.add('Address');
    if (skip.contains(residencePhone)) missing.add('Residence phone');
    if (cityId == 0 || areaId == 0) missing.add('City / Area');
    return missing;
  }

  /// "Ali Town, Lahore" — omits either part when empty.
  String get location {
    if (areaTitle.isNotEmpty && cityTitle.isNotEmpty) return '$areaTitle, $cityTitle';
    if (areaTitle.isNotEmpty) return areaTitle;
    return cityTitle;
  }

  factory SellerCustomerProfile.fromJson(Map<String, dynamic> json) {
    return SellerCustomerProfile(
      id: _asInt(json['id']),
      identifier: _text(json['identifier']),
      picture: _text(json['picture']),
      address: _text(json['address']),
      cityId: _asInt(json['city_id']),
      areaId: _asInt(json['area_id']),
      cityTitle: _nestedTitle(json['city']),
      areaTitle: _nestedTitle(json['area']),
      cnicNo: _text(json['cnic_no']),
      fatherName: _text(json['father_name']),
      residencePhone: _text(json['residence_phone']),
      officeAddress: _text(json['office_address']),
      officePhone: _text(json['office_phone']),
      verified: json['verified']?.toString() == '1',
      type: _text(json['type']),
      portal: _text(json['portal']),
      notVerifiedReason: _text(json['not_verified_reason']),
    );
  }
}

class SellerCustomerVerification {
  final int id;
  final String idCardFront;
  final String idCardBack;
  final bool addressFound;
  final String house;
  final bool physicalMeet;
  final String work;
  final String selfie;
  final String createdAt;

  const SellerCustomerVerification({
    required this.id,
    required this.idCardFront,
    required this.idCardBack,
    required this.addressFound,
    required this.house,
    required this.physicalMeet,
    required this.work,
    required this.selfie,
    required this.createdAt,
  });

  bool get exists => id > 0;

  factory SellerCustomerVerification.fromJson(Map<String, dynamic> json) {
    return SellerCustomerVerification(
      id: _asInt(json['id']),
      idCardFront: _text(json['id_card_front_side']),
      idCardBack: _text(json['id_card_back_side']),
      addressFound: json['address_found']?.toString() == '1',
      house: _text(json['house']),
      physicalMeet: json['customer_physical_meet']?.toString() == '1',
      work: _text(json['work']),
      selfie: _text(json['selfie_with_customer']),
      createdAt: _text(json['created_at']),
    );
  }

  static SellerCustomerVerification get empty =>
      const SellerCustomerVerification(
        id: 0,
        idCardFront: 'Not available',
        idCardBack: 'Not available',
        addressFound: false,
        house: 'Not available',
        physicalMeet: false,
        work: 'Not available',
        selfie: 'Not available',
        createdAt: 'Not available',
      );
}

class SellerCustomerDetails {
  final SellerCustomer user;
  final SellerCustomerVerification verification;
  final List<SellerCustomerOrderSummary> customOrders;
  final int totalCustomSales;
  final int totalCustomRecovery;
  final double recoveryPercentage;

  const SellerCustomerDetails({
    required this.user,
    required this.verification,
    required this.customOrders,
    required this.totalCustomSales,
    required this.totalCustomRecovery,
    required this.recoveryPercentage,
  });

  String get formattedTotalCustomSales => _money(totalCustomSales);
  String get formattedTotalCustomRecovery => _money(totalCustomRecovery);
  String get formattedRecoveryPercentage =>
      '${recoveryPercentage.toStringAsFixed(2)}%';

  factory SellerCustomerDetails.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'])
        : <String, dynamic>{};
    final user = data['user'] is Map
        ? Map<String, dynamic>.from(data['user'])
        : <String, dynamic>{};
    user['customer'] = data['customer'];

    final rawVerification = data['customer_verification'];

    return SellerCustomerDetails(
      user: SellerCustomer.fromJson(user),
      verification: rawVerification is Map
          ? SellerCustomerVerification.fromJson(
              Map<String, dynamic>.from(rawVerification),
            )
          : SellerCustomerVerification.empty,
      customOrders: (data['custom_orders'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => SellerCustomerOrderSummary.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(growable: false),
      totalCustomSales: _asInt(data['total_custom_sales']),
      totalCustomRecovery: _asInt(data['total_custom_recovery']),
      recoveryPercentage: _asDouble(data['recovery_percentage']),
    );
  }
}

class SellerCustomerInstalmentsResponse {
  final List<SellerCustomerInstalment> instalments;
  final SellerCustomersPagination pagination;

  const SellerCustomerInstalmentsResponse({
    required this.instalments,
    required this.pagination,
  });

  factory SellerCustomerInstalmentsResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'])
        : <String, dynamic>{};
    return SellerCustomerInstalmentsResponse(
      instalments: (data['data'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => SellerCustomerInstalment.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(growable: false),
      pagination: SellerCustomersPagination.fromJson(data),
    );
  }
}

class SellerCustomerCustomOrdersResponse {
  final List<SellerCustomerOrderSummary> orders;
  final SellerCustomersPagination pagination;

  const SellerCustomerCustomOrdersResponse({
    required this.orders,
    required this.pagination,
  });

  factory SellerCustomerCustomOrdersResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'])
        : <String, dynamic>{};
    return SellerCustomerCustomOrdersResponse(
      orders: (data['data'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => SellerCustomerOrderSummary.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(growable: false),
      pagination: SellerCustomersPagination.fromJson(data),
    );
  }
}

class SellerCustomerOrderSummary {
  final int id;
  final String uuid;
  final int totalDealPrice;
  final int productId;
  final int userId;
  final String portal;
  final String status;
  final String createdAt;

  const SellerCustomerOrderSummary({
    required this.id,
    required this.uuid,
    required this.totalDealPrice,
    required this.productId,
    required this.userId,
    required this.portal,
    required this.status,
    required this.createdAt,
  });

  String get formattedTotalDealPrice => _money(totalDealPrice);
  String get formattedCreatedAt => _date(createdAt);

  factory SellerCustomerOrderSummary.fromJson(Map<String, dynamic> json) {
    return SellerCustomerOrderSummary(
      id: _asInt(json['id']),
      uuid: _text(json['uuid']),
      totalDealPrice: _asInt(json['total_deal_price']),
      productId: _asInt(json['product_id']),
      userId: _asInt(json['user_id']),
      portal: _text(json['portal']),
      status: _text(json['status'], fallback: 'Unknown'),
      createdAt: _text(json['created_at']),
    );
  }
}

class SellerCustomerInstalment {
  final int id;
  final int orderId;
  final String month;
  final int installmentPrice;
  final int installmentPaidPrice;
  final String installmentDate;
  final String installmentPaidDate;
  final String receipt;
  final String paymentMethod;
  final String type;
  final String status;
  final String orderType;

  const SellerCustomerInstalment({
    required this.id,
    required this.orderId,
    required this.month,
    required this.installmentPrice,
    required this.installmentPaidPrice,
    required this.installmentDate,
    required this.installmentPaidDate,
    required this.receipt,
    required this.paymentMethod,
    required this.type,
    required this.status,
    required this.orderType,
  });

  String get formattedPrice => _money(installmentPrice);
  String get formattedPaidPrice => _money(installmentPaidPrice);

  factory SellerCustomerInstalment.fromJson(Map<String, dynamic> json) {
    return SellerCustomerInstalment(
      id: _asInt(json['id']),
      orderId: _asInt(json['order_id']),
      month: _text(json['month']),
      installmentPrice: _asInt(json['installment_price']),
      installmentPaidPrice: _asInt(json['installment_paid_price']),
      installmentDate: _text(json['installment_date']),
      installmentPaidDate: _text(json['installment_paid_date']),
      receipt: _text(json['receipet'] ?? json['receipt']),
      paymentMethod: _text(json['payment_method']),
      type: _text(json['type']),
      status: _text(json['status'], fallback: 'Unknown'),
      orderType: _text(json['order_type']),
    );
  }
}

class SellerCustomerArea {
  final int id;
  final String title;
  final int cityId;

  const SellerCustomerArea({
    required this.id,
    required this.title,
    required this.cityId,
  });

  factory SellerCustomerArea.fromJson(Map<String, dynamic> json) {
    return SellerCustomerArea(
      id: _asInt(json['id']),
      title: _text(json['title'], fallback: 'Area'),
      cityId: _asInt(json['city_id']),
    );
  }
}

String _nestedTitle(dynamic obj) {
  if (obj is Map) {
    final t = obj['title']?.toString().trim() ?? '';
    return (t.isEmpty || t == 'null') ? '' : t;
  }
  return '';
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String _text(dynamic value, {String fallback = 'Not available'}) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty || text == 'null') return fallback;
  return text;
}

String _date(dynamic value) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty || text == 'null' || text == 'Not available') return 'N/A';
  try {
    final dt = DateTime.parse(text).toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  } catch (_) {
    return text.split('T').first;
  }
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
