import 'package:atompro/core/auth/seller_session_manager.dart';

class SellerDashboardBundle {
  final SellerDashboardModel dashboard;
  final SellerSalesRevenueModel revenue;

  const SellerDashboardBundle({required this.dashboard, required this.revenue});
}

class SellerDashboardModel {
  final String userName;
  final String businessName;
  final int days;
  final String todayDate;
  final String previous30Date;
  final int sellerId;
  final int monthlyLeads;
  final int monthlyWonLeads;
  final int monthlyLostLeads;
  final String totalCustomSales;
  final String totalCustomRecovery;
  final String totalCustomSalesAll;
  final String totalCustomRecoveryAll;
  final String totalCustomRecoveryPercentage;
  final String totalCustomRecoveryPercentageAll;
  final int totalCustomOrders;
  final int totalCustomers;
  final String outstandingBalance;
  final int salesVelocityWeek;
  final int pendingRecoveryCount;
  final String pendingRecoverySum;
  final Map<String, int> leadStatusPercentages;
  final Map<String, int> orderStatusPercentages;
  final List<SellerDashboardRecord> customers;
  final List<SellerDashboardRecord> customOrders;
  final List<SellerDashboardRecord> topProducts;

  const SellerDashboardModel({
    required this.userName,
    required this.businessName,
    required this.days,
    required this.todayDate,
    required this.previous30Date,
    required this.sellerId,
    required this.monthlyLeads,
    required this.monthlyWonLeads,
    required this.monthlyLostLeads,
    required this.totalCustomSales,
    required this.totalCustomRecovery,
    required this.totalCustomSalesAll,
    required this.totalCustomRecoveryAll,
    required this.totalCustomRecoveryPercentage,
    required this.totalCustomRecoveryPercentageAll,
    required this.totalCustomOrders,
    required this.totalCustomers,
    required this.outstandingBalance,
    required this.salesVelocityWeek,
    required this.pendingRecoveryCount,
    required this.pendingRecoverySum,
    required this.leadStatusPercentages,
    required this.orderStatusPercentages,
    required this.customOrders,
    required this.customers,
    required this.topProducts,
  });

  static Future<SellerDashboardModel> fromResponse(
    Map<String, dynamic> response,
  ) async {
    final data = response['data'] as Map<String, dynamic>? ?? {};
    final userName = await SellerSessionManager.getUserName();
    final businessName = await SellerSessionManager.getBusinessName();

    return SellerDashboardModel(
      userName: _fallback(userName, 'Seller'),
      businessName: _fallback(businessName, 'AtomShop Seller'),
      days: _asInt(data['days']),
      todayDate: _text(data['today_date']),
      previous30Date: _text(data['previous_30_date']),
      sellerId: _asInt(data['seller_id']),
      monthlyLeads: _asInt(data['monthly_leads']),
      monthlyWonLeads: _asInt(data['monthly_won_leads']),
      monthlyLostLeads: _asInt(data['monthly_lost_leads']),
      totalCustomSales: _money(data['total_custom_sales']),
      totalCustomRecovery: _money(data['total_custom_recovery']),
      totalCustomSalesAll: _money(data['total_custom_sales_all']),
      totalCustomRecoveryAll: _money(data['total_custom_recovery_all']),
      totalCustomRecoveryPercentage: _percent(
        data['total_custom_recovery_percentage'],
      ),
      totalCustomRecoveryPercentageAll: _percent(
        data['total_custom_recovery_percentage_all'],
      ),
      totalCustomOrders: _asInt(data['total_custom_orders']),
      totalCustomers: _asInt(data['total_customers']),
      outstandingBalance: _money(data['outstanding_balance']),
      salesVelocityWeek: _asInt(data['sales_velocity_week']),
      pendingRecoveryCount: _asInt(data['pending_recovery_count']),
      pendingRecoverySum: _money(data['pending_recovery_sum']),
      leadStatusPercentages: _asPercentMap(data['lead_status_percentages']),
      orderStatusPercentages: _asPercentMap(data['order_status_percentages']),
      customers: _asList(
        data['customers'],
      ).map(_customerRecord).toList(growable: false),
      customOrders: _asList(
        data['lastest_custom_orders'],
      ).map(_customOrderRecord).toList(growable: false),
      topProducts: _asList(
        data['top_products'],
      ).map(_topProductRecord).toList(growable: false),
    );
  }

  static SellerDashboardRecord _customerRecord(Map<String, dynamic> item) {
    return SellerDashboardRecord(
      title: _fallback(item['name']?.toString(), 'Customer'),
      subtitle: _fallback(item['phone']?.toString(), 'No phone'),
      badge: _fallback(item['status']?.toString(), 'Active'),
      details: {
        // ── Personal Information ──────────────────────────────
        'Name': _text(item['name']),
        'Phone': _text(item['phone']),
        'Email': _text(item['email']),
        'Status': _text(item['status']),
        'Joined Through': _text(item['joined_through']),
        'Member Since': _date(item['created_at']),
      },
    );
  }

