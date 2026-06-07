// ============================================================
//  seller_instalments_model.dart
//
//  Models for the new "Instalments & Dues" API contract:
//  KPI-driven order list with server-computed stats
//  (c_paid/c_remaining/c_progress_pct/c_status/c_next_due),
//  a full per-order ledger, and an invoice-data shape.
// ============================================================

class SellerInstalmentsQuery {
  final String q;
  final int? customer;
  final String filterStatus; // all | active | overdue | completed
  final int? month;
  final int? year;
  final int page;

  const SellerInstalmentsQuery({
    this.q = '',
    this.customer,
    this.filterStatus = 'all',
    this.month,
    this.year,
    this.page = 1,
  });

  SellerInstalmentsQuery copyWith({
    String? q,
    int? customer,
    String? filterStatus,
    int? month,
    int? year,
    int? page,
    bool clearMonth = false,
    bool clearYear = false,
  }) {
    return SellerInstalmentsQuery(
      q: q ?? this.q,
      customer: customer ?? this.customer,
      filterStatus: filterStatus ?? this.filterStatus,
      month: clearMonth ? null : (month ?? this.month),
      year: clearYear ? null : (year ?? this.year),
      page: page ?? this.page,
    );
  }

  Map<String, String> toQueryParameters() {
    final params = <String, String>{'page': page.toString()};
    final query = q.trim();
    if (query.isNotEmpty) params['q'] = query;
    if (customer != null) params['customer'] = customer.toString();
    if (filterStatus.trim().isNotEmpty && filterStatus != 'all') {
      params['filter_status'] = filterStatus;
    }
    if (month != null) params['month'] = month.toString();
    if (year != null) params['year'] = year.toString();
    return params;
  }

  @override
  bool operator ==(Object other) {
    return other is SellerInstalmentsQuery &&
        other.q == q &&
        other.customer == customer &&
        other.filterStatus == filterStatus &&
        other.month == month &&
        other.year == year &&
        other.page == page;
  }

  @override
  int get hashCode =>
      Object.hash(q, customer, filterStatus, month, year, page);
}

// ═══════════════════════════════════════════════════════════
//  PAGINATION (Laravel-style — unchanged shape)
// ═══════════════════════════════════════════════════════════
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

// ═══════════════════════════════════════════════════════════
//  LIST RESPONSE — KPIs + paginated order summaries
// ═══════════════════════════════════════════════════════════
class SellerInstalmentsListResponse {
  final SellerInstalmentKpi kpi;
  final List<SellerInstalmentOrderSummary> orders;
  final SellerInstalmentsPagination pagination;

  const SellerInstalmentsListResponse({
    required this.kpi,
    required this.orders,
    required this.pagination,
  });

  factory SellerInstalmentsListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'])
        : <String, dynamic>{};
    final ordersPage = data['orders'] is Map
        ? Map<String, dynamic>.from(data['orders'])
        : <String, dynamic>{};

    return SellerInstalmentsListResponse(
      kpi: SellerInstalmentKpi.fromJson(
        data['kpi'] is Map
            ? Map<String, dynamic>.from(data['kpi'])
            : <String, dynamic>{},
      ),
      orders: (ordersPage['data'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => SellerInstalmentOrderSummary.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(growable: false),
      pagination: SellerInstalmentsPagination.fromJson(ordersPage),
    );
  }
}

class SellerInstalmentKpi {
  final int totalOrders;
  final int totalPending;
  final int collectedThisMonth;
  final int overdueCount;

  const SellerInstalmentKpi({
    required this.totalOrders,
    required this.totalPending,
    required this.collectedThisMonth,
    required this.overdueCount,
  });

  String get formattedTotalPending => formatPKR(totalPending);
  String get formattedCollectedThisMonth => formatPKR(collectedThisMonth);

