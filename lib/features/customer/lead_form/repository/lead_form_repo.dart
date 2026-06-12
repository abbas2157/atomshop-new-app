import 'dart:io';

import 'package:atompro/core/auth/session_manager.dart';
import 'package:atompro/core/network/network_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:atompro/core/network/network_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'lead_form_repo.g.dart';

class LeadFormRepo {
  final NetworkManager network;
  LeadFormRepo(this.network);

  Future<void> submitLead(
    Map<String, dynamic> data,
    Map<String, File> files,
  ) async {
    final token = await SessionManager.getToken();
    debugPrint('=== LEAD SUBMIT ===');
    debugPrint('Token: $token');
    debugPrint('Data: $data');
    debugPrint('Files: ${files.keys.toList()}');
    final response = await network.postMultipartRequest(
      "leads/create",
      data,
      files,
      token: token,
    );
    debugPrint('Response: $response');
    debugPrint('===================');
    if (response is Map && response['success'] != true) {
      throw Exception(
        response['message']?.toString() ?? 'Failed to submit lead.',
      );
    }
  }
}

@riverpod
LeadFormRepo leadFormRepo(Ref ref) {
  final network = ref.read(networkManagerProvider);
  return LeadFormRepo(network);
}
