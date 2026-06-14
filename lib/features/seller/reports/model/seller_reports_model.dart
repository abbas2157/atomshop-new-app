// ─── Shared report customer ───────────────────────────────────────────────────

class ReportCustomer {
  final int id;
  final String name;
  final String phone;

  const ReportCustomer({
    required this.id,
    required this.name,
    required this.phone,
  });

  factory ReportCustomer.fromJson(Map<String, dynamic> json) {
    return ReportCustomer(
      id: _asInt(json['id']),
      name: _text(json['name'], fallback: 'Customer'),
      phone: _text(json['phone']),
    );
  }
}

// ─── 1. Recovery Sheet ────────────────────────────────────────────────────────

class RecoverySheetQuery {
  final String status;
  final String q;

  const RecoverySheetQuery({
    this.status = 'active',
    this.q = '',
  });

  RecoverySheetQuery copyWith({String? status, String? q}) {
    return RecoverySheetQuery(
      status: status ?? this.status,
      q: q ?? this.q,
    );
  }

  Map<String, String> toQueryParameters() {
    final params = <String, String>{};
    if (status.trim().isNotEmpty) params['status'] = status.trim();
    if (q.trim().isNotEmpty) params['q'] = q.trim();
    return params;
  }

  @override
  bool operator ==(Object other) =>
      other is RecoverySheetQuery &&
      other.status == status &&
      other.q == q;

  @override
  int get hashCode => Object.hash(status, q);
}

class RecoverySheetResponse {
  final List<RecoverySheetRow> rows;
  final RecoverySheetTotals totals;

  const RecoverySheetResponse({required this.rows, required this.totals});

  factory RecoverySheetResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'])
        : <String, dynamic>{};
    return RecoverySheetResponse(
      rows: (data['rows'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => RecoverySheetRow.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false),
      totals: RecoverySheetTotals.fromJson(
        data['totals'] is Map
            ? Map<String, dynamic>.from(data['totals'])
            : <String, dynamic>{},
      ),
    );
  }
}

class RecoverySheetTotals {
  final int count;
  final int total;
  final int paid;
  final int remaining;
  final int overdue;

  const RecoverySheetTotals({
    required this.count,
    required this.total,
    required this.paid,
    required this.remaining,
    required this.overdue,
  });

  String get formattedTotal => _money(total);
  String get formattedPaid => _money(paid);
  String get formattedRemaining => _money(remaining);
  String get formattedOverdue => _money(overdue);

  factory RecoverySheetTotals.fromJson(Map<String, dynamic> json) {
    return RecoverySheetTotals(
      count: _asInt(json['count']),
      total: _asInt(json['total']),
      paid: _asInt(json['paid']),
      remaining: _asInt(json['remaining']),
      overdue: _asInt(json['overdue']),
    );
  }
}

class RecoverySheetRow {
  final int orderId;
  final String orderNo;
  final String date;
  final String customerName;
  final String customerPhone;
  final String productTitle;
  final String prNumber;
  final int totalAmount;
  final int amountPaid;
  final int amountRemaining;
  final int instalmentsDue;
  final int overdueAmount;
  final String nextDueDate;
  final int nextDueAmount;
  final String recoveryStatus;
  final String orderStatus;
  final int tenure;

  const RecoverySheetRow({
    required this.orderId,
    required this.orderNo,
    required this.date,
    required this.customerName,
    required this.customerPhone,
    required this.productTitle,
    required this.prNumber,
    required this.totalAmount,
    required this.amountPaid,
    required this.amountRemaining,
    required this.instalmentsDue,
    required this.overdueAmount,
    required this.nextDueDate,
    required this.nextDueAmount,
    required this.recoveryStatus,
    required this.orderStatus,
    required this.tenure,
  });

  String get formattedTotalAmount => _money(totalAmount);
  String get formattedAmountPaid => _money(amountPaid);
  String get formattedAmountRemaining => _money(amountRemaining);
  String get formattedOverdueAmount => _money(overdueAmount);
  String get formattedNextDueAmount => _money(nextDueAmount);

