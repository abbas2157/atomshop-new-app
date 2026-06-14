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
      } on SellerPlanUpgradeException {
        // Pin the errored state so the autoDispose provider isn't disposed and
        // re-run on every gate-screen rebuild (infinite refetch loop).
        ref.keepAlive();
        rethrow;
      }
    });

final sellerInvestmentDetailsProvider = FutureProvider.autoDispose
    .family<SellerInvestmentDetails, int>((ref, investmentId) {
      return ref
          .read(sellerInvestmentsRepositoryProvider)
          .getInvestmentDetails(investmentId);
    });
