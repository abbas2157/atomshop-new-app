class SellerInvestmentsResponse {
  final List<SellerInvestment> investments;
  final SellerInvestmentsPagination pagination;

  const SellerInvestmentsResponse({
    required this.investments,
    required this.pagination,
  });

  int get totalAmount => investments.fold(0, (sum, item) => sum + item.amount);
  int get activeCount =>
      investments.where((item) => item.status.toLowerCase() == 'active').length;
  String get formattedTotalAmount => _money(totalAmount);

  factory SellerInvestmentsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'])
        : <String, dynamic>{};

    return SellerInvestmentsResponse(
      investments: (data['data'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                SellerInvestment.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
      pagination: SellerInvestmentsPagination.fromJson(data),
    );
  }
}

class SellerInvestmentDetails {
  final SellerInvestment investment;
  final Map<String, String> fields;

  const SellerInvestmentDetails({
    required this.investment,
    required this.fields,
  });

  factory SellerInvestmentDetails.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'])
        : <String, dynamic>{};
    final rawInvestment = data['investment'] is Map
        ? Map<String, dynamic>.from(data['investment'])
        : data;
    final investment = SellerInvestment.fromJson(rawInvestment);

    return SellerInvestmentDetails(
      investment: investment,
      fields: _flattenFields(rawInvestment),
    );
  }
}

class SellerInvestmentsPagination {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final int? from;
  final int? to;

  const SellerInvestmentsPagination({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    this.from,
    this.to,
  });

  bool get hasPrevious => currentPage > 1;
  bool get hasNext => currentPage < lastPage;

  factory SellerInvestmentsPagination.fromJson(Map<String, dynamic> json) {
    return SellerInvestmentsPagination(
      currentPage: _asInt(json['current_page'], fallback: 1),
      lastPage: _asInt(json['last_page'], fallback: 1),
      perPage: _asInt(json['per_page']),
      total: _asInt(json['total']),
      from: json['from'] == null ? null : _asInt(json['from']),
      to: json['to'] == null ? null : _asInt(json['to']),
    );
  }
}

class SellerInvestment {
  final int id;
  final String uuid;
  final int amount;
  final int paidAmount;
  final int profitAmount;
  final String investorName;
  final String investorPhone;
  final String status;
  final String type;
  final String createdAt;
  final String updatedAt;
  final Map<String, dynamic> raw;

  const SellerInvestment({
    required this.id,
    required this.uuid,
    required this.amount,
    required this.paidAmount,
    required this.profitAmount,
    required this.investorName,
    required this.investorPhone,
    required this.status,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    required this.raw,
  });

  String get formattedAmount => _money(amount);
  String get formattedPaidAmount => _money(paidAmount);
  String get formattedProfitAmount => _money(profitAmount);
  String get formattedCreatedAt => _date(createdAt);
  String get formattedUpdatedAt => _date(updatedAt);

  factory SellerInvestment.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map
        ? Map<String, dynamic>.from(json['user'])
        : json['investor'] is Map
        ? Map<String, dynamic>.from(json['investor'])
        : <String, dynamic>{};

    return SellerInvestment(
      id: _asInt(json['id']),
      uuid: _text(json['uuid'], fallback: ''),
      amount: _asInt(
        json['amount'] ??
            json['investment_amount'] ??
            json['total_amount'] ??
            json['principal'],
      ),
      paidAmount: _asInt(
        json['paid_amount'] ?? json['total_paid'] ?? json['paid'],
      ),
      profitAmount: _asInt(
        json['profit_amount'] ?? json['profit'] ?? json['return_amount'],
      ),
      investorName: _text(
        json['investor_name'] ?? json['name'] ?? user['name'],
        fallback: 'Investor',
      ),
      investorPhone: _text(json['phone'] ?? user['phone'], fallback: ''),
      status: _text(json['status'], fallback: 'pending'),
      type: _text(json['type'] ?? json['investment_type']),
      createdAt: _text(json['created_at'], fallback: ''),
      updatedAt: _text(json['updated_at'], fallback: ''),
      raw: json,
    );
  }
}

Map<String, String> _flattenFields(Map<String, dynamic> raw) {
  final fields = <String, String>{};
  for (final entry in raw.entries) {
    final value = entry.value;
    if (value == null || value is Map || value is List) continue;
    final text = value.toString().trim();
    if (text.isEmpty || text == 'null') continue;
    fields[_label(entry.key)] = text;
  }
  return fields;
}

String _label(String key) {
  return key
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
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
