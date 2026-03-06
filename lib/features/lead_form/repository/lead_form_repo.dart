import 'dart:io';

import 'package:atompro/core/network/network_manager.dart';
import 'package:atompro/core/network/network_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'lead_form_repo.g.dart';

class LeadFormRepo {
  final NetworkManager network;
  LeadFormRepo(this.network);

  /// Submits the lead data to the leads/create endpoint.
  /// This expects a Map containing: full_name, contact_number, city_id, area_id, product_title, etc.
  Future<void> submitLead(
    Map<String, dynamic> data,
    Map<String, File> files,
  ) async {
    await network.postMultipartRequest("leads/create", data, files);
  }
}

@riverpod
LeadFormRepo leadFormRepo(Ref ref) {
  final network = ref.read(networkManagerProvider);
  return LeadFormRepo(network);
}
