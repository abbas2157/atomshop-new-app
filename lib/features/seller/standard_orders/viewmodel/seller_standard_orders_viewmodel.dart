import 'package:atompro/features/seller/standard_orders/model/seller_standard_orders_model.dart';
import 'package:atompro/features/seller/standard_orders/repository/seller_standard_orders_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sellerStandardOrdersProvider = FutureProvider.autoDispose
    .family<SellerStandardOrdersResponse, int>((ref, page) {
      return ref
          .read(sellerStandardOrdersRepositoryProvider)
          .getOrders(page: page);
    });

final sellerStandardOrderDetailsProvider = FutureProvider.autoDispose
    .family<SellerStandardOrderDetails, String>((ref, orderUuid) {
      return ref
          .read(sellerStandardOrdersRepositoryProvider)
          .getOrderDetails(orderUuid);
    });