  factory RecoverySheetRow.fromJson(Map<String, dynamic> json) {
    return RecoverySheetRow(
      orderId: _asInt(json['order_id']),
      orderNo: _text(json['order_no']),
      date: _date(json['date']),
      customerName: _text(json['customer_name'], fallback: 'Customer'),
      customerPhone: _text(json['customer_phone']),
      productTitle: _text(json['product_title']),
      prNumber: _text(json['pr_number']),
      totalAmount: _asInt(json['total_amount']),
      amountPaid: _asInt(json['amount_paid']),
      amountRemaining: _asInt(json['amount_remaining']),
      instalmentsDue: _asInt(json['instalments_due']),
      overdueAmount: _asInt(json['overdue_amount']),
      nextDueDate: _date(json['next_due_date']),
      nextDueAmount: _asInt(json['next_due_amount']),
      recoveryStatus: _text(json['recovery_status']),
      orderStatus: _text(json['order_status']),
      tenure: _asInt(json['tenure']),
    );
  }
}

// ─── 2. Customer Ledger ───────────────────────────────────────────────────────

class CustomerLedgerQuery {
  final int customerId;
  final int month;
  final int year;

  const CustomerLedgerQuery({
    required this.customerId,
    required this.month,
    required this.year,
  });

  CustomerLedgerQuery copyWith({int? customerId, int? month, int? year}) {
    return CustomerLedgerQuery(
      customerId: customerId ?? this.customerId,
      month: month ?? this.month,
      year: year ?? this.year,
    );
  }

  Map<String, String> toQueryParameters() {
    return {
      'customer_id': customerId.toString(),
      'month': month.toString(),
      'year': year.toString(),
    };
  }

  @override
  bool operator ==(Object other) =>
      other is CustomerLedgerQuery &&
      other.customerId == customerId &&
      other.month == month &&
      other.year == year;

  @override
  int get hashCode => Object.hash(customerId, month, year);
}

class CustomerLedgerResponse {
  final ReportCustomer customer;
  final String period;
  final int openingBalance;
  final List<LedgerEntry> entries;
  final int closingBalance;
  final int totalDebit;
  final int totalCredit;

  const CustomerLedgerResponse({
    required this.customer,
    required this.period,
    required this.openingBalance,
    required this.entries,
    required this.closingBalance,
    required this.totalDebit,
    required this.totalCredit,
  });

  String get formattedOpeningBalance => _money(openingBalance);
  String get formattedClosingBalance => _money(closingBalance);
  String get formattedTotalDebit => _money(totalDebit);
  String get formattedTotalCredit => _money(totalCredit);

  factory CustomerLedgerResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'])
        : <String, dynamic>{};
    return CustomerLedgerResponse(
      customer: ReportCustomer.fromJson(
        data['customer'] is Map
            ? Map<String, dynamic>.from(data['customer'])
            : <String, dynamic>{},
      ),
      period: _text(data['period']),
      openingBalance: _asInt(data['opening_balance']),
      entries: (data['entries'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => LedgerEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false),
      closingBalance: _asInt(data['closing_balance']),
      totalDebit: _asInt(data['total_debit']),
      totalCredit: _asInt(data['total_credit']),
    );
  }
}

class LedgerEntry {
  final String date;
  final String narration;
  final int debit;
  final int credit;
  final int balance;

  const LedgerEntry({
    required this.date,
    required this.narration,
    required this.debit,
    required this.credit,
    required this.balance,
  });

  String get formattedDebit => _money(debit);
  String get formattedCredit => _money(credit);
  String get formattedBalance => _money(balance);

  factory LedgerEntry.fromJson(Map<String, dynamic> json) {
    return LedgerEntry(
      date: _date(json['date']),
      narration: _text(json['narration']),
      debit: _asInt(json['debit']),
      credit: _asInt(json['credit']),
      balance: _asInt(json['balance']),
    );
  }
}

// ─── 3. Aging Report ──────────────────────────────────────────────────────────

class AgingResponse {
  final Map<String, AgingBucket> buckets;
  final int total;
  final int count;

  const AgingResponse({
    required this.buckets,
    required this.total,
    required this.count,
  });

  String get formattedTotal => _money(total);

  factory AgingResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'])
        : <String, dynamic>{};
    final rawBuckets = data['buckets'];
    final bucketsMap = <String, AgingBucket>{};
    if (rawBuckets is Map) {
      rawBuckets.forEach((key, value) {
        if (value is Map) {
          bucketsMap[key.toString()] =
              AgingBucket.fromJson(Map<String, dynamic>.from(value));
        }
      });
    }
    return AgingResponse(
      buckets: bucketsMap,
      total: _asInt(data['total']),
      count: _asInt(data['count']),
    );
  }
}

