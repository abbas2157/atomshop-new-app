class MyOrdersResponse {
  final UserInfo user;
  final CustomerInfo customer;
  final List<OrderModel> orders;

  const MyOrdersResponse({
    required this.user,
    required this.customer,
    required this.orders,
  });

  factory MyOrdersResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return MyOrdersResponse(
      user: UserInfo.fromJson(data['user'] as Map<String, dynamic>),
      customer: CustomerInfo.fromJson(data['customer'] as Map<String, dynamic>),
      orders: (data['orders'] as List? ?? [])
          .map((o) => OrderModel.fromJson(o as Map<String, dynamic>))
          .toList(),
    );
  }
}

class UserInfo {
  final String uuid;
  final String name;
  final String? phone;
  final String email;
  final String joinDate;

  const UserInfo({
    required this.uuid,
    required this.name,
    this.phone,
    required this.email,
    required this.joinDate,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) => UserInfo(
    uuid: json['uuid']?.toString() ?? '',
    name: json['name']?.toString() ?? 'Unknown',
    phone: json['phone']?.toString(),
    email: json['email']?.toString() ?? '',
    joinDate: json['join_date']?.toString() ?? '',
  );
}

class CustomerInfo {
  final String identifier;
  final String address;
  final String? fatherName;
  final String? cnicNo;
  final String city;
  final String area;
  final bool isVerified;

  const CustomerInfo({
    required this.identifier,
    required this.address,
    this.fatherName,
    this.cnicNo,
    required this.city,
    required this.area,
    required this.isVerified,
  });

  factory CustomerInfo.fromJson(Map<String, dynamic> json) => CustomerInfo(
    identifier: json['identifier']?.toString() ?? '-',
    address: json['address']?.toString() ?? '-',
    fatherName: json['father_name']?.toString(),
    cnicNo: json['cnic_no']?.toString(),
    city: json['city']?.toString() ?? '-',
    area: json['area']?.toString() ?? '-',
    isVerified: json['verified']?.toString() == '1',
  );
}

class OrderModel {
  final int id;
  final String uuid;
  final String status;
  final String portal;
  final int totalDealPrice;
  final int advancePrice;
  final int sourcingAgentFee;
  final int tenure;
  final double perMonthPercentage;
  final int outstandingPrincipal;
  final String createdAt;
  final ProductInfo product;
  final List<InstallmentItem> installments;
  final SellerInfo? seller; // nullable — supplier can be null from API

