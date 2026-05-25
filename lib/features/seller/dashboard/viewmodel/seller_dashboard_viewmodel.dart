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
      final results = await Future.wait([
        repository.getDashboard(),
        repository.getSalesRevenue(
          from: query.revenueFrom,
          to: query.revenueTo,
        ),
      ]);

      return SellerDashboardBundle(
        dashboard: results[0] as SellerDashboardModel,
        revenue: results[1] as SellerSalesRevenueModel,
      );
    });