  static SellerDashboardRecord _leadRecord(Map<String, dynamic> item) {
    final area = item['area'] is Map
        ? Map<String, dynamic>.from(item['area'])
        : {};
    return SellerDashboardRecord(
      title: _fallback(item['full_name']?.toString(), 'Lead'),
      subtitle: _fallback(item['product_title']?.toString(), 'No product'),
      badge: _fallback(item['status']?.toString(), 'New Lead'),
      details: {
        'Lead ID': _text(item['id']),
        'Lead UUID': _text(item['uuid']),
        'Product Title': _text(item['product_title']),
        'Full Name': _text(item['full_name']),
        'Phone': _text(item['phone']),
        'Available on WhatsApp': _yesNo(item['available_on_whatsapp']),
        'City': _text(item['city']),
        'City ID': _text(item['city_id']),
        'Address': _text(item['address']),
        'Area ID': _text(item['area_id']),
        'Area': _text(area['title']),
        'Portal': _text(item['portal']),
        'Reason': _text(item['reason']),
        'Seller ID': _text(item['seller_id']),
        'Lead Status': _text(item['status']),
        'Lead Type': _text(item['type']),
        'Feature Image': _text(item['feaure_image']),
        'Created At': _date(item['created_at']),
        'Updated At': _date(item['updated_at']),
      },
    );
  }

  static SellerDashboardRecord _customOrderRecord(Map<String, dynamic> item) {
    return SellerDashboardRecord(
      title: 'Order #${_text(item['id'])}',
      subtitle: '${_money(item['total_deal_price'])} · ${_fallback(item['status']?.toString(), 'Pending')}',
      badge: _fallback(item['status']?.toString(), 'Order'),
      details: {
        // ── Order Details ─────────────────────────────────────
        'Order No': '#${_text(item['id'])}',
        'Portal': _text(item['portal']),
        'Status': _text(item['status']),
        'Order Date': _date(item['created_at']),
        // ── Financial Information ─────────────────────────────
        'Deal Price': _money(item['total_deal_price']),
        'Advance': _money(item['advance_price']),
        'Tenure': '${_text(item['tenure'])} months',
        'Monthly %': '${_text(item['per_month_percentage'])}%',
        'Settlement': _money(item['settlement_amount']),
        'Deal Closed': _yesNo(item['deal_close']),
      },
    );
  }

  static SellerDashboardRecord _topProductRecord(Map<String, dynamic> item) {
    return SellerDashboardRecord(
      title: _fallback(item['product_title']?.toString(), 'Product'),
      subtitle: '${_asInt(item['order_count'])} orders',
      badge: _money(item['sales_value']),
      details: {
        'Product Title': _text(item['product_title']),
        'Order Count': _text(item['order_count']),
        'Sales Value': _money(item['sales_value']),
      },
    );
  }

  static Map<String, int> _asPercentMap(dynamic value) {
    if (value is! Map) return const {};
    return Map<String, int>.fromEntries(
      value.entries.map(
        (entry) =>
            MapEntry(_labelize(entry.key.toString()), _asInt(entry.value)),
      ),
    );
  }

  static List<Map<String, dynamic>> _asList(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _money(dynamic value) {
    final amount = _asInt(value);
    return 'Rs ${_withCommas(amount)}';
  }

  static String _percent(dynamic value) {
    final number = _asDouble(value);
    final text = number == number.roundToDouble()
        ? number.toInt().toString()
        : number.toStringAsFixed(2);
    return '$text%';
  }

  static String _text(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text == 'null') return 'Not available';
    return text;
  }

  static String _date(dynamic value) {
    final text = _text(value);
    if (text == 'Not available') return text;
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

  static String _yesNo(dynamic value) {
    final text = value?.toString();
    if (text == '1' || text == 'true') return 'Yes';
    if (text == '0' || text == 'false') return 'No';
    return _text(value);
  }

  static String _fallback(String? value, String fallback) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty || trimmed == 'null') {
      return fallback;
    }
    return trimmed;
  }

  static String _labelize(String value) {
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  static String _withCommas(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final remaining = text.length - i;
      buffer.write(text[i]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write(',');
    }
    return buffer.toString();
  }
}

class SellerDashboardRecord {
  final String title;
  final String subtitle;
  final String badge;
  final Map<String, String> details;

  const SellerDashboardRecord({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.details,
  });
}

class SellerSalesRevenueModel {
  final String totalSales;
  final String totalRecovered;
  final String outstanding;
  final String recoveryPercentage;
  final String from;
  final String to;
  final int days;
  final List<SellerRevenuePoint> revenuePoints;
  final SellerPerformanceMetrics performanceMetrics;

