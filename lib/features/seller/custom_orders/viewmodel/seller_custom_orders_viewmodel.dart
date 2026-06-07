import 'package:atompro/features/seller/custom_orders/model/seller_custom_orders_model.dart';
import 'package:atompro/features/seller/custom_orders/repository/seller_custom_orders_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sellerCustomOrdersProvider = FutureProvider.autoDispose
    .family<SellerCustomOrdersResponse, SellerCustomOrdersQuery>((ref, query) {
      return ref
          .read(sellerCustomOrdersRepositoryProvider)
          .getCustomOrders(query);
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