class AgingBucket {
  final String label;
  final List<AgingRow> rows;
  final int total;
  final int count;

  const AgingBucket({
    required this.label,
    required this.rows,
    required this.total,
    required this.count,
  });

  String get formattedTotal => _money(total);

  factory AgingBucket.fromJson(Map<String, dynamic> json) {
    return AgingBucket(
      label: _text(json['label']),
      rows: (json['rows'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => AgingRow.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false),
      total: _asInt(json['total']),
      count: _asInt(json['count']),
    );
  }
}

class AgingRow {
  final int days;
  final String dueDate;
  final String customerName;
  final String customerPhone;
  final String productTitle;
  final String orderNo;
  final String month;
  final int amount;

  const AgingRow({
    required this.days,
    required this.dueDate,
    required this.customerName,
    required this.customerPhone,
    required this.productTitle,
    required this.orderNo,
    required this.month,
    required this.amount,
  });

  String get formattedAmount => _money(amount);

  factory AgingRow.fromJson(Map<String, dynamic> json) {
    return AgingRow(
      days: _asInt(json['days']),
      dueDate: _date(json['due_date']),
      customerName: _text(json['customer_name'], fallback: 'Customer'),
      customerPhone: _text(json['customer_phone']),
      productTitle: _text(json['product_title']),
      orderNo: _text(json['order_no']),
      month: _text(json['month']),
      amount: _asInt(json['amount']),
    );
  }
}

// ─── 4. Upcoming Dues ─────────────────────────────────────────────────────────

class UpcomingDuesQuery {
  final int days;

  const UpcomingDuesQuery({this.days = 7});

  UpcomingDuesQuery copyWith({int? days}) {
    return UpcomingDuesQuery(days: days ?? this.days);
  }

  Map<String, String> toQueryParameters() {
    return {'days': days.toString()};
  }

  @override
  bool operator ==(Object other) =>
      other is UpcomingDuesQuery && other.days == days;

  @override
  int get hashCode => days.hashCode;
}

class UpcomingDuesResponse {
  final List<UpcomingDueRow> rows;
  final int total;
  final int count;
  final int days;

  const UpcomingDuesResponse({
    required this.rows,
    required this.total,
    required this.count,
    required this.days,
  });

  String get formattedTotal => _money(total);

  factory UpcomingDuesResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'])
        : <String, dynamic>{};
    return UpcomingDuesResponse(
      rows: (data['rows'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => UpcomingDueRow.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false),
      total: _asInt(data['total']),
      count: _asInt(data['count']),
      days: _asInt(data['days']),
    );
  }
}

class UpcomingDueRow {
  final String dueDate;
  final int daysLeft;
  final String urgency;
  final String customerName;
  final String customerPhone;
  final String productTitle;
  final String orderNo;
  final String month;
  final int amount;

  const UpcomingDueRow({
    required this.dueDate,
    required this.daysLeft,
    required this.urgency,
    required this.customerName,
    required this.customerPhone,
    required this.productTitle,
    required this.orderNo,
    required this.month,
    required this.amount,
  });

  String get formattedAmount => _money(amount);

  factory UpcomingDueRow.fromJson(Map<String, dynamic> json) {
    return UpcomingDueRow(
      dueDate: _date(json['due_date']),
      daysLeft: _asInt(json['days_left']),
      urgency: _text(json['urgency']),
      customerName: _text(json['customer_name'], fallback: 'Customer'),
      customerPhone: _text(json['customer_phone']),
      productTitle: _text(json['product_title']),
      orderNo: _text(json['order_no']),
      month: _text(json['month']),
      amount: _asInt(json['amount']),
    );
  }
}

// ─── 5. Defaulters ────────────────────────────────────────────────────────────

class DefaultersQuery {
  final int missed;

  const DefaultersQuery({this.missed = 2});

  DefaultersQuery copyWith({int? missed}) {
    return DefaultersQuery(missed: missed ?? this.missed);
  }

  Map<String, String> toQueryParameters() {
    return {'missed': missed.toString()};
  }

  @override
  bool operator ==(Object other) =>
      other is DefaultersQuery && other.missed == missed;