  factory SellerInstalmentKpi.fromJson(Map<String, dynamic> json) {
    return SellerInstalmentKpi(
      totalOrders: _asInt(json['total_orders']),
      totalPending: _asInt(json['total_pending']),
      collectedThisMonth: _asInt(json['collected_this_month']),
      overdueCount: _asInt(json['overdue_count']),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  USER / PRODUCT / "NEXT DUE" ROW — shared lightweight shapes
// ═══════════════════════════════════════════════════════════
class SellerInstalmentUser {
  final int id;
  final String name;
  final String phone;
  final String uuid;
  final SellerInstalmentCustomerInfo? customer;

  const SellerInstalmentUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.uuid,
    this.customer,
  });

  factory SellerInstalmentUser.fromJson(Map<String, dynamic> json) {
    return SellerInstalmentUser(
      id: _asInt(json['id']),
      name: _text(json['name'], fallback: 'Customer'),
      phone: _text(json['phone']),
      uuid: _text(json['uuid']),
      customer: json['customer'] is Map
          ? SellerInstalmentCustomerInfo.fromJson(
              Map<String, dynamic>.from(json['customer']),
            )
          : null,
    );
  }
}

class SellerInstalmentCustomerInfo {
  final String identifier;
  final String cnicNo;
  final String address;
  final String alternatePhone;
  final String city;
  final String area;

  const SellerInstalmentCustomerInfo({
    required this.identifier,
    required this.cnicNo,
    required this.address,
    required this.alternatePhone,
    required this.city,
    required this.area,
  });

  factory SellerInstalmentCustomerInfo.fromJson(Map<String, dynamic> json) {
    final city = json['city'] is Map
        ? Map<String, dynamic>.from(json['city'])
        : <String, dynamic>{};
    final area = json['area'] is Map
        ? Map<String, dynamic>.from(json['area'])
        : <String, dynamic>{};

    return SellerInstalmentCustomerInfo(
      identifier: _text(json['identifier']),
      cnicNo: _text(json['cnic_no']),
      address: _text(json['address']),
      alternatePhone: _text(json['alternate_phone']),
      city: _text(city['title']),
      area: _text(area['title']),
    );
  }
}

class SellerInstalmentProduct {
  final int id;
  final String title;
  final String prNumber;
  final String picture;

  const SellerInstalmentProduct({
    required this.id,
    required this.title,
    required this.prNumber,
    required this.picture,
  });

  factory SellerInstalmentProduct.fromJson(Map<String, dynamic> json) {
    return SellerInstalmentProduct(
      id: _asInt(json['id']),
      title: _text(json['title'], fallback: 'Product'),
      prNumber: _text(json['pr_number']),
      picture: _text(json['picture']),
    );
  }
}

/// Light instalment record — used for `c_next_due` and `next_instalment`.
class SellerInstalmentRow {
  final int id;
  final int orderId;
  final String month;
  final int installmentPrice;
  final String installmentDate;
  final String type;
  final String status;

  const SellerInstalmentRow({
    required this.id,
    required this.orderId,
    required this.month,
    required this.installmentPrice,
    required this.installmentDate,
    required this.type,
    required this.status,
  });

  String get formattedPrice => formatPKR(installmentPrice);
  String get formattedDate => _date(installmentDate);

