import 'package:atompro/core/seller_plan_upgrade_exception.dart';
import 'package:atompro/features/seller/fee_charge/model/seller_fee_charge_model.dart';
import 'package:atompro/features/seller/fee_charge/repository/seller_fee_charge_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sellerFeeChargeProvider = FutureProvider.autoDispose
    .family<SellerFeeChargeResponse, int>((ref, page) async {
      try {
        return await ref
            .read(sellerFeeChargeRepositoryProvider)
            .getFeeCharges(page: page);
      } on SellerPlanUpgradeException catch (e) {
        // Return the gate as data so the provider settles into a stable
        // AsyncData state instead of an AsyncError that re-runs every rebuild.
        ref.keepAlive();
        return SellerFeeChargeResponse.gated(e);
      }
    });