  @override
  int get hashCode => missed.hashCode;
}

class DefaultersResponse {
  final List<DefaulterRow> rows;
  final int count;
  final int totalOverdue;

  const DefaultersResponse({
    required this.rows,
    required this.count,
    required this.totalOverdue,
  });

  String get formattedTotalOverdue => _money(totalOverdue);

  factory DefaultersResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'])
        : <String, dynamic>{};
    return DefaultersResponse(
      rows: (data['rows'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => DefaulterRow.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false),
      count: _asInt(data['count']),
      totalOverdue: _asInt(data['total_overdue']),
    );
  }
}

class DefaulterRow {
  final int orderId;
  final String orderNo;
  final String customerName;
  final String customerPhone;
  final String productTitle;
  final int totalDeal;
  final int totalPaid;
  final int overdueAmount;
  final int missedCount;
  final String oldestDue;
  final int daysSince;
  final String severity;

  const DefaulterRow({
    required this.orderId,
    required this.orderNo,
    required this.customerName,
    required this.customerPhone,
    required this.productTitle,
    required this.totalDeal,
    required this.totalPaid,
    required this.overdueAmount,
    required this.missedCount,
    required this.oldestDue,
    required this.daysSince,
    required this.severity,
  });

  String get formattedTotalDeal => _money(totalDeal);
  String get formattedTotalPaid => _money(totalPaid);
  String get formattedOverdueAmount => _money(overdueAmount);

  factory DefaulterRow.fromJson(Map<String, dynamic> json) {
    return DefaulterRow(
      orderId: _asInt(json['order_id']),
      orderNo: _text(json['order_no']),
      customerName: _text(json['customer_name'], fallback: 'Customer'),
      customerPhone: _text(json['customer_phone']),
      productTitle: _text(json['product_title']),
      totalDeal: _asInt(json['total_deal']),
      totalPaid: _asInt(json['total_paid']),
      overdueAmount: _asInt(json['overdue_amount']),
      missedCount: _asInt(json['missed_count']),
      oldestDue: _date(json['oldest_due']),
      daysSince: _asInt(json['days_since']),
      severity: _text(json['severity']),
    );
  }
}

// ─── 6. Collection ────────────────────────────────────────────────────────────

class CollectionQuery {
  final String mode;
  final String from;
  final String to;

  const CollectionQuery({
    this.mode = 'daily',
    required this.from,
    required this.to,
  });

  CollectionQuery copyWith({String? mode, String? from, String? to}) {
    return CollectionQuery(
      mode: mode ?? this.mode,
      from: from ?? this.from,
      to: to ?? this.to,
    );
  }

  Map<String, String> toQueryParameters() {
    final params = <String, String>{};
    if (mode.trim().isNotEmpty) params['mode'] = mode.trim();
    if (from.trim().isNotEmpty) params['from'] = from.trim();
    if (to.trim().isNotEmpty) params['to'] = to.trim();
    return params;
  }

  @override
  bool operator ==(Object other) =>
      other is CollectionQuery &&
      other.mode == mode &&
      other.from == from &&
      other.to == to;

  @override
  int get hashCode => Object.hash(mode, from, to);
}

class CollectionResponse {
  final List<CollectionRow> rows;
  final int total;
  final int count;
  final Map<String, CollectionMethod> methods;

  const CollectionResponse({
    required this.rows,
    required this.total,
    required this.count,
    required this.methods,
  });

  String get formattedTotal => _money(total);

  factory CollectionResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'])
        : <String, dynamic>{};
    final rawMethods = data['methods'];
    final methodsMap = <String, CollectionMethod>{};
    if (rawMethods is Map) {
      rawMethods.forEach((key, value) {
        if (value is Map) {
          methodsMap[key.toString()] =
              CollectionMethod.fromJson(Map<String, dynamic>.from(value));
        }
      });
    }
    return CollectionResponse(
      rows: (data['rows'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => CollectionRow.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false),
      total: _asInt(data['total']),
      count: _asInt(data['count']),
      methods: methodsMap,
    );
  }
}

class CollectionRow {
  final String period;
  final String sortKey;
  final int count;
  final int total;
  final int cash;
  final int online;
  final int other;

  const CollectionRow({
    required this.period,
    required this.sortKey,
    required this.count,
    required this.total,
    required this.cash,
    required this.online,
    required this.other,
  });

