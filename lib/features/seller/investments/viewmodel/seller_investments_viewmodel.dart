import 'package:atompro/core/seller_plan_upgrade_exception.dart';
import 'package:atompro/features/seller/investments/model/seller_investment_model.dart';
import 'package:atompro/features/seller/investments/repository/seller_investments_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sellerInvestmentsProvider = FutureProvider.autoDispose
    .family<SellerInvestmentsResponse, int>((ref, page) async {
      try {
        return await ref
            .read(sellerInvestmentsRepositoryProvider)
            .getInvestments(page: page);
      } on SellerPlanUpgradeException catch (e) {
        // Return the gate as data so the provider settles into a stable
        // AsyncData state instead of an AsyncError that re-runs every rebuild.
        ref.keepAlive();
        return SellerInvestmentsResponse.gated(e);
      }
    });

final sellerInvestmentDetailsProvider = FutureProvider.autoDispose
    .family<SellerInvestmentDetails, int>((ref, investmentId) {
      return ref
          .read(sellerInvestmentsRepositoryProvider)
          .getInvestmentDetails(investmentId);
    });