  const SellerSalesRevenueModel({
    required this.totalSales,
    required this.totalRecovered,
    required this.outstanding,
    required this.recoveryPercentage,
    required this.from,
    required this.to,
    required this.days,
    required this.revenuePoints,
    required this.performanceMetrics,
  });

  factory SellerSalesRevenueModel.fromResponse(Map<String, dynamic> response) {
    final data = response['data'] as Map<String, dynamic>? ?? {};
    return SellerSalesRevenueModel(
      totalSales: SellerDashboardModel._money(data['totalSales']),
      totalRecovered: SellerDashboardModel._money(data['totalRecovered']),
      outstanding: SellerDashboardModel._money(data['outstanding']),
      recoveryPercentage: SellerDashboardModel._percent(
        data['recoveryPercentage'],
      ),
      from: SellerDashboardModel._text(data['from']),
      to: SellerDashboardModel._text(data['to']),
      days: SellerDashboardModel._asInt(data['days']),
      revenuePoints: SellerDashboardModel._asList(
        data['morrisData'],
      ).map(SellerRevenuePoint.fromMap).toList(growable: false),
      performanceMetrics: SellerPerformanceMetrics.fromMap(
        data['performanceMetrics'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class SellerRevenuePoint {
  final String period;
  final int sales;
  final int recovered;

  const SellerRevenuePoint({
    required this.period,
    required this.sales,
    required this.recovered,
  });

  factory SellerRevenuePoint.fromMap(Map<String, dynamic> data) {
    return SellerRevenuePoint(
      period: SellerDashboardModel._text(data['y']),
      sales: SellerDashboardModel._asInt(data['a']),
      recovered: SellerDashboardModel._asInt(data['b']),
    );
  }
}

class SellerPerformanceMetrics {
  final String averageOrderValue;
  final String conversionRate;
  final int averageDaysToRecover;
  final String onTimeRecoveryRate;
  final int uniqueCustomers;
  final int repeatCustomers;
  final String repeatCustomerRate;
  final List<SellerDashboardRecord> topAreas;
  final List<SellerDashboardRecord> topProducts;

  const SellerPerformanceMetrics({
    required this.averageOrderValue,
    required this.conversionRate,
    required this.averageDaysToRecover,
    required this.onTimeRecoveryRate,
    required this.uniqueCustomers,
    required this.repeatCustomers,
    required this.repeatCustomerRate,
    required this.topAreas,
    required this.topProducts,
  });

  factory SellerPerformanceMetrics.fromMap(Map<String, dynamic> data) {
    return SellerPerformanceMetrics(
      averageOrderValue: SellerDashboardModel._money(data['avg_order_value']),
      conversionRate: SellerDashboardModel._percent(data['conversion_rate']),
      averageDaysToRecover: SellerDashboardModel._asInt(
        data['avg_days_to_recover'],
      ),
      onTimeRecoveryRate: SellerDashboardModel._percent(
        data['on_time_recovery_rate'],
      ),
      uniqueCustomers: SellerDashboardModel._asInt(data['unique_customers']),
      repeatCustomers: SellerDashboardModel._asInt(data['repeat_customers']),
      repeatCustomerRate: SellerDashboardModel._percent(
        data['repeat_customer_rate'],
      ),
      topAreas: SellerDashboardModel._asList(data['top_areas'])
          .map(
            (item) => SellerDashboardRecord(
              title: SellerDashboardModel._fallback(
                item['area_name']?.toString(),
                'Area',
              ),
              subtitle:
                  '${SellerDashboardModel._asInt(item['order_count'])} orders',
              badge: SellerDashboardModel._money(item['sales_amount']),
              details: {
                'Area Name': SellerDashboardModel._text(item['area_name']),
                'Order Count': SellerDashboardModel._text(item['order_count']),
                'Sales Amount': SellerDashboardModel._money(
                  item['sales_amount'],
                ),
              },
            ),
          )
          .toList(growable: false),
      topProducts: SellerDashboardModel._asList(data['top_products'])
          .map(
            (item) => SellerDashboardRecord(
              title: SellerDashboardModel._fallback(
                item['product_name']?.toString(),
                'Product',
              ),
              subtitle:
                  '${SellerDashboardModel._asInt(item['order_count'])} orders',
              badge: SellerDashboardModel._money(item['sales_amount']),
              details: {
                'Product Name': SellerDashboardModel._text(
                  item['product_name'],
                ),
                'Order Count': SellerDashboardModel._text(item['order_count']),
                'Sales Amount': SellerDashboardModel._money(
                  item['sales_amount'],
                ),
              },
            ),
          )
          .toList(growable: false),
    );
  }
}
