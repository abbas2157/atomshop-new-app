import 'dart:io';

import 'package:atompro/core/auth/seller_session_manager.dart';
import 'package:atompro/core/network/api_endpoints.dart';
import 'package:atompro/core/network/network_manager.dart';
import 'package:atompro/core/network/network_provider.dart';
import 'package:atompro/features/seller/subscription/model/seller_subscription_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sellerSubscriptionRepositoryProvider =
    Provider<SellerSubscriptionRepository>((ref) {
      return SellerSubscriptionRepository(ref.watch(networkManagerProvider));
    });

class SellerSubscriptionRepository {
  final NetworkManager _network;

  SellerSubscriptionRepository(this._network);

  Future<SellerSubscriptionData> getSubscription() async {
    final token = await SellerSessionManager.getToken();
    final response = await _network.getRequest(
      ApiEndpoints.sellerSubscription,
      token: token,
    );
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to load subscription.');
    }
    return SellerSubscriptionData.fromResponse(
      Map<String, dynamic>.from(response),
    );
  }

  /// Submits a [paymentType] (`monthly` or `commission`) payment. The server
  /// computes the amount from the active subscription — no amount is sent.
  Future<SellerSubscriptionPayment> submitPayment({
    required String paymentType,
    required String paymentMethod,
    File? receipt,
    String? notes,
  }) async {
    final token = await SellerSessionManager.getToken();
    final data = <String, dynamic>{
      'payment_type': paymentType,
      'payment_method': paymentMethod,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    };

    final response = receipt != null
        ? await _network.postMultipartRequest(
            ApiEndpoints.sellerSubscriptionPay,
            data,
            {'receipt': receipt},
            token: token,
          )
        : await _network.postRequest(
            ApiEndpoints.sellerSubscriptionPay,
            data,
            token: token,
          );

    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Payment could not be submitted.');
    }

    final payData = response['data'] is Map
        ? Map<String, dynamic>.from(response['data'])
        : <String, dynamic>{};
    return SellerSubscriptionPayment.fromJson(payData);
  }
}
