import 'dart:io';
import 'package:atompro/core/network/network_manager.dart';
import 'package:atompro/core/network/network_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'supplier_repo.g.dart';

class SupplierRepo {
  final NetworkManager network;
  SupplierRepo(this.network);

  /// Fetches product categories list.
  Future<Map<String, dynamic>> getCategories() async {
    return await network.getRequest('categories');
  }

  /// Submits supplier registration as multipart (text fields + 3 image files).
  Future<Map<String, dynamic>> submit({
    required Map<String, dynamic> fields,
    required File locationPhoto,
    required File cnicFront,
    required File cnicBack,
  }) async {
    return await network.postMultipartRequest('supplier/register', fields, {
      'business_location_photo': locationPhoto,
      'cnic_front': cnicFront,
      'cnic_back': cnicBack,
    });
  }
}

@riverpod
SupplierRepo supplierRepo(Ref ref) {
  final network = ref.read(networkManagerProvider);
  return SupplierRepo(network);
}
