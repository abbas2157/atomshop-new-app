class SellerInstalmentsQuery {
  final int page;
  final String? status;

  const SellerInstalmentsQuery({this.page = 1, this.status});

  SellerInstalmentsQuery copyWith({
    int? page,
    String? status,
    bool clearStatus = false,
  }) {
    return SellerInstalmentsQuery(
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
    return other is SellerInstalmentsQuery &&
        other.page == page &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(page, status);
}

class SellerInstalmentsResponse {
  final List<SellerInstalment> instalments;
  final SellerInstalmentsPagination pagination;
  final List<SellerInstalmentCustomer> customers;
  final int totalPaid;
  final int totalUnpaid;

  const SellerInstalmentsResponse({
    required this.instalments,
    required this.pagination,
    required this.customers,
    required this.totalPaid,
    required this.totalUnpaid,
  });

  String get formattedTotalPaid => _money(totalPaid);
  String get formattedTotalUnpaid => _money(totalUnpaid);

  factory SellerInstalmentsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'])
        : <String, dynamic>{};
    final rawInstalments = data['instalments'] is Map
        ? Map<String, dynamic>.from(data['instalments'])
        : <String, dynamic>{};

    return SellerInstalmentsResponse(
      instalments: (rawInstalments['data'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                SellerInstalment.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
      pagination: SellerInstalmentsPagination.fromJson(rawInstalments),
      customers: (data['customers'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => SellerInstalmentCustomer.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(growable: false),
      totalPaid: _asInt(data['totalPaid']),
      totalUnpaid: _asInt(data['totalUnpaid']),
    );
  }
}

class SellerInstalmentsPagination {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final int? from;
  final int? to;

  const SellerInstalmentsPagination({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    this.from,
    this.to,
  });

  bool get hasPrevious => currentPage > 1;
  bool get hasNext => currentPage < lastPage;

  factory SellerInstalmentsPagination.fromJson(Map<String, dynamic> json) {
    return SellerInstalmentsPagination(
      currentPage: _asInt(json['current_page'], fallback: 1),
      lastPage: _asInt(json['last_page'], fallback: 1),
      perPage: _asInt(json['per_page']),
      total: _asInt(json['total']),
      from: json['from'] == null ? null : _asInt(json['from']),
      to: json['to'] == null ? null : _asInt(json['to']),
    );
  }
}

class SellerInstalment {
  final int id;
  final int userId;
  final int orderId;
  final String month;
  final int installmentPrice;
  final int installmentPaidPrice;
  final String receipt;
  final String paymentMethod;
  final String installmentDate;
  final String type;
  final String status;
  final int previousPending;
  final SellerInstalmentOrder order;

  const SellerInstalment({
    required this.id,
    required this.userId,
    required this.orderId,
    required this.month,
    required this.installmentPrice,
    required this.installmentPaidPrice,
    required this.receipt,
    required this.paymentMethod,
    required this.installmentDate,
    required this.type,
    required this.status,
    required this.previousPending,
    required this.order,
  });

  bool get paid => status.toLowerCase() == 'paid';
  bool get canPay => !paid;
  String get formattedPrice => _money(installmentPrice);
  String get formattedPaidPrice => _money(installmentPaidPrice);
  String get formattedPreviousPending => _money(previousPending);
  String get formattedDate => _date(installmentDate);
  String get productTitle => order.productTitle;

  factory SellerInstalment.fromJson(Map<String, dynamic> json) {
    return SellerInstalment(
      id: _asInt(json['id']),
      userId: _asInt(json['user_id']),
      orderId: _asInt(json['order_id']),
      month: _text(json['month']),
      installmentPrice: _asInt(json['installment_price']),
      installmentPaidPrice: _asInt(json['installment_paid_price']),
      receipt: _text(json['receipet'] ?? json['receipt']),
      paymentMethod: _text(json['payment_method']),
      installmentDate: _text(json['installment_date']),
      type: _text(json['type']),
      status: _text(json['status'], fallback: 'Unknown'),
      previousPending: _asInt(json['previous_pending']),
      order: SellerInstalmentOrder.fromJson(
        json['order'] is Map
            ? Map<String, dynamic>.from(json['order'])
            : <String, dynamic>{},
      ),
    );
  }
}

class SellerInstalmentOrder {
  final int id;
  final String uuid;
  final int userId;
  final int totalDealPrice;
  final int advancePrice;
  final int tenure;
  final String portal;
  final String status;
  final String productTitle;
  final String productImage;
  final String productPrNumber;

  const SellerInstalmentOrder({
    required this.id,
    required this.uuid,
    required this.userId,
    required this.totalDealPrice,
    required this.advancePrice,
    required this.tenure,
    required this.portal,
    required this.status,
    required this.productTitle,
    required this.productImage,
    required this.productPrNumber,
  });

  String get formattedTotalDealPrice => _money(totalDealPrice);

  factory SellerInstalmentOrder.fromJson(Map<String, dynamic> json) {
    final cart = json['cart'] is Map
        ? Map<String, dynamic>.from(json['cart'])
        : <String, dynamic>{};
    final product = cart['product'] is Map
        ? Map<String, dynamic>.from(cart['product'])
        : <String, dynamic>{};

    return SellerInstalmentOrder(
      id: _asInt(json['id']),
      uuid: _text(json['uuid']),
      userId: _asInt(json['user_id']),
      totalDealPrice: _asInt(json['total_deal_price']),
      advancePrice: _asInt(json['advance_price']),
      tenure: _asInt(json['instalment_tenure'] ?? cart['tenure']),
      portal: _text(json['portal']),
      status: _text(json['status'], fallback: 'Unknown'),
      productTitle: _text(product['title'], fallback: 'Product'),
      productImage: _text(product['product_picture'] ?? product['picture']),
      productPrNumber: _text(product['pr_number']),
    );
  }
}

class SellerInstalmentCustomer {
  final int id;
  final String name;

  const SellerInstalmentCustomer({required this.id, required this.name});

  factory SellerInstalmentCustomer.fromJson(Map<String, dynamic> json) {
    return SellerInstalmentCustomer(
      id: _asInt(json['id']),
      name: _text(json['name'], fallback: 'Customer'),
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
