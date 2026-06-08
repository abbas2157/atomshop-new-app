import 'package:atompro/features/seller/customers/model/seller_customers_model.dart';
import 'package:atompro/features/seller/customers/repository/seller_customers_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sellerCustomersProvider = FutureProvider.autoDispose
    .family<SellerCustomersResponse, SellerCustomersQuery>((ref, query) {
      return ref.read(sellerCustomersRepositoryProvider).getCustomers(query);
    });

final sellerCustomersNotificationCountProvider =
    FutureProvider.autoDispose<int>((ref) {
      return ref.read(sellerCustomersRepositoryProvider).getNotificationCount();
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
