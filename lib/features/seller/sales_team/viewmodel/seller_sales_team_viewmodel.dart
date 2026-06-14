import 'package:atompro/core/seller_plan_upgrade_exception.dart';
import 'package:atompro/features/seller/core/models/seller_gated.dart';
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
      } on SellerPlanUpgradeException catch (e) {
        // Return the gate as data so the provider settles into a stable
        // AsyncData state instead of an AsyncError that re-runs every rebuild.
        ref.keepAlive();
        return SellerSalesTeamResponse.gated(e);
      }
    });

final sellerSalesTeamEditProvider = FutureProvider.autoDispose
    .family<SellerGated<SellerSalesTeamEditData>, String>((ref, memberUuid) async {
      try {
        return SellerGated.value(
          await ref.read(sellerSalesTeamRepositoryProvider).getMemberEdit(memberUuid),
        );
      } on SellerPlanUpgradeException catch (e) {
        ref.keepAlive();
        return SellerGated.gated(e);
      }
    });

final sellerSalesTeamPerformanceProvider = FutureProvider.autoDispose
    .family<SellerGated<SellerSalesTeamPerformance>, String>((
      ref,
      memberUuid,
    ) async {
      try {
        return SellerGated.value(
          await ref
              .read(sellerSalesTeamRepositoryProvider)
              .getPerformance(memberUuid),
        );
      } on SellerPlanUpgradeException catch (e) {
        ref.keepAlive();
        return SellerGated.gated(e);
      }
    });
