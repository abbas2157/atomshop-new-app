import 'package:atompro/features/seller/subscription/model/seller_subscription_model.dart';
import 'package:atompro/features/seller/subscription/repository/seller_subscription_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Loads the seller's subscription plan, payment-action flags, commission
/// summary and payment history in one call.
final sellerSubscriptionProvider =
    FutureProvider.autoDispose<SellerSubscriptionData>((ref) {
      return ref.read(sellerSubscriptionRepositoryProvider).getSubscription();
    });