  String get formattedTotal => _money(total);
  String get formattedCash => _money(cash);
  String get formattedOnline => _money(online);
  String get formattedOther => _money(other);

  factory CollectionRow.fromJson(Map<String, dynamic> json) {
    return CollectionRow(
      period: _text(json['period']),
      sortKey: _text(json['sort_key']),
      count: _asInt(json['count']),
      total: _asInt(json['total']),
      cash: _asInt(json['cash']),
      online: _asInt(json['online']),
      other: _asInt(json['other']),
    );
  }
}

class CollectionMethod {
  final int count;
  final int total;

  const CollectionMethod({required this.count, required this.total});

  String get formattedTotal => _money(total);

  factory CollectionMethod.fromJson(Map<String, dynamic> json) {
    return CollectionMethod(
      count: _asInt(json['count']),
      total: _asInt(json['total']),
    );
  }
}

// ─── 7. Sales Revenue ─────────────────────────────────────────────────────────

class SalesRevenueQuery {
  final int month;
  final int year;

  const SalesRevenueQuery({required this.month, required this.year});

  SalesRevenueQuery copyWith({int? month, int? year}) {
    return SalesRevenueQuery(
      month: month ?? this.month,
      year: year ?? this.year,
    );
  }

  Map<String, String> toQueryParameters() {
    return {'month': month.toString(), 'year': year.toString()};
  }

  @override
  bool operator ==(Object other) =>
      other is SalesRevenueQuery &&
      other.month == month &&
      other.year == year;

  @override
  int get hashCode => Object.hash(month, year);
}

class SalesRevenueResponse {
  final List<SalesRevenueRow> rows;
  final SalesRevenueTotals totals;
  final String period;

  const SalesRevenueResponse({
    required this.rows,
    required this.totals,
    required this.period,
  });

  factory SalesRevenueResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'])
        : <String, dynamic>{};
    return SalesRevenueResponse(
      rows: (data['rows'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => SalesRevenueRow.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false),
      totals: SalesRevenueTotals.fromJson(
        data['totals'] is Map
            ? Map<String, dynamic>.from(data['totals'])
            : <String, dynamic>{},
      ),
      period: _text(data['period']),
    );
  }
}

class SalesRevenueTotals {
  final int count;
  final int totalSale;
  final int commission;
  final int net;

  const SalesRevenueTotals({
    required this.count,
    required this.totalSale,
    required this.commission,
    required this.net,
  });

  String get formattedTotalSale => _money(totalSale);
  String get formattedCommission => _money(commission);
  String get formattedNet => _money(net);

  factory SalesRevenueTotals.fromJson(Map<String, dynamic> json) {
    return SalesRevenueTotals(
      count: _asInt(json['count']),
      totalSale: _asInt(json['total_sale']),
      commission: _asInt(json['commission']),
      net: _asInt(json['net']),
    );
  }
}

class SalesRevenueRow {
  final int orderId;
  final String orderNo;
  final String date;
  final String productTitle;
  final String prNumber;
  final String customerName;
  final String customerPhone;
  final int qty;
  final int unitPrice;
  final int totalSale;
  final int commission;
  final int net;
  final String status;

  const SalesRevenueRow({
    required this.orderId,
    required this.orderNo,
    required this.date,
    required this.productTitle,
    required this.prNumber,
    required this.customerName,
    required this.customerPhone,
    required this.qty,
    required this.unitPrice,
    required this.totalSale,
    required this.commission,
    required this.net,
    required this.status,
  });

  String get formattedUnitPrice => _money(unitPrice);
  String get formattedTotalSale => _money(totalSale);
  String get formattedCommission => _money(commission);
  String get formattedNet => _money(net);

  factory SalesRevenueRow.fromJson(Map<String, dynamic> json) {
    return SalesRevenueRow(
      orderId: _asInt(json['order_id']),
      orderNo: _text(json['order_no']),
      date: _date(json['date']),
      productTitle: _text(json['product_title']),
      prNumber: _text(json['pr_number']),
      customerName: _text(json['customer_name'], fallback: 'Customer'),
      customerPhone: _text(json['customer_phone']),
      qty: _asInt(json['qty']),
      unitPrice: _asInt(json['unit_price']),
      totalSale: _asInt(json['total_sale']),
      commission: _asInt(json['commission']),
      net: _asInt(json['net']),
      status: _text(json['status']),
    );
  }
}

// ─── 8. Order Summary ─────────────────────────────────────────────────────────

class OrderSummaryQuery {
  final String from;
  final String to;
  final String status;

