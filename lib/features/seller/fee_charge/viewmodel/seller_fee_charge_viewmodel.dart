import 'package:atompro/features/seller/fee_charge/model/seller_fee_charge_model.dart';
import 'package:atompro/features/seller/fee_charge/repository/seller_fee_charge_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sellerFeeChargeProvider = FutureProvider.autoDispose
    .family<SellerFeeChargeResponse, int>((ref, page) {
      return ref
          .read(sellerFeeChargeRepositoryProvider)
          .getFeeCharges(page: page);
    });
