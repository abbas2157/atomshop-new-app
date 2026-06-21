import 'package:atompro/core/seller_plan_upgrade_exception.dart';
import 'package:atompro/features/seller/custom_orders/model/seller_custom_orders_model.dart';
import 'package:atompro/features/seller/custom_orders/repository/seller_custom_orders_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sellerCustomOrdersProvider = FutureProvider.autoDispose
    .family<SellerCustomOrdersResponse, SellerCustomOrdersQuery>(
        (ref, query) async {
  try {
    return await ref
        .read(sellerCustomOrdersRepositoryProvider)
        .getCustomOrders(query);
  } on SellerPlanUpgradeException catch (e) {
    // Return the gate as data (not thrown) so the provider settles into a
    // stable AsyncData state instead of an AsyncError that re-runs on every
    // rebuild (infinite refetch loop). The screen reads `.gate`.
    ref.keepAlive();
    return SellerCustomOrdersResponse.gated(e);
  }
});

final sellerCustomOrderDetailsProvider = FutureProvider.autoDispose
    .family<SellerCustomOrderDetails, String>((ref, orderUuid) {
      return ref
          .read(sellerCustomOrdersRepositoryProvider)
          .getCustomOrderDetails(orderUuid);
    });

final sellerCustomOrderGuarantorProvider = FutureProvider.autoDispose
    .family<SellerCustomOrderGuarantor, String>((ref, orderUuid) {
      return ref
          .read(sellerCustomOrdersRepositoryProvider)
          .getCustomOrderGuarantor(orderUuid);
    });

final sellerCustomOrdersPendingCountProvider = FutureProvider.autoDispose<int>((
  ref,
) {
  return ref.read(sellerCustomOrdersRepositoryProvider).getPendingCount();
});

final sellerMyAreaOrdersTotalProvider = FutureProvider.autoDispose<int>((ref) async {
  final res = await ref
      .read(sellerCustomOrdersRepositoryProvider)
      .getCustomOrders(const SellerCustomOrdersQuery(page: 1));
  return res.pagination.total;
});

final sellerCustomOrdersStatusCountsProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) {
      return ref.read(sellerCustomOrdersRepositoryProvider).getStatusCounts();
    });

final sellerCustomOrderCategoriesProvider =
    FutureProvider.autoDispose<List<SellerCustomOrderLookup>>((ref) {
      return ref.read(sellerCustomOrdersRepositoryProvider).getCategories();
    });

final sellerCustomOrderBrandsProvider =
    FutureProvider.autoDispose<List<SellerCustomOrderLookup>>((ref) {
      return ref.read(sellerCustomOrdersRepositoryProvider).getBrands();
    });