  const OrderSummaryQuery({
    required this.from,
    required this.to,
    this.status = 'all',
  });

  OrderSummaryQuery copyWith({String? from, String? to, String? status}) {
    return OrderSummaryQuery(
      from: from ?? this.from,
      to: to ?? this.to,
      status: status ?? this.status,
    );
  }

  Map<String, String> toQueryParameters() {
    final params = <String, String>{};
    if (from.trim().isNotEmpty) params['from'] = from.trim();
    if (to.trim().isNotEmpty) params['to'] = to.trim();
    if (status.trim().isNotEmpty && status != 'all') {
      params['status'] = status.trim();
    }
    return params;
  }

  @override
  bool operator ==(Object other) =>
      other is OrderSummaryQuery &&
      other.from == from &&
      other.to == to &&
      other.status == status;

  @override
  int get hashCode => Object.hash(from, to, status);
}

class OrderSummaryResponse {
  final List<OrderSummaryRow> rows;
  final Map<String, OrderGroup> groups;
  final int total;
  final int count;

  const OrderSummaryResponse({
    required this.rows,
    required this.groups,
    required this.total,
    required this.count,
  });

  String get formattedTotal => _money(total);

  factory OrderSummaryResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'])
        : <String, dynamic>{};
    final rawGroups = data['groups'];
    final groupsMap = <String, OrderGroup>{};
    if (rawGroups is Map) {
      rawGroups.forEach((key, value) {
        if (value is Map) {
          groupsMap[key.toString()] =
              OrderGroup.fromJson(Map<String, dynamic>.from(value));
        }
      });
    }
    return OrderSummaryResponse(
      rows: (data['rows'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => OrderSummaryRow.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false),
      groups: groupsMap,
      total: _asInt(data['total']),
      count: _asInt(data['count']),
    );
  }
}

class OrderSummaryRow {
  final int orderId;
  final String orderNo;
  final String date;
  final String customerName;
  final String customerPhone;
  final String productTitle;
  final int total;
  final int advance;
  final int tenure;
  final String status;

  const OrderSummaryRow({
    required this.orderId,
    required this.orderNo,
    required this.date,
    required this.customerName,
    required this.customerPhone,
    required this.productTitle,
    required this.total,
    required this.advance,
    required this.tenure,
    required this.status,
  });

  String get formattedTotal => _money(total);
  String get formattedAdvance => _money(advance);

  factory OrderSummaryRow.fromJson(Map<String, dynamic> json) {
    return OrderSummaryRow(
      orderId: _asInt(json['order_id']),
      orderNo: _text(json['order_no']),
      date: _date(json['date']),
      customerName: _text(json['customer_name'], fallback: 'Customer'),
      customerPhone: _text(json['customer_phone']),
      productTitle: _text(json['product_title']),
      total: _asInt(json['total']),
      advance: _asInt(json['advance']),
      tenure: _asInt(json['tenure']),
      status: _text(json['status']),
    );
  }
}

class OrderGroup {
  final int count;
  final int total;

  const OrderGroup({required this.count, required this.total});

  String get formattedTotal => _money(total);

  factory OrderGroup.fromJson(Map<String, dynamic> json) {
    return OrderGroup(
      count: _asInt(json['count']),
      total: _asInt(json['total']),
    );
  }
}

// ─── 9. Lead Funnel ───────────────────────────────────────────────────────────

class LeadFunnelQuery {
  final String from;
  final String to;

  const LeadFunnelQuery({required this.from, required this.to});

  LeadFunnelQuery copyWith({String? from, String? to}) {
    return LeadFunnelQuery(
      from: from ?? this.from,
      to: to ?? this.to,
    );
  }

  Map<String, String> toQueryParameters() {
    final params = <String, String>{};
    if (from.trim().isNotEmpty) params['from'] = from.trim();
    if (to.trim().isNotEmpty) params['to'] = to.trim();
    return params;
  }

  @override
  bool operator ==(Object other) =>
      other is LeadFunnelQuery && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}

class LeadFunnelResponse {
  final List<FunnelStage> funnel;
  final int total;
  final int won;
  final int lost;
  final double conversionRate;