  factory SellerInstalmentRow.fromJson(Map<String, dynamic> json) {
    return SellerInstalmentRow(
      id: _asInt(json['id']),
      orderId: _asInt(json['order_id']),
      month: _text(json['month']),
      installmentPrice: _asInt(json['installment_price']),
      installmentDate: _text(json['installment_date']),
      type: _text(json['type']),
      status: _text(json['status'], fallback: 'Unpaid'),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  ORDER SUMMARY — list-screen card data
// ═══════════════════════════════════════════════════════════
class SellerInstalmentOrderSummary {
  final int id;
  final int totalDealPrice;
  final int advancePrice;
  final int tenure;
  final String status;
  final String createdAt;
  final SellerInstalmentUser user;
  final SellerInstalmentProduct product;
  final int cPaid;
  final int cRemaining;
  final int cProgressPct;
  final String cStatus;
  final SellerInstalmentRow? cNextDue;

  const SellerInstalmentOrderSummary({
    required this.id,
    required this.totalDealPrice,
    required this.advancePrice,
    required this.tenure,
    required this.status,
    required this.createdAt,
    required this.user,
    required this.product,
    required this.cPaid,
    required this.cRemaining,
    required this.cProgressPct,
    required this.cStatus,
    this.cNextDue,
  });

  String get formattedOrderNo => formatOrderNo(id);
  String get formattedTotalDealPrice => formatPKR(totalDealPrice);
  String get formattedPaid => formatPKR(cPaid);
  String get formattedRemaining => formatPKR(cRemaining);
  double get progressFraction => (cProgressPct.clamp(0, 100)) / 100;

  factory SellerInstalmentOrderSummary.fromJson(Map<String, dynamic> json) {
    return SellerInstalmentOrderSummary(
      id: _asInt(json['id']),
      totalDealPrice: _asInt(json['total_deal_price']),
      advancePrice: _asInt(json['advance_price']),
      tenure: _asInt(json['tenure']),
      status: _text(json['status'], fallback: 'Unknown'),
      createdAt: _text(json['created_at']),
      user: SellerInstalmentUser.fromJson(
        json['user'] is Map
            ? Map<String, dynamic>.from(json['user'])
            : <String, dynamic>{},
      ),
      product: SellerInstalmentProduct.fromJson(
        json['product'] is Map
            ? Map<String, dynamic>.from(json['product'])
            : <String, dynamic>{},
      ),
      cPaid: _asInt(json['c_paid']),
      cRemaining: _asInt(json['c_remaining']),
      cProgressPct: _asInt(json['c_progress_pct']),
      cStatus: _text(json['c_status'], fallback: 'Active'),
      cNextDue: json['c_next_due'] is Map
          ? SellerInstalmentRow.fromJson(
              Map<String, dynamic>.from(json['c_next_due']),
            )
          : null,
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  ORDER DETAIL — full ledger screen data
// ═══════════════════════════════════════════════════════════
class SellerInstalmentOrderDetail {
  final SellerInstalmentOrderFull order;
  final List<SellerLedgerEntry> ledger;
  final int totalPaid;
  final int remaining;
  final int progressPct;
  final String orderStatus;
  final SellerInstalmentRow? nextInstalment;
  final SellerInstalmentSellerInfo seller;

  const SellerInstalmentOrderDetail({
    required this.order,
    required this.ledger,
    required this.totalPaid,
    required this.remaining,
    required this.progressPct,
    required this.orderStatus,
    required this.seller,
    this.nextInstalment,
  });

  String get formattedTotalPaid => formatPKR(totalPaid);
  String get formattedRemaining => formatPKR(remaining);
  double get progressFraction => (progressPct.clamp(0, 100)) / 100;
  bool get isCleared => remaining <= 0;

  factory SellerInstalmentOrderDetail.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'])
        : <String, dynamic>{};

    return SellerInstalmentOrderDetail(
      order: SellerInstalmentOrderFull.fromJson(
        data['order'] is Map
            ? Map<String, dynamic>.from(data['order'])
            : <String, dynamic>{},
      ),
      ledger: (data['ledger'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                SellerLedgerEntry.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
      totalPaid: _asInt(data['total_paid']),
      remaining: _asInt(data['remaining']),
      progressPct: _asInt(data['progress_pct']),
      orderStatus: _text(data['order_status'], fallback: 'Active'),
      nextInstalment: data['next_instalment'] is Map
          ? SellerInstalmentRow.fromJson(
              Map<String, dynamic>.from(data['next_instalment']),
            )
          : null,
      seller: SellerInstalmentSellerInfo.fromJson(
        data['seller'] is Map
            ? Map<String, dynamic>.from(data['seller'])
            : <String, dynamic>{},
      ),
    );
  }
}

class SellerInstalmentOrderFull {
  final int id;
  final int totalDealPrice;
  final int advancePrice;
  final int tenure;
  final String status;
  final String createdAt;
  final SellerInstalmentUser user;
  final SellerInstalmentProduct product;

  const SellerInstalmentOrderFull({
    required this.id,
    required this.totalDealPrice,
    required this.advancePrice,
    required this.tenure,
    required this.status,
    required this.createdAt,
    required this.user,
    required this.product,
  });

  String get formattedOrderNo => formatOrderNo(id);
  String get formattedTotalDealPrice => formatPKR(totalDealPrice);
  String get formattedAdvancePrice => formatPKR(advancePrice);

  /// `Monthly Instalment = (total_deal_price - advance_price) / tenure`
  String get formattedMonthlyInstalment {
    if (tenure <= 0) return formatPKR(0);
    return formatPKR(((totalDealPrice - advancePrice) / tenure).round());
  }

  factory SellerInstalmentOrderFull.fromJson(Map<String, dynamic> json) {
    return SellerInstalmentOrderFull(
      id: _asInt(json['id']),
      totalDealPrice: _asInt(json['total_deal_price']),
      advancePrice: _asInt(json['advance_price']),
      tenure: _asInt(json['tenure']),
      status: _text(json['status'], fallback: 'Unknown'),
      createdAt: _text(json['created_at']),
      user: SellerInstalmentUser.fromJson(
        json['user'] is Map
            ? Map<String, dynamic>.from(json['user'])
            : <String, dynamic>{},
      ),
      product: SellerInstalmentProduct.fromJson(
        json['product'] is Map
            ? Map<String, dynamic>.from(json['product'])
            : <String, dynamic>{},
      ),
    );
  }
}

class SellerLedgerEntry {
  final String date;
  final String desc;
  final int debit;
  final int credit;
  final int balance;
  final String rowType;
  final bool paid;
  final bool overdue;
  final int? instId;
  final String? month;
  final String? type;
  final String? status;
  final String? paymentMethod;
  final String? installmentDate;

  const SellerLedgerEntry({
    required this.date,
    required this.desc,
    required this.debit,
    required this.credit,
    required this.balance,
    required this.rowType,
    required this.paid,
    required this.overdue,
    this.instId,
    this.month,
    this.type,
    this.status,
    this.paymentMethod,
    this.installmentDate,
  });

  String get formattedDebit => debit > 0 ? formatPKR(debit) : '—';
  String get formattedCredit => credit > 0 ? formatPKR(credit) : '—';
  String get formattedBalance => formatPKR(balance);

  factory SellerLedgerEntry.fromJson(Map<String, dynamic> json) {
    return SellerLedgerEntry(
      date: _text(json['date']),
      desc: _text(json['desc'], fallback: 'Transaction'),
      debit: _asInt(json['debit']),
      credit: _asInt(json['credit']),
      balance: _asInt(json['balance']),
      rowType: _text(json['row_type']),
      paid: json['paid'] == true,
      overdue: json['overdue'] == true,
      instId: json['inst_id'] == null ? null : _asInt(json['inst_id']),
      month: json['month']?.toString(),
      type: json['type']?.toString(),
      status: json['status']?.toString(),
      paymentMethod: json['payment_method']?.toString(),
      installmentDate: json['installment_date']?.toString(),
    );
  }
}

class SellerInstalmentSellerInfo {
  final String name;
  final String businessName;

  const SellerInstalmentSellerInfo({
    required this.name,
    required this.businessName,
  });

  factory SellerInstalmentSellerInfo.fromJson(Map<String, dynamic> json) {
    return SellerInstalmentSellerInfo(
      name: _text(json['name'], fallback: 'Seller'),
      businessName: _text(json['business_name'], fallback: 'Business'),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  INVOICE DATA — client-rendered invoice screen
// ═══════════════════════════════════════════════════════════
class SellerInstalmentInvoiceData {
  final SellerInstalmentInvoiceInstalment instalment;
  final SellerInstalmentSellerInfo seller;
  final int totalPaid;
  final int remaining;

  const SellerInstalmentInvoiceData({
    required this.instalment,
    required this.seller,
    required this.totalPaid,
    required this.remaining,
  });

  /// `INV-{year}-{inst_id padded to 4 digits}`
  String get invoiceNumber {
    final year = _yearOf(instalment.installmentPaidDate);
    return 'INV-$year-${instalment.id.toString().padLeft(4, '0')}';
  }

  String get formattedTotalPaid => formatPKR(totalPaid);
  String get formattedRemaining => formatPKR(remaining);

  factory SellerInstalmentInvoiceData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'])
        : <String, dynamic>{};

    return SellerInstalmentInvoiceData(
      instalment: SellerInstalmentInvoiceInstalment.fromJson(
        data['instalment'] is Map
            ? Map<String, dynamic>.from(data['instalment'])
            : <String, dynamic>{},
      ),
      seller: SellerInstalmentSellerInfo.fromJson(
        data['seller'] is Map
            ? Map<String, dynamic>.from(data['seller'])
            : <String, dynamic>{},
      ),
      totalPaid: _asInt(data['total_paid']),
      remaining: _asInt(data['remaining']),
    );
  }
}

class SellerInstalmentInvoiceInstalment {
  final int id;
  final int orderId;
  final String month;
  final int installmentPrice;
  final int installmentPaidPrice;
  final String installmentPaidDate;
  final String paymentMethod;
  final String receipt;
  final String type;
  final String status;
  final SellerInstalmentInvoiceOrder customOrder;
  final SellerInstalmentUser user;

  const SellerInstalmentInvoiceInstalment({
    required this.id,
    required this.orderId,
    required this.month,
    required this.installmentPrice,
    required this.installmentPaidPrice,
    required this.installmentPaidDate,
    required this.paymentMethod,
    required this.receipt,
    required this.type,
    required this.status,
    required this.customOrder,
    required this.user,
  });

  String get formattedInstallmentPaidPrice => formatPKR(installmentPaidPrice);
  String get formattedDate => _date(installmentPaidDate);

  factory SellerInstalmentInvoiceInstalment.fromJson(
    Map<String, dynamic> json,
  ) {
    return SellerInstalmentInvoiceInstalment(
      id: _asInt(json['id']),
      orderId: _asInt(json['order_id']),
      month: _text(json['month']),
      installmentPrice: _asInt(json['installment_price']),
      installmentPaidPrice: _asInt(json['installment_paid_price']),
      installmentPaidDate: _text(json['installment_paid_date']),
      paymentMethod: _text(json['payment_method']),
      // `receipet` is an intentional backend typo — do not rename.
      receipt: _text(json['receipet'] ?? json['receipt']),
      type: _text(json['type']),
      status: _text(json['status'], fallback: 'Paid'),
      customOrder: SellerInstalmentInvoiceOrder.fromJson(
        json['custom_order'] is Map
            ? Map<String, dynamic>.from(json['custom_order'])
            : <String, dynamic>{},
      ),
      user: SellerInstalmentUser.fromJson(
        json['user'] is Map
            ? Map<String, dynamic>.from(json['user'])
            : <String, dynamic>{},
      ),
    );
  }
}

class SellerInstalmentInvoiceOrder {
  final int id;
  final int totalDealPrice;
  final int advancePrice;
  final int tenure;
  final SellerInstalmentProduct product;

  const SellerInstalmentInvoiceOrder({
    required this.id,
    required this.totalDealPrice,
    required this.advancePrice,
    required this.tenure,
    required this.product,
  });

  String get formattedTotalDealPrice => formatPKR(totalDealPrice);

  factory SellerInstalmentInvoiceOrder.fromJson(Map<String, dynamic> json) {
    return SellerInstalmentInvoiceOrder(
      id: _asInt(json['id']),
      totalDealPrice: _asInt(json['total_deal_price']),
      advancePrice: _asInt(json['advance_price']),
      tenure: _asInt(json['tenure']),
      product: SellerInstalmentProduct.fromJson(
        json['product'] is Map
            ? Map<String, dynamic>.from(json['product'])
            : <String, dynamic>{},
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  SHARED FORMATTING HELPERS
// ═══════════════════════════════════════════════════════════

/// `ORD-` + zero-padded to 4 digits, e.g. `ORD-0101`.
String formatOrderNo(int id) => 'ORD-${id.toString().padLeft(4, '0')}';

/// `Rs. 75,000` — values are always whole-number Pakistani Rupees.
String formatPKR(int amount) => 'Rs. ${_withCommas(amount)}';

int _yearOf(String date) {
  final match = RegExp(r'(\d{4})').firstMatch(date);
  if (match == null) return DateTime.now().year;
  return int.tryParse(match.group(1)!) ?? DateTime.now().year;
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

String _withCommas(int value) {
  final negative = value < 0;
  final text = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final remaining = text.length - i;
    buffer.write(text[i]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write(',');
  }
  return negative ? '-${buffer.toString()}' : buffer.toString();
}
