import 'package:atompro/features/seller/instalments/model/seller_instalments_model.dart';
import 'package:atompro/features/seller/instalments/repository/seller_instalments_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sellerInstalmentsListProvider = FutureProvider.autoDispose
    .family<SellerInstalmentsListResponse, SellerInstalmentsQuery>((ref, query) {
      return ref
          .read(sellerInstalmentsRepositoryProvider)
          .getInstalmentsList(query);
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
