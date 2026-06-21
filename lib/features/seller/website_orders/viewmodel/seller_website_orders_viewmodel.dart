import 'package:atompro/core/seller_plan_upgrade_exception.dart';
import 'package:atompro/features/seller/website_orders/model/seller_website_orders_model.dart';
import 'package:atompro/features/seller/website_orders/repository/seller_website_orders_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sellerWebsiteOrdersTotalProvider = FutureProvider.autoDispose<int>((ref) async {
  final res = await ref
      .read(sellerWebsiteOrdersRepositoryProvider)
      .getWebsiteOrders(page: 1);
  return res.pagination.total;
});

final sellerWebsiteOrdersProvider = FutureProvider.autoDispose
    .family<SellerWebsiteOrdersResponse, SellerWebsiteOrdersQuery>(
        (ref, query) async {
  // The plan gate is returned as DATA (SellerWebsiteOrdersResponse.gated),
  // never thrown. A thrown SellerPlanUpgradeException left the provider in an
  // AsyncError state that was re-executed on every rebuild — an infinite
  // refetch loop. Settling into a stable AsyncData state stops it. The screen
  // reads `response.gate` to decide whether to show the plan gate.
  try {
    return await ref
        .read(sellerWebsiteOrdersRepositoryProvider)
        .getWebsiteOrders(search: query.search, page: query.page);
  } on SellerPlanUpgradeException catch (e) {
    ref.keepAlive();
    return SellerWebsiteOrdersResponse.gated(e);
  }
});
