import 'package:atompro/features/seller/profile/model/seller_profile_model.dart';
import 'package:atompro/features/seller/profile/repository/seller_profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sellerProfileBundleProvider =
    FutureProvider.autoDispose<SellerProfileBundle>((ref) {
      return ref.read(sellerProfileRepositoryProvider).getProfileBundle();
    });
