import 'package:atompro/core/seller_plan_upgrade_exception.dart';
import 'package:atompro/features/seller/dashboard/model/seller_dashboard_model.dart';
import 'package:atompro/features/seller/dashboard/repository/seller_dashboard_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SellerDashboardQuery {
  final String? revenueFrom;
  final String? revenueTo;

  const SellerDashboardQuery({this.revenueFrom, this.revenueTo});

  bool get hasRevenueRange =>
      revenueFrom != null &&
      revenueFrom!.trim().isNotEmpty &&
      revenueTo != null &&
      revenueTo!.trim().isNotEmpty;

  @override
  bool operator ==(Object other) {
    return other is SellerDashboardQuery &&
        other.revenueFrom == revenueFrom &&
        other.revenueTo == revenueTo;
  }

  @override
  int get hashCode => Object.hash(revenueFrom, revenueTo);
}

final sellerDashboardProvider = FutureProvider.autoDispose
    .family<SellerDashboardBundle, SellerDashboardQuery>((ref, query) async {
  final repository = ref.read(sellerDashboardRepositoryProvider);

  // Dashboard loads for all sellers regardless of plan.
  final dashboard = await repository.getDashboard();

  // Sales revenue requires the Financial plan. If the seller doesn't have it,
  // store the gate exception in the bundle so Insights can show the plan gate
  // while the home dashboard still renders normally.
  SellerSalesRevenueModel revenue;
  SellerPlanUpgradeException? revenueGate;
  try {
    revenue = await repository.getSalesRevenue(
      from: query.revenueFrom,
      to: query.revenueTo,
    );
  } on SellerPlanUpgradeException catch (e) {
    ref.keepAlive();
    revenue = SellerSalesRevenueModel.empty();
    revenueGate = e;
  }

  return SellerDashboardBundle(
    dashboard: dashboard,
    revenue: revenue,
    revenueGate: revenueGate,
  );
});