  const OrderModel({
    required this.id,
    required this.uuid,
    required this.status,
    required this.portal,
    required this.totalDealPrice,
    required this.advancePrice,
    required this.sourcingAgentFee,
    required this.tenure,
    required this.perMonthPercentage,
    required this.outstandingPrincipal,
    required this.createdAt,
    required this.product,
    required this.installments,
    this.seller,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
    id: _parseInt(json['id']),
    uuid: json['uuid']?.toString() ?? '',
    status: json['status']?.toString() ?? 'Pending',
    portal: json['portal']?.toString() ?? '-',
    totalDealPrice: _parseInt(json['total_deal_price']),
    advancePrice: _parseInt(json['advance_price']),
    sourcingAgentFee: _parseInt(json['sourcing_agent_fee']),
    tenure: _parseInt(json['tenure']),
    perMonthPercentage: _parseDouble(json['per_month_percentage']),
    outstandingPrincipal: _parseInt(json['outstanding_principal']),
    createdAt: json['created_at']?.toString() ?? '',
    product: json['product'] != null
        ? ProductInfo.fromJson(json['product'] as Map<String, dynamic>)
        : ProductInfo.empty(),
    installments: (json['installments'] as List? ?? [])
        .map((i) => InstallmentItem.fromJson(i as Map<String, dynamic>))
        .toList(),
    seller: json['seller'] != null
        ? SellerInfo.fromJson(json['seller'] as Map<String, dynamic>)
        : null,
  );

  // ── Status helpers ─────────────────────────────────────────────────────────
  bool get isApproved =>
      status.toLowerCase() == 'approved' ||
      status.toLowerCase() == 'instalments';

  bool get isCancelled => status.toLowerCase() == 'cancelled';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isOnInstalments => status.toLowerCase() == 'instalments';

  // ── Display helpers ────────────────────────────────────────────────────────
  String get orderNumber =>
      uuid.isNotEmpty ? '#${uuid.split('-').first.toUpperCase()}' : '#-';
  String get orderDate =>
      createdAt.isNotEmpty ? createdAt.split(' ').first : '-';
  String get totalDealAmount => 'PKR ${_fmt(totalDealPrice)}';
  String get advanceAmount => 'PKR ${_fmt(advancePrice)}';
  String get sourcingFee => 'PKR ${_fmt(sourcingAgentFee)}';
  String get installmentTenure => '$tenure months';
  String get monthlyPercent => '$perMonthPercentage%';
  String get productPrice => 'PKR ${_fmt(product.price)}';
  String get outstandingAmount => 'PKR ${_fmt(outstandingPrincipal)}';

  int get paidInstallments => installments.where((i) => i.isPaid).length;

  // ── Private parse helpers — never throw ───────────────────────────────────
  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static String _fmt(num v) {
    if (v >= 1000000) {
      return '${(v / 1000000).toStringAsFixed(1)}M';
    }
    if (v >= 1000) {
      final s = v.toStringAsFixed(0);
      final buf = StringBuffer();
      int count = 0;
      for (int i = s.length - 1; i >= 0; i--) {
        if (count > 0 && count % 3 == 0) buf.write(',');
        buf.write(s[i]);
        count++;
      }
      return buf.toString().split('').reversed.join();
    }
    return v.toStringAsFixed(0);
  }
}

class ProductInfo {
  final int id;
  final String title;
  final int price;
  final String? picture;

  const ProductInfo({
    required this.id,
    required this.title,
    required this.price,
    this.picture,
  });

  factory ProductInfo.empty() =>
      const ProductInfo(id: 0, title: 'Unknown Product', price: 0);

  factory ProductInfo.fromJson(Map<String, dynamic> json) => ProductInfo(
    id: OrderModel._parseInt(json['id']),
    title: json['title']?.toString() ?? 'Unknown Product',
    price: OrderModel._parseInt(json['price']),
    picture: json['picture']?.toString(),
  );
}

class InstallmentItem {
  final int? id;
  final String month;
  final int installmentPrice;
  final int installmentPaidPrice; // 0 when null from API
  final String? installmentDate;
  final String status;
  final String? paymentMethod;

  const InstallmentItem({
    this.id,
    required this.month,
    required this.installmentPrice,
    required this.installmentPaidPrice,
    this.installmentDate,
    required this.status,
    this.paymentMethod,
  });

  factory InstallmentItem.fromJson(Map<String, dynamic> json) =>
      InstallmentItem(
        id: json['id'] != null ? OrderModel._parseInt(json['id']) : null,
        month: json['month']?.toString() ?? '-',
        installmentPrice: OrderModel._parseInt(json['installment_price']),
        // API sends null for unpaid — treat as 0
        installmentPaidPrice: OrderModel._parseInt(
          json['installment_paid_price'],
        ),
        installmentDate: json['installment_date']?.toString(),
        status: json['status']?.toString() ?? 'Unpaid',
        paymentMethod: json['payment_method']?.toString(),
      );

  bool get isPaid => status.toLowerCase() == 'paid';

  String get installmentAmount => 'PKR ${OrderModel._fmt(installmentPrice)}';
  String get paidAmount => 'PKR ${OrderModel._fmt(installmentPaidPrice)}';
  String get outstandingAmount =>
      'PKR ${OrderModel._fmt(installmentPrice - installmentPaidPrice)}';
  String? get paidDate => installmentDate;
}

class SellerInfo {
  final String name;
  final String businessName;
  final String phone;

  const SellerInfo({
    required this.name,
    required this.businessName,
    required this.phone,
  });

  factory SellerInfo.fromJson(Map<String, dynamic> json) => SellerInfo(
    name: json['name']?.toString() ?? '-',
    businessName: json['business_name']?.toString() ?? '-',
    phone: json['phone']?.toString() ?? '-',
  );
}
