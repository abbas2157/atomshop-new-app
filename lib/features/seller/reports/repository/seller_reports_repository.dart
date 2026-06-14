import 'package:atompro/core/auth/seller_session_manager.dart';
import 'package:atompro/core/network/api_endpoints.dart';
import 'package:atompro/core/network/network_manager.dart';
import 'package:atompro/core/network/network_provider.dart';
import 'package:atompro/features/seller/reports/model/seller_reports_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sellerReportsRepositoryProvider = Provider<SellerReportsRepository>((ref) {
  return SellerReportsRepository(ref.watch(networkManagerProvider));
});

class SellerReportsRepository {
  final NetworkManager _network;

  SellerReportsRepository(this._network);

  // ── 1. Customers ─────────────────────────────────────────────────────────────

  /// GET seller-app/reports/customers
  Future<List<ReportCustomer>> getReportCustomers() async {
    final response = await _get(ApiEndpoints.sellerReportsCustomers);
    final raw = response['data'];
    final list = raw is List ? raw : <dynamic>[];
    return list
        .whereType<Map>()
        .map((item) => ReportCustomer.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  // ── 2. Recovery Sheet ────────────────────────────────────────────────────────

  /// GET seller-app/reports/recovery-sheet?status=&q=
  Future<RecoverySheetResponse> getRecoverySheet(
    RecoverySheetQuery query,
  ) async {
    final queryString = Uri(queryParameters: query.toQueryParameters()).query;
    final endpoint = queryString.isEmpty
        ? ApiEndpoints.sellerReportsRecoverySheet
        : '${ApiEndpoints.sellerReportsRecoverySheet}?$queryString';
    final response = await _get(endpoint);
    return RecoverySheetResponse.fromJson(Map<String, dynamic>.from(response));
  }

  // ── 3. Customer Ledger ───────────────────────────────────────────────────────

  /// GET seller-app/reports/customer-ledger?customer_id=&month=&year=
  Future<CustomerLedgerResponse> getCustomerLedger(
    CustomerLedgerQuery query,
  ) async {
    final queryString = Uri(queryParameters: query.toQueryParameters()).query;
    final endpoint = queryString.isEmpty
        ? ApiEndpoints.sellerReportsCustomerLedger
        : '${ApiEndpoints.sellerReportsCustomerLedger}?$queryString';
    final response = await _get(endpoint);
    return CustomerLedgerResponse.fromJson(Map<String, dynamic>.from(response));
  }

  // ── 4. Aging ─────────────────────────────────────────────────────────────────

  /// GET seller-app/reports/aging
  Future<AgingResponse> getAging() async {
    final response = await _get(ApiEndpoints.sellerReportsAging);
    return AgingResponse.fromJson(Map<String, dynamic>.from(response));
  }

  // ── 5. Upcoming Dues ─────────────────────────────────────────────────────────

  /// GET seller-app/reports/upcoming-dues?days=
  Future<UpcomingDuesResponse> getUpcomingDues(
    UpcomingDuesQuery query,
  ) async {
    final queryString = Uri(queryParameters: query.toQueryParameters()).query;
    final endpoint = queryString.isEmpty
        ? ApiEndpoints.sellerReportsUpcomingDues
        : '${ApiEndpoints.sellerReportsUpcomingDues}?$queryString';
    final response = await _get(endpoint);
    return UpcomingDuesResponse.fromJson(Map<String, dynamic>.from(response));
  }

  // ── 6. Defaulters ────────────────────────────────────────────────────────────

  /// GET seller-app/reports/defaulters?missed=
  Future<DefaultersResponse> getDefaulters(DefaultersQuery query) async {
    final queryString = Uri(queryParameters: query.toQueryParameters()).query;
    final endpoint = queryString.isEmpty
        ? ApiEndpoints.sellerReportsDefaulters
        : '${ApiEndpoints.sellerReportsDefaulters}?$queryString';
    final response = await _get(endpoint);
    return DefaultersResponse.fromJson(Map<String, dynamic>.from(response));
  }

  // ── 7. Collection ────────────────────────────────────────────────────────────

  /// GET seller-app/reports/collection?mode=&from=&to=
  Future<CollectionResponse> getCollection(CollectionQuery query) async {
    final queryString = Uri(queryParameters: query.toQueryParameters()).query;
    final endpoint = queryString.isEmpty
        ? ApiEndpoints.sellerReportsCollection
        : '${ApiEndpoints.sellerReportsCollection}?$queryString';
    final response = await _get(endpoint);
    return CollectionResponse.fromJson(Map<String, dynamic>.from(response));
  }

  // ── 8. Sales Revenue ─────────────────────────────────────────────────────────

  /// GET seller-app/reports/sales-revenue?month=&year=
  Future<SalesRevenueResponse> getSalesRevenue(
    SalesRevenueQuery query,
  ) async {
    final queryString = Uri(queryParameters: query.toQueryParameters()).query;
    final endpoint = queryString.isEmpty
        ? ApiEndpoints.sellerReportsSalesRevenue
        : '${ApiEndpoints.sellerReportsSalesRevenue}?$queryString';
    final response = await _get(endpoint);
    return SalesRevenueResponse.fromJson(Map<String, dynamic>.from(response));
  }

  // ── 9. Order Summary ─────────────────────────────────────────────────────────

  /// GET seller-app/reports/order-summary?from=&to=&status=
  Future<OrderSummaryResponse> getOrderSummary(
    OrderSummaryQuery query,
  ) async {
    final queryString = Uri(queryParameters: query.toQueryParameters()).query;
    final endpoint = queryString.isEmpty
        ? ApiEndpoints.sellerReportsOrderSummary
        : '${ApiEndpoints.sellerReportsOrderSummary}?$queryString';
    final response = await _get(endpoint);
    return OrderSummaryResponse.fromJson(Map<String, dynamic>.from(response));
  }

  // ── 10. Lead Funnel ──────────────────────────────────────────────────────────

  /// GET seller-app/reports/lead-funnel?from=&to=
  Future<LeadFunnelResponse> getLeadFunnel(LeadFunnelQuery query) async {
    final queryString = Uri(queryParameters: query.toQueryParameters()).query;
    final endpoint = queryString.isEmpty
        ? ApiEndpoints.sellerReportsLeadFunnel
        : '${ApiEndpoints.sellerReportsLeadFunnel}?$queryString';
    final response = await _get(endpoint);
    return LeadFunnelResponse.fromJson(Map<String, dynamic>.from(response));
  }

  // ── 11. Offers Report ────────────────────────────────────────────────────────

  /// GET seller-app/reports/offers-report?from=&to=&status=
  Future<OffersReportResponse> getOffersReport(
    OffersReportQuery query,
  ) async {
    final queryString = Uri(queryParameters: query.toQueryParameters()).query;
    final endpoint = queryString.isEmpty
        ? ApiEndpoints.sellerReportsOffersReport
        : '${ApiEndpoints.sellerReportsOffersReport}?$queryString';
    final response = await _get(endpoint);
    return OffersReportResponse.fromJson(Map<String, dynamic>.from(response));
  }

  // ── 12. Outstanding ──────────────────────────────────────────────────────────

  /// GET seller-app/reports/outstanding
  Future<OutstandingResponse> getOutstanding() async {
    final response = await _get(ApiEndpoints.sellerReportsOutstanding);
    return OutstandingResponse.fromJson(Map<String, dynamic>.from(response));
  }

  // ── 13. Payment History ──────────────────────────────────────────────────────

  /// GET seller-app/reports/payment-history?customer_id=
  Future<PaymentHistoryResponse> getPaymentHistory(
    PaymentHistoryQuery query,
  ) async {
    final queryString = Uri(queryParameters: query.toQueryParameters()).query;
    final endpoint = queryString.isEmpty
        ? ApiEndpoints.sellerReportsPaymentHistory
        : '${ApiEndpoints.sellerReportsPaymentHistory}?$queryString';
    final response = await _get(endpoint);
    return PaymentHistoryResponse.fromJson(Map<String, dynamic>.from(response));
  }

  // ── Internal helper ──────────────────────────────────────────────────────────

  Future<dynamic> _get(String endpoint) async {
    final token = await SellerSessionManager.getToken();
    final response = await _network.getRequest(endpoint, token: token);
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Request failed.');
    }
    return response;
  }
}
