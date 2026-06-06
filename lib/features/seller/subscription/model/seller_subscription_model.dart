// Models for the seller Subscription feature.
// Mirrors `GET /seller-app/subscription` and the `POST /subscription/pay`
// response. All money values arrive as integers; rates as doubles.

class SellerSubscriptionData {
  final bool hasActivePlan;
  final SellerPlan? plan;
  final SellerCommissionSummary? commission;
  final List<SellerSubscriptionPayment> payments;

  const SellerSubscriptionData({
    required this.hasActivePlan,
    required this.plan,
    required this.commission,
    required this.payments,
  });

  factory SellerSubscriptionData.fromResponse(Map<String, dynamic> response) {
    final data = response['data'] is Map
        ? Map<String, dynamic>.from(response['data'])
        : <String, dynamic>{};
    final planJson = data['plan'];
    final commJson = data['commission'];
    return SellerSubscriptionData(
      hasActivePlan: data['has_active_plan'] == true,
      plan: planJson is Map
          ? SellerPlan.fromJson(Map<String, dynamic>.from(planJson))
          : null,
      commission: commJson is Map
          ? SellerCommissionSummary.fromJson(Map<String, dynamic>.from(commJson))
          : null,
      payments: (data['payments'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (e) =>
                SellerSubscriptionPayment.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(growable: false),
    );
  }
}

class SellerPlan {
  final int id;
  final String planType;
  final String planLabel;
  final int monthlyPrice;
  final double salesCommission;
  final String status;
  final String startDate;
  final String? endDate;
  final bool featureFinancial;
  final bool featureMarketing;
  final SellerPaymentAction monthly;
  final SellerPaymentAction commissionAction;

  const SellerPlan({
    required this.id,
    required this.planType,
    required this.planLabel,
    required this.monthlyPrice,
    required this.salesCommission,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.featureFinancial,
    required this.featureMarketing,
    required this.monthly,
    required this.commissionAction,
  });

  bool get hasCommissionRate => salesCommission > 0;
  String get commissionRateLabel => '${_trimNum(salesCommission)}%';
  String get formattedMonthlyPrice => _money(monthlyPrice);
  String get endDateLabel =>
      (endDate == null || endDate!.trim().isEmpty || endDate == 'null')
      ? 'No expiry'
      : endDate!;

  factory SellerPlan.fromJson(Map<String, dynamic> json) {
    final features = json['features'] is Map
        ? Map<String, dynamic>.from(json['features'])
        : <String, dynamic>{};
    final actions = json['payment_actions'] is Map
        ? Map<String, dynamic>.from(json['payment_actions'])
        : <String, dynamic>{};
    return SellerPlan(
      id: _asInt(json['id']),
      planType: _text(json['plan_type'], fallback: ''),
      planLabel: _text(json['plan_label'], fallback: 'Subscription Plan'),
      monthlyPrice: _asInt(json['monthly_price']),
      salesCommission: _asDouble(json['sales_commission']),
      status: _text(json['status'], fallback: 'active'),
      startDate: _text(json['start_date'], fallback: '—'),
      endDate: json['end_date']?.toString(),
      featureFinancial: features['financial'] == true,
      featureMarketing: features['marketing'] == true,
      monthly: SellerPaymentAction.fromJson(
        actions['monthly'] is Map
            ? Map<String, dynamic>.from(actions['monthly'])
            : const {},
      ),
      commissionAction: SellerPaymentAction.fromJson(
        actions['commission'] is Map
            ? Map<String, dynamic>.from(actions['commission'])
            : const {},
      ),
    );
  }
}

class SellerPaymentAction {
  final bool canPay;
  final bool isPending;
  final int unpaidMonths;
  final int amount;

  const SellerPaymentAction({
    required this.canPay,
    required this.isPending,
    required this.unpaidMonths,
    required this.amount,
  });

  String get formattedAmount => _money(amount);

  factory SellerPaymentAction.fromJson(Map<String, dynamic> json) {
    return SellerPaymentAction(
      canPay: json['can_pay'] == true,
      isPending: json['is_pending'] == true,
      unpaidMonths: _asInt(json['unpaid_months']),
      amount: _asInt(json['amount']),
    );
  }
}

class SellerCommissionSummary {
  final double rate;
  final int totalSales;
  final int accrued;
  final int paid;
  final int pending;
  final String lastPaidDate;

  const SellerCommissionSummary({
    required this.rate,
    required this.totalSales,
    required this.accrued,
    required this.paid,
    required this.pending,
    required this.lastPaidDate,
  });

  String get rateLabel => '${_trimNum(rate)}%';
  String get formattedTotalSales => _money(totalSales);
  String get formattedAccrued => _money(accrued);
  String get formattedPaid => _money(paid);
  String get formattedPending => _money(pending);

  factory SellerCommissionSummary.fromJson(Map<String, dynamic> json) {
    return SellerCommissionSummary(
      rate: _asDouble(json['rate']),
      totalSales: _asInt(json['total_sales']),
      accrued: _asInt(json['accrued']),
      paid: _asInt(json['paid']),
      pending: _asInt(json['pending']),
      lastPaidDate: _text(json['last_paid_date'], fallback: '—'),
    );
  }
}

class SellerSubscriptionPayment {
  final int id;
  final String paymentType;
  final int amount;
  final String paymentMethod;
  final String month;
  final String status;
  final String? receipt;
  final String? notes;
  final String submittedAt;

  const SellerSubscriptionPayment({
    required this.id,
    required this.paymentType,
    required this.amount,
    required this.paymentMethod,
    required this.month,
    required this.status,
    required this.receipt,
    required this.notes,
    required this.submittedAt,
  });

  bool get isReceived => status.toLowerCase() == 'received';
  bool get isMonthly => paymentType.toLowerCase() == 'monthly';
  String get typeLabel => isMonthly ? 'Monthly' : 'Commission';
  String get formattedAmount => _money(amount);
  bool get hasReceipt => receipt != null && receipt!.trim().isNotEmpty;
  bool get hasNotes => notes != null && notes!.trim().isNotEmpty;

  factory SellerSubscriptionPayment.fromJson(Map<String, dynamic> json) {
    return SellerSubscriptionPayment(
      id: _asInt(json['id']),
      paymentType: _text(json['payment_type'], fallback: 'monthly'),
      amount: _asInt(json['amount']),
      paymentMethod: _text(json['payment_method'], fallback: '—'),
      month: _text(json['month'], fallback: '—'),
      status: _text(json['status'], fallback: 'pending'),
      receipt: json['receipt']?.toString(),
      notes: json['notes']?.toString(),
      submittedAt: _text(json['submitted_at'], fallback: '—'),
    );
  }
}

// ── helpers ──────────────────────────────────────────────────────────────
int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  final normalized = value?.toString().replaceAll(',', '').trim() ?? '';
  return int.tryParse(normalized) ?? double.tryParse(normalized)?.toInt() ?? fallback;
}

double _asDouble(dynamic value, {double fallback = 0}) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString().trim() ?? '') ?? fallback;
}

String _text(dynamic value, {String fallback = 'Not available'}) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty || text == 'null') return fallback;
  return text;
}

String _trimNum(double value) =>
    value == value.roundToDouble() ? value.toInt().toString() : value.toString();

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
