import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:atompro/core/seller_plan_upgrade_exception.dart';
import 'package:atompro/features/seller/core/models/seller_gated.dart';
import 'package:atompro/features/seller/reports/model/seller_reports_model.dart';
import 'package:atompro/features/seller/reports/repository/seller_reports_repository.dart';

// Every report provider returns SellerGated<T>: the plan gate is carried as
// data, never thrown. A thrown SellerPlanUpgradeException leaves an autoDispose
// provider in an AsyncError state that re-runs on every rebuild — an infinite
// refetch loop. keepAlive + returning SellerGated.gated keeps it stable.

// 1. No-param: list of report customers (picker helper). On gate, return an
//    empty list so the dropdown simply shows nothing — no gate UI needed here,
//    the screen's main report provider surfaces the gate.
final sellerReportCustomersProvider =
    FutureProvider.autoDispose<List<ReportCustomer>>((ref) async {
      try {
        return await ref
            .read(sellerReportsRepositoryProvider)
            .getReportCustomers();
      } on SellerPlanUpgradeException {
        ref.keepAlive();
        return const [];
      }
    });

// 2. Recovery sheet — parameterised by RecoverySheetQuery
final sellerRecoverySheetProvider = FutureProvider.autoDispose
    .family<SellerGated<RecoverySheetResponse>, RecoverySheetQuery>((
      ref,
      query,
    ) async {
      try {
        return SellerGated.value(
          await ref.read(sellerReportsRepositoryProvider).getRecoverySheet(query),
        );
      } on SellerPlanUpgradeException catch (e) {
        ref.keepAlive();
        return SellerGated.gated(e);
      }
    });

// 3. Customer ledger — parameterised by CustomerLedgerQuery
final sellerCustomerLedgerProvider = FutureProvider.autoDispose
    .family<SellerGated<CustomerLedgerResponse>, CustomerLedgerQuery>((
      ref,
      query,
    ) async {
      try {
        return SellerGated.value(
          await ref.read(sellerReportsRepositoryProvider).getCustomerLedger(query),
        );
      } on SellerPlanUpgradeException catch (e) {
        ref.keepAlive();
        return SellerGated.gated(e);
      }
    });

// 4. No-param: aging report
final sellerAgingReportProvider =
    FutureProvider.autoDispose<SellerGated<AgingResponse>>((ref) async {
      try {
        return SellerGated.value(
          await ref.read(sellerReportsRepositoryProvider).getAging(),
        );
      } on SellerPlanUpgradeException catch (e) {
        ref.keepAlive();
        return SellerGated.gated(e);
      }
    });

// 5. Upcoming dues — parameterised by UpcomingDuesQuery
final sellerUpcomingDuesProvider = FutureProvider.autoDispose
    .family<SellerGated<UpcomingDuesResponse>, UpcomingDuesQuery>((
      ref,
      query,
    ) async {
      try {
        return SellerGated.value(
          await ref.read(sellerReportsRepositoryProvider).getUpcomingDues(query),
        );
      } on SellerPlanUpgradeException catch (e) {
        ref.keepAlive();
        return SellerGated.gated(e);
      }
    });

// 6. Defaulters — parameterised by DefaultersQuery
final sellerDefaultersProvider = FutureProvider.autoDispose
    .family<SellerGated<DefaultersResponse>, DefaultersQuery>((
      ref,
      query,
    ) async {
      try {
        return SellerGated.value(
          await ref.read(sellerReportsRepositoryProvider).getDefaulters(query),
        );
      } on SellerPlanUpgradeException catch (e) {
        ref.keepAlive();
        return SellerGated.gated(e);
      }
    });

// 7. Collection — parameterised by CollectionQuery
final sellerCollectionProvider = FutureProvider.autoDispose
    .family<SellerGated<CollectionResponse>, CollectionQuery>((
      ref,
      query,
    ) async {
      try {
        return SellerGated.value(
          await ref.read(sellerReportsRepositoryProvider).getCollection(query),
        );
      } on SellerPlanUpgradeException catch (e) {
        ref.keepAlive();
        return SellerGated.gated(e);
      }
    });

// 8. Sales revenue — parameterised by SalesRevenueQuery
final sellerSalesRevenueProvider = FutureProvider.autoDispose
    .family<SellerGated<SalesRevenueResponse>, SalesRevenueQuery>((
      ref,
      query,
    ) async {
      try {
        return SellerGated.value(
          await ref.read(sellerReportsRepositoryProvider).getSalesRevenue(query),
        );
      } on SellerPlanUpgradeException catch (e) {
        ref.keepAlive();
        return SellerGated.gated(e);
      }
    });

// 9. Order summary — parameterised by OrderSummaryQuery
final sellerOrderSummaryProvider = FutureProvider.autoDispose
    .family<SellerGated<OrderSummaryResponse>, OrderSummaryQuery>((
      ref,
      query,
    ) async {
      try {
        return SellerGated.value(
          await ref.read(sellerReportsRepositoryProvider).getOrderSummary(query),
        );
      } on SellerPlanUpgradeException catch (e) {
        ref.keepAlive();
        return SellerGated.gated(e);
      }
    });

// 10. Lead funnel — parameterised by LeadFunnelQuery
final sellerLeadFunnelProvider = FutureProvider.autoDispose
    .family<SellerGated<LeadFunnelResponse>, LeadFunnelQuery>((
      ref,
      query,
    ) async {
      try {
        return SellerGated.value(
          await ref.read(sellerReportsRepositoryProvider).getLeadFunnel(query),
        );
      } on SellerPlanUpgradeException catch (e) {
        ref.keepAlive();
        return SellerGated.gated(e);
      }
    });

// 11. Offers report — parameterised by OffersReportQuery
final sellerOffersReportProvider = FutureProvider.autoDispose
    .family<SellerGated<OffersReportResponse>, OffersReportQuery>((
      ref,
      query,
    ) async {
      try {
        return SellerGated.value(
          await ref.read(sellerReportsRepositoryProvider).getOffersReport(query),
        );
      } on SellerPlanUpgradeException catch (e) {
        ref.keepAlive();
        return SellerGated.gated(e);
      }
    });

// 12. No-param: outstanding balances
final sellerOutstandingProvider =
    FutureProvider.autoDispose<SellerGated<OutstandingResponse>>((ref) async {
      try {
        return SellerGated.value(
          await ref.read(sellerReportsRepositoryProvider).getOutstanding(),
        );
      } on SellerPlanUpgradeException catch (e) {
        ref.keepAlive();
        return SellerGated.gated(e);
      }
    });

// 13. Payment history — parameterised by PaymentHistoryQuery
final sellerPaymentHistoryProvider = FutureProvider.autoDispose
    .family<SellerGated<PaymentHistoryResponse>, PaymentHistoryQuery>((
      ref,
      query,
    ) async {
      try {
        return SellerGated.value(
          await ref
              .read(sellerReportsRepositoryProvider)
              .getPaymentHistory(query),
        );
      } on SellerPlanUpgradeException catch (e) {
        ref.keepAlive();
        return SellerGated.gated(e);
      }
    });
