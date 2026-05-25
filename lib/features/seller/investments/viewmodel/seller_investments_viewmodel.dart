import 'package:atompro/features/seller/investments/model/seller_investment_model.dart';
import 'package:atompro/features/seller/investments/repository/seller_investments_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sellerInvestmentsProvider = FutureProvider.autoDispose
    .family<SellerInvestmentsResponse, int>((ref, page) {
      return ref
          .read(sellerInvestmentsRepositoryProvider)
          .getInvestments(page: page);
    });

final sellerInvestmentDetailsProvider = FutureProvider.autoDispose
    .family<SellerInvestmentDetails, int>((ref, investmentId) {
      return ref
          .read(sellerInvestmentsRepositoryProvider)
          .getInvestmentDetails(investmentId);
    });
