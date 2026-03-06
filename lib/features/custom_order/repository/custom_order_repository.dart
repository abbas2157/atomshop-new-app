import 'package:atompro/core/auth/session_manager.dart';
import 'package:atompro/core/network/network_manager.dart';
import 'package:atompro/core/network/network_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'custom_order_repository.g.dart';

@riverpod
CustomOrderRepository customOrderRepository(Ref ref) {
  final network = ref.watch(networkManagerProvider);
  return CustomOrderRepository(network);
}

class CustomOrderRepository {
  final NetworkManager _network;
  CustomOrderRepository(this._network);

  /// Submits the custom order data to the server
  Future<dynamic> submitOrder(Map<String, dynamic> data) async {
    return await _network.postRequest("custom-order-calculator/store", data);
  }

  /// Validates the supplier reference code
  Future<bool> validateRefCode(String code) async {
    try {
      final response = await _network.getRequest(
        "custom-order-calculator/reference-code?code=$code",
      );
      if (kDebugMode) {
        print(response);
      }
      return response['data']['success'] == true;
    } catch (_) {
      return false;
    }
  }

  /// get my orders
  Future<dynamic> getmyorder() async {
    final uuid = await SessionManager.getUserUuid();
    final token = await SessionManager.getToken();

    return await _network.postRequest("account/my-orders", {
      'uuid': uuid,
    }, token: token);
  }
}
