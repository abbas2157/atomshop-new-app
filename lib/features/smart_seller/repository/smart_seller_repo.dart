import 'package:atompro/core/network/network_manager.dart';
import 'package:atompro/core/network/network_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'smart_seller_repo.g.dart';

class SmartSellerRepo {
  final NetworkManager network;
  SmartSellerRepo(this.network);

  Future<Map<String, dynamic>> submit(Map<String, dynamic> data) async {
    return await network.postRequest('seller/register', data);
  }
}

@riverpod
SmartSellerRepo smartSellerRepo(Ref ref) {
  final network = ref.read(networkManagerProvider);
  return SmartSellerRepo(network);
}
