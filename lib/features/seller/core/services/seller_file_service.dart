import 'dart:io';

import 'package:atompro/core/auth/seller_session_manager.dart';
import 'package:atompro/core/network/api_endpoints.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SellerFileService {
  SellerFileService._();

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Accept': '*/*'},
    ),
  );

  static Future<String> downloadAuthenticatedFile({
    required String endpoint,
    required String fileName,
  }) async {
    final token = await SellerSessionManager.getToken();
    final directory = await getTemporaryDirectory();
    final target = File('${directory.path}${Platform.pathSeparator}$fileName');

    final response = await _dio.get<List<int>>(
      endpoint,
      options: Options(
        responseType: ResponseType.bytes,
        headers: {'Authorization': 'Bearer ${token ?? ''}'},
      ),
    );

    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) {
      throw Exception('Downloaded file is empty.');
    }

    await target.writeAsBytes(bytes, flush: true);
    return target.path;
  }

  static Future<void> openLocalFile(String path) async {
    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done) {
      throw Exception(result.message);
    }
  }

  static Future<void> openExternalUrl(String url) async {
    final uri = Uri.parse(url);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) throw Exception('Unable to open link.');
  }
}
