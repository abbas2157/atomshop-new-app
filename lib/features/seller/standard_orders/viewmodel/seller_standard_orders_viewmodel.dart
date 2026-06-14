import 'package:atompro/core/seller_plan_upgrade_exception.dart';
import 'package:atompro/features/seller/standard_orders/model/seller_standard_orders_model.dart';
import 'package:atompro/features/seller/standard_orders/repository/seller_standard_orders_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sellerStandardOrdersProvider = FutureProvider.autoDispose
    .family<SellerStandardOrdersResponse, int>((ref, page) async {
      try {
        return await ref
            .read(sellerStandardOrdersRepositoryProvider)
            .getOrders(page: page);
      } on SellerPlanUpgradeException catch (e) {
        // Return the gate as data so the provider settles into a stable
        // AsyncData state instead of an AsyncError that re-runs every rebuild.
        ref.keepAlive();
        return SellerStandardOrdersResponse.gated(e);
      }
    });

final sellerStandardOrderDetailsProvider = FutureProvider.autoDispose
    .family<SellerStandardOrderDetails, String>((ref, orderUuid) {
      return ref
          .read(sellerStandardOrdersRepositoryProvider)
          .getOrderDetails(orderUuid);
    });