  const LeadFunnelResponse({
    required this.funnel,
    required this.total,
    required this.won,
    required this.lost,
    required this.conversionRate,
  });

  String get formattedConversionRate =>
      '${conversionRate.toStringAsFixed(2)}%';

  factory LeadFunnelResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'])
        : <String, dynamic>{};
    return LeadFunnelResponse(
      funnel: (data['funnel'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => FunnelStage.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false),
      total: _asInt(data['total']),
      won: _asInt(data['won']),
      lost: _asInt(data['lost']),
      conversionRate: _asDouble(data['conversion_rate']),
    );
  }
}

class FunnelStage {
  final String status;
  final int count;
  final double pct;

  const FunnelStage({
    required this.status,
    required this.count,
    required this.pct,
  });

  String get formattedPct => '${pct.toStringAsFixed(1)}%';

  factory FunnelStage.fromJson(Map<String, dynamic> json) {
    return FunnelStage(
      status: _text(json['status']),
      count: _asInt(json['count']),
      pct: _asDouble(json['pct']),
    );
  }
}

// ─── 10. Offers Report ────────────────────────────────────────────────────────

class OffersReportQuery {
  final String from;
  final String to;
  final String status;

  const OffersReportQuery({
    required this.from,
    required this.to,
    this.status = 'all',
  });

  OffersReportQuery copyWith({String? from, String? to, String? status}) {
    return OffersReportQuery(
      from: from ?? this.from,
      to: to ?? this.to,
      status: status ?? this.status,
    );
  }

  Map<String, String> toQueryParameters() {
    final params = <String, String>{};
    if (from.trim().isNotEmpty) params['from'] = from.trim();
    if (to.trim().isNotEmpty) params['to'] = to.trim();
    if (status.trim().isNotEmpty && status != 'all') {
      params['status'] = status.trim();
    }
    return params;
  }

  @override
  bool operator ==(Object other) =>
      other is OffersReportQuery &&
      other.from == from &&
      other.to == to &&
      other.status == status;

  @override
  int get hashCode => Object.hash(from, to, status);
}

class OffersReportResponse {
  final List<OfferRow> rows;
  final int total;
  final int won;
  final int lost;
  final int inProgress;
  final double conversionRate;

  const OffersReportResponse({
    required this.rows,
    required this.total,
    required this.won,
    required this.lost,
    required this.inProgress,
    required this.conversionRate,
  });

  String get formattedConversionRate =>
      '${conversionRate.toStringAsFixed(2)}%';

  factory OffersReportResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'])
        : <String, dynamic>{};
    return OffersReportResponse(
      rows: (data['rows'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => OfferRow.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false),
      total: _asInt(data['total']),
      won: _asInt(data['won']),
      lost: _asInt(data['lost']),
      inProgress: _asInt(data['in_progress']),
      conversionRate: _asDouble(data['conversion_rate']),
    );
  }
}

class OfferRow {
  final int leadId;
  final String date;
  final String customer;
  final String phone;
  final String product;
  final String city;
  final String area;
  final String status;
  final String portal;
  final String? reason;

  const OfferRow({
    required this.leadId,
    required this.date,
    required this.customer,
    required this.phone,
    required this.product,
    required this.city,
    required this.area,
    required this.status,
    required this.portal,
    this.reason,
  });

  factory OfferRow.fromJson(Map<String, dynamic> json) {
    final rawReason = json['reason'];
    return OfferRow(
      leadId: _asInt(json['lead_id']),
      date: _date(json['date']),
      customer: _text(json['customer'], fallback: 'Customer'),
      phone: _text(json['phone']),
      product: _text(json['product']),
      city: _text(json['city']),
      area: _text(json['area']),
      status: _text(json['status']),
      portal: _text(json['portal']),
      reason: (rawReason == null ||
              rawReason.toString().trim().isEmpty ||
              rawReason.toString() == 'null')
          ? null
          : rawReason.toString().trim(),
    );
  }
}

// ─── 11. Outstanding ──────────────────────────────────────────────────────────

class OutstandingResponse {
  final List<OutstandingRow> rows;
  final int totalOutstanding;
  final int totalOverdue;
  final int count;

