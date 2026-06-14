import 'package:atompro/core/seller_plan_upgrade_exception.dart';
import 'package:atompro/features/seller/instalments/model/seller_instalments_model.dart';
import 'package:atompro/features/seller/instalments/repository/seller_instalments_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sellerInstalmentsListProvider = FutureProvider.autoDispose
    .family<SellerInstalmentsListResponse, SellerInstalmentsQuery>((
      ref,
      query,
    ) async {
      try {
        return await ref
            .read(sellerInstalmentsRepositoryProvider)
            .getInstalmentsList(query);
      } on SellerPlanUpgradeException {
        // Pin the errored state so the autoDispose provider isn't disposed and
        // re-run on every gate-screen rebuild (infinite refetch loop).
        ref.keepAlive();
        rethrow;
      }
    });

final sellerInstalmentOrderDetailProvider = FutureProvider.autoDispose
    .family<SellerInstalmentOrderDetail, int>((ref, orderId) {
      return ref
          .read(sellerInstalmentsRepositoryProvider)
          .getOrderDetail(orderId);
    });

final sellerInstalmentInvoiceDataProvider = FutureProvider.autoDispose
    .family<SellerInstalmentInvoiceData, int>((ref, instalmentId) {
      return ref
          .read(sellerInstalmentsRepositoryProvider)
          .getInvoiceData(instalmentId);
    });
