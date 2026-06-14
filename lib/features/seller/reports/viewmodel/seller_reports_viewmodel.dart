import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:atompro/features/seller/reports/model/seller_reports_model.dart';
import 'package:atompro/features/seller/reports/repository/seller_reports_repository.dart';

// 1. No-param: list of report customers
final sellerReportCustomersProvider =
    FutureProvider.autoDispose<List<ReportCustomer>>((ref) {
      return ref.read(sellerReportsRepositoryProvider).getReportCustomers();
    });

// 2. Recovery sheet — parameterised by RecoverySheetQuery
final sellerRecoverySheetProvider = FutureProvider.autoDispose
    .family<RecoverySheetResponse, RecoverySheetQuery>((ref, query) {
      return ref.read(sellerReportsRepositoryProvider).getRecoverySheet(query);
    });

// 3. Customer ledger — parameterised by CustomerLedgerQuery
final sellerCustomerLedgerProvider = FutureProvider.autoDispose
    .family<CustomerLedgerResponse, CustomerLedgerQuery>((ref, query) {
      return ref.read(sellerReportsRepositoryProvider).getCustomerLedger(query);
    });

// 4. No-param: aging report
final sellerAgingReportProvider =
    FutureProvider.autoDispose<AgingResponse>((ref) {
      return ref.read(sellerReportsRepositoryProvider).getAging();
    });

// 5. Upcoming dues — parameterised by UpcomingDuesQuery
final sellerUpcomingDuesProvider = FutureProvider.autoDispose
    .family<UpcomingDuesResponse, UpcomingDuesQuery>((ref, query) {
      return ref.read(sellerReportsRepositoryProvider).getUpcomingDues(query);
    });

// 6. Defaulters — parameterised by DefaultersQuery
final sellerDefaultersProvider = FutureProvider.autoDispose
    .family<DefaultersResponse, DefaultersQuery>((ref, query) {
      return ref.read(sellerReportsRepositoryProvider).getDefaulters(query);
    });

// 7. Collection — parameterised by CollectionQuery
final sellerCollectionProvider = FutureProvider.autoDispose
    .family<CollectionResponse, CollectionQuery>((ref, query) {
      return ref.read(sellerReportsRepositoryProvider).getCollection(query);
    });

// 8. Sales revenue — parameterised by SalesRevenueQuery
final sellerSalesRevenueProvider = FutureProvider.autoDispose
    .family<SalesRevenueResponse, SalesRevenueQuery>((ref, query) {
      return ref.read(sellerReportsRepositoryProvider).getSalesRevenue(query);
    });

// 9. Order summary — parameterised by OrderSummaryQuery
final sellerOrderSummaryProvider = FutureProvider.autoDispose
    .family<OrderSummaryResponse, OrderSummaryQuery>((ref, query) {
      return ref.read(sellerReportsRepositoryProvider).getOrderSummary(query);
    });

// 10. Lead funnel — parameterised by LeadFunnelQuery
final sellerLeadFunnelProvider = FutureProvider.autoDispose
    .family<LeadFunnelResponse, LeadFunnelQuery>((ref, query) {
      return ref.read(sellerReportsRepositoryProvider).getLeadFunnel(query);
    });

// 11. Offers report — parameterised by OffersReportQuery
final sellerOffersReportProvider = FutureProvider.autoDispose
    .family<OffersReportResponse, OffersReportQuery>((ref, query) {
      return ref.read(sellerReportsRepositoryProvider).getOffersReport(query);
    });

// 12. No-param: outstanding balances
final sellerOutstandingProvider =
    FutureProvider.autoDispose<OutstandingResponse>((ref) {
      return ref.read(sellerReportsRepositoryProvider).getOutstanding();
    });

// 13. Payment history — parameterised by PaymentHistoryQuery
final sellerPaymentHistoryProvider = FutureProvider.autoDispose
    .family<PaymentHistoryResponse, PaymentHistoryQuery>((ref, query) {
      return ref
          .read(sellerReportsRepositoryProvider)
          .getPaymentHistory(query);
    });
