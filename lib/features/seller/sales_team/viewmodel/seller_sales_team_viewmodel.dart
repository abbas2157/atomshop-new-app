import 'package:atompro/features/seller/sales_team/model/seller_sales_team_model.dart';
import 'package:atompro/features/seller/sales_team/repository/seller_sales_team_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sellerSalesTeamProvider = FutureProvider.autoDispose
    .family<SellerSalesTeamResponse, int>((ref, page) {
      return ref.read(sellerSalesTeamRepositoryProvider).getMembers(page: page);
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
