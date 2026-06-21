import 'package:atompro/core/seller_plan_upgrade_exception.dart';
import 'package:atompro/features/seller/customers/model/seller_customers_model.dart';
import 'package:atompro/features/seller/customers/repository/seller_customers_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sellerCustomersProvider = FutureProvider.autoDispose
    .family<SellerCustomersResponse, SellerCustomersQuery>((ref, query) async {
      try {
        return await ref
            .read(sellerCustomersRepositoryProvider)
            .getCustomers(query);
      } on SellerPlanUpgradeException catch (e) {
        // Return the gate as data so the provider settles into a stable
        // AsyncData state instead of an AsyncError that re-runs every rebuild.
        ref.keepAlive();
        return SellerCustomersResponse.gated(e);
      }
    });

final sellerCustomersNotificationCountProvider =
    FutureProvider.autoDispose<int>((ref) {
      return ref.read(sellerCustomersRepositoryProvider).getNotificationCount();
    });

final sellerMyCustomersTotalProvider =
    FutureProvider.autoDispose<int>((ref) async {
      final res = await ref.read(sellerCustomersRepositoryProvider).getCustomers(
            const SellerCustomersQuery(scope: SellerCustomerScope.mine, page: 1),
          );
      return res.pagination.total;
    });

final sellerOtherCustomersTotalProvider =
    FutureProvider.autoDispose<int>((ref) async {
      final res = await ref.read(sellerCustomersRepositoryProvider).getCustomers(
            const SellerCustomersQuery(scope: SellerCustomerScope.other, page: 1),
          );
      return res.pagination.total;
    });

final sellerCustomerProfileProvider = FutureProvider.autoDispose
    .family<SellerCustomerDetails, String>((ref, customerUuid) {
      return ref
          .read(sellerCustomersRepositoryProvider)
          .getCustomerProfile(customerUuid);
    });

final sellerCustomerInstalmentsProvider = FutureProvider.autoDispose
    .family<SellerCustomerInstalmentsResponse, String>((ref, customerUuid) {
      return ref
          .read(sellerCustomersRepositoryProvider)
          .getCustomerInstalments(customerUuid: customerUuid);
    });

final sellerCustomerCustomOrdersProvider = FutureProvider.autoDispose
    .family<SellerCustomerCustomOrdersResponse, String>((ref, customerUuid) {
      return ref
          .read(sellerCustomersRepositoryProvider)
          .getCustomerCustomOrders(customerUuid: customerUuid);
    });

final sellerCustomerAreasProvider = FutureProvider.autoDispose
    .family<List<SellerCustomerArea>, int>((ref, cityId) {
      return ref.read(sellerCustomersRepositoryProvider).getAreasByCity(cityId);
    });

final sellerCustomerCitiesProvider =
    FutureProvider.autoDispose<List<SellerCustomerArea>>((ref) {
      return ref.read(sellerCustomersRepositoryProvider).getCities();
    });
