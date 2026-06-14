import 'package:atompro/core/seller_plan_upgrade_exception.dart';
import 'package:atompro/features/seller/sales_team/model/seller_sales_team_model.dart';
import 'package:atompro/features/seller/sales_team/repository/seller_sales_team_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SellerSalesTeamQuery {
  final int page;
  final int? status; // 1 = active, 0 = inactive, null = all
  final String? memberType; // 'sale' / 'recovery' / null = all
  final String? query;

  const SellerSalesTeamQuery({
    this.page = 1,
    this.status,
    this.memberType,
    this.query,
  });

  SellerSalesTeamQuery copyWith({
    int? page,
    int? status,
    String? memberType,
    String? query,
    bool clearStatus = false,
    bool clearMemberType = false,
  }) {
    return SellerSalesTeamQuery(
      page: page ?? this.page,
      status: clearStatus ? null : (status ?? this.status),
      memberType: clearMemberType ? null : (memberType ?? this.memberType),
      query: query ?? this.query,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SellerSalesTeamQuery &&
      other.page == page &&
      other.status == status &&
      other.memberType == memberType &&
      other.query == query;

  @override
  int get hashCode => Object.hash(page, status, memberType, query);
}

final sellerSalesTeamProvider = FutureProvider.autoDispose
    .family<SellerSalesTeamResponse, SellerSalesTeamQuery>((ref, q) async {
      try {
        return await ref.read(sellerSalesTeamRepositoryProvider).getMembers(
              page: q.page,
              status: q.status,
              memberType: q.memberType,
              query: q.query,
            );
      } on SellerPlanUpgradeException {
        // Pin the errored state so the autoDispose provider isn't disposed and
        // re-run on every gate-screen rebuild (infinite refetch loop).
        ref.keepAlive();
        rethrow;
      }
    });

final sellerSalesTeamEditProvider = FutureProvider.autoDispose
    .family<SellerSalesTeamEditData, String>((ref, memberUuid) {
      return ref
          .read(sellerSalesTeamRepositoryProvider)
          .getMemberEdit(memberUuid);
    });

final sellerSalesTeamPerformanceProvider = FutureProvider.autoDispose
    .family<SellerSalesTeamPerformance, String>((ref, memberUuid) {
      return ref
          .read(sellerSalesTeamRepositoryProvider)
          .getPerformance(memberUuid);
    });
