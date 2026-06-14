import 'package:atompro/core/seller_plan_upgrade_exception.dart';

class SellerFeeChargeResponse {
  final int grandTotal;
  final int totalPaid;
  final List<SellerFeeCharge> charges;
  final SellerFeeChargePagination pagination;

  /// Non-null when the plan doesn't include this feature — carried as data, not
  /// thrown, to avoid the AsyncError refetch loop. Screen renders the gate from it.
  final SellerPlanUpgradeException? gate;

  const SellerFeeChargeResponse({
    required this.grandTotal,
    required this.totalPaid,
    required this.charges,
    required this.pagination,
    this.gate,
  });

  factory SellerFeeChargeResponse.gated(SellerPlanUpgradeException gate) {
    return SellerFeeChargeResponse(
      grandTotal: 0,
      totalPaid: 0,
      charges: const [],
      pagination: const SellerFeeChargePagination(
        currentPage: 1,
        lastPage: 1,
        perPage: 0,
        total: 0,
      ),
      gate: gate,
    );
  }

  int get outstanding => grandTotal - totalPaid;
  bool get hasOutstanding => outstanding > 0;
  String get formattedGrandTotal => _money(grandTotal);
  String get formattedTotalPaid => _money(totalPaid);
  String get formattedOutstanding => _money(outstanding < 0 ? 0 : outstanding);

  factory SellerFeeChargeResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'])
        : <String, dynamic>{};
    final rawCharges = data['fee_charges'] is Map
        ? Map<String, dynamic>.from(data['fee_charges'])
        : <String, dynamic>{};

    return SellerFeeChargeResponse(
      grandTotal: _asInt(data['grand_total']),
      totalPaid: _asInt(data['total_paid']),
      charges: (rawCharges['data'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => SellerFeeCharge.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
      pagination: SellerFeeChargePagination.fromJson(rawCharges),
    );
  }
}

class SellerFeeChargePagination {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final int? from;
  final int? to;

  const SellerFeeChargePagination({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    this.from,
    this.to,
  });

  bool get hasPrevious => currentPage > 1;
  bool get hasNext => currentPage < lastPage;

  factory SellerFeeChargePagination.fromJson(Map<String, dynamic> json) {
    return SellerFeeChargePagination(
      currentPage: _asInt(json['current_page'], fallback: 1),
      lastPage: _asInt(json['last_page'], fallback: 1),
      perPage: _asInt(json['per_page']),
      total: _asInt(json['total']),
      from: json['from'] == null ? null : _asInt(json['from']),
      to: json['to'] == null ? null : _asInt(json['to']),
    );
  }
}

class SellerFeeCharge {
  final int id;
  final int amount;
  final int paidAmount;
  final String status;
  final String type;
  final String note;
  final String createdAt;
  final String paidAt;
  final Map<String, dynamic> raw;

  const SellerFeeCharge({
    required this.id,
    required this.amount,
    required this.paidAmount,
    required this.status,
    required this.type,
    required this.note,
    required this.createdAt,
    required this.paidAt,
    required this.raw,
  });

  bool get paid => status.toLowerCase() == 'paid' || paidAmount >= amount;
  int get pendingAmount => amount - paidAmount;
  String get formattedAmount => _money(amount);
  String get formattedPaidAmount => _money(paidAmount);
  String get formattedPendingAmount =>
      _money(pendingAmount < 0 ? 0 : pendingAmount);
  String get formattedCreatedAt => _date(createdAt);
  String get formattedPaidAt => _date(paidAt);

  factory SellerFeeCharge.fromJson(Map<String, dynamic> json) {
    return SellerFeeCharge(
      id: _asInt(json['id']),
      amount: _asInt(
        json['amount'] ??
            json['fee'] ??
            json['fee_amount'] ??
            json['charge'] ??
            json['total'],
      ),
      paidAmount: _asInt(
        json['paid_amount'] ??
            json['total_paid'] ??
            json['paid'] ??
            json['paid_fee'],
      ),
      status: _text(json['status'], fallback: 'Pending'),
      type: _text(json['type'] ?? json['fee_type'] ?? json['charge_type']),
      note: _text(json['note'] ?? json['description'] ?? json['remarks']),
      createdAt: _text(json['created_at'], fallback: ''),
      paidAt: _text(json['paid_at'] ?? json['updated_at'], fallback: ''),
      raw: json,
    );
  }
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  final normalized = value?.toString().replaceAll(',', '').trim() ?? '';
  return int.tryParse(normalized) ?? fallback;
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
