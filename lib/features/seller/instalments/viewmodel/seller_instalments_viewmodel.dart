import 'package:atompro/features/seller/instalments/model/seller_instalments_model.dart';
import 'package:atompro/features/seller/instalments/repository/seller_instalments_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sellerInstalmentsProvider = FutureProvider.autoDispose
    .family<SellerInstalmentsResponse, SellerInstalmentsQuery>((ref, query) {
      return ref
          .read(sellerInstalmentsRepositoryProvider)
          .getInstalments(query);
    });