  const OutstandingResponse({
    required this.rows,
    required this.totalOutstanding,
    required this.totalOverdue,
    required this.count,
  });

  String get formattedTotalOutstanding => _money(totalOutstanding);
  String get formattedTotalOverdue => _money(totalOverdue);

  factory OutstandingResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'])
        : <String, dynamic>{};
    return OutstandingResponse(
      rows: (data['rows'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => OutstandingRow.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false),
      totalOutstanding: _asInt(data['total_outstanding']),
      totalOverdue: _asInt(data['total_overdue']),
      count: _asInt(data['count']),
    );
  }
}

class OutstandingRow {
  final int customerId;
  final String customerName;
  final String customerPhone;
  final int ordersCount;
  final int totalDeal;
  final int totalPaid;
  final int outstanding;
  final int overdue;
  final String nextDueDate;
  final int nextAmount;

  const OutstandingRow({
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.ordersCount,
    required this.totalDeal,
    required this.totalPaid,
    required this.outstanding,
    required this.overdue,
    required this.nextDueDate,
    required this.nextAmount,
  });

  String get formattedTotalDeal => _money(totalDeal);
  String get formattedTotalPaid => _money(totalPaid);
  String get formattedOutstanding => _money(outstanding);
  String get formattedOverdue => _money(overdue);
  String get formattedNextAmount => _money(nextAmount);

  factory OutstandingRow.fromJson(Map<String, dynamic> json) {
    return OutstandingRow(
      customerId: _asInt(json['customer_id']),
      customerName: _text(json['customer_name'], fallback: 'Customer'),
      customerPhone: _text(json['customer_phone']),
      ordersCount: _asInt(json['orders_count']),
      totalDeal: _asInt(json['total_deal']),
      totalPaid: _asInt(json['total_paid']),
      outstanding: _asInt(json['outstanding']),
      overdue: _asInt(json['overdue']),
      nextDueDate: _date(json['next_due_date']),
      nextAmount: _asInt(json['next_amount']),
    );
  }
}

// ─── 12. Payment History ──────────────────────────────────────────────────────

class PaymentHistoryQuery {
  final int customerId;

  const PaymentHistoryQuery({required this.customerId});

  PaymentHistoryQuery copyWith({int? customerId}) {
    return PaymentHistoryQuery(customerId: customerId ?? this.customerId);
  }

  Map<String, String> toQueryParameters() {
    return {'customer_id': customerId.toString()};
  }

  @override
  bool operator ==(Object other) =>
      other is PaymentHistoryQuery && other.customerId == customerId;

  @override
  int get hashCode => customerId.hashCode;
}

class PaymentHistoryResponse {
  final ReportCustomer customer;
  final List<PaymentRow> rows;
  final int total;
  final int count;

  const PaymentHistoryResponse({
    required this.customer,
    required this.rows,
    required this.total,
    required this.count,
  });

  String get formattedTotal => _money(total);

  factory PaymentHistoryResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'])
        : <String, dynamic>{};
    return PaymentHistoryResponse(
      customer: ReportCustomer.fromJson(
        data['customer'] is Map
            ? Map<String, dynamic>.from(data['customer'])
            : <String, dynamic>{},
      ),
      rows: (data['rows'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => PaymentRow.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false),
      total: _asInt(data['total']),
      count: _asInt(data['count']),
    );
  }
}

class PaymentRow {
  final String date;
  final String orderNo;
  final String productTitle;
  final String type;
  final String? month;
  final int amount;
  final String method;

  const PaymentRow({
    required this.date,
    required this.orderNo,
    required this.productTitle,
    required this.type,
    this.month,
    required this.amount,
    required this.method,
  });

  String get formattedAmount => _money(amount);

  factory PaymentRow.fromJson(Map<String, dynamic> json) {
    final rawMonth = json['month'];
    return PaymentRow(
      date: _date(json['date']),
      orderNo: _text(json['order_no']),
      productTitle: _text(json['product_title']),
      type: _text(json['type']),
      month: (rawMonth == null ||
              rawMonth.toString().trim().isEmpty ||
              rawMonth.toString() == 'null')
          ? null
          : rawMonth.toString().trim(),
      amount: _asInt(json['amount']),
      method: _text(json['method']),
    );
  }
}

// ─── Helper functions ─────────────────────────────────────────────────────────

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
