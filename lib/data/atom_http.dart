import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/session_manager.dart';
import '../core/network/api_endpoints.dart';
import '../core/network/reachability.dart';

/// An API refusal or failure with a sentence the customer can act on.
///
/// [statusCode] is the HTTP status (0 when the server was not reached);
/// [data] is the envelope's `data` (field errors, or extra details such as
/// `needs_verification`).
class AtomApiException implements Exception {
  const AtomApiException(this.message, {this.statusCode = 0, this.data = const {}});

  final String message;
  final int statusCode;
  final Map<String, dynamic> data;

  bool get isOffline => statusCode == 0;
  bool get isUnauthorised => statusCode == 401;
  bool get isRateLimited => statusCode == 429;

  /// First message for [field] from Laravel's `{field: [messages]}`.
  String? fieldError(String field) {
    final v = data[field];
    if (v is List && v.isNotEmpty) return v.first.toString();
    if (v is String && v.isNotEmpty) return v;
    return null;
  }

  @override
  String toString() => message;
}

/// Client for the app's `api/app/*` endpoints and the older customer
/// endpoints, reading the `{success, message, data}` envelope.
///
/// Unlike `NetworkManager` it keeps the envelope on errors (status code and
/// `data`), sends the signed-in customer's token automatically, and turns
/// `success: false` answered with HTTP 200 (older endpoints) into an error.
class AtomHttp {
  AtomHttp({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: ApiEndpoints.baseUrl,
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 40),
              headers: const {'Accept': 'application/json'},
              // Read every answer; the envelope decides.
              validateStatus: (s) => s != null && s < 600,
            ));

  final Dio _dio;

  /// Called on HTTP 401 for a request that carried a token (the session was
  /// revoked elsewhere). Set by the session notifier.
  static void Function()? onUnauthorised;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) => _send(() async => _dio.get(path, queryParameters: query, options: await _options()));

  Future<dynamic> post(String path, [Map<String, dynamic>? body]) =>
      _send(() async => _dio.post(path, data: body ?? const {}, options: await _options()));

  /// Multipart post; [files] maps field name → local file path. A field
  /// ending in `[]` may carry several files.
  Future<dynamic> postFiles(String path, Map<String, dynamic> fields, Map<String, List<String>> files) => _send(() async {
        final form = FormData.fromMap({
          for (final e in fields.entries)
            if (e.value != null) e.key: e.value.toString(),
        });
        for (final f in files.entries) {
          for (final path in f.value) {
            form.files.add(MapEntry(f.key, await MultipartFile.fromFile(path)));
          }
        }
        return _dio.post(path, data: form, options: await _options());
      });

  /// Raw bytes (receipt PDF).
  Future<List<int>> bytes(String path) async {
    try {
      final res = await _dio.get<List<int>>(path, options: (await _options()).copyWith(responseType: ResponseType.bytes));
      if ((res.statusCode ?? 500) >= 400) throw AtomApiException('Could not download the file.', statusCode: res.statusCode ?? 500);
      return res.data ?? const [];
    } on DioException {
      throw const AtomApiException('Check your internet connection and try again.');
    }
  }

  Future<Options> _options() async {
    final token = await SessionManager.getToken();
    return Options(headers: {if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token'});
  }

  Future<dynamic> _send(Future<Response<dynamic>> Function() request) async {
    final Response<dynamic> res;
    try {
      res = await request();
    } on DioException catch (e) {
      atomServerReachable.value = false;
      final timedOut = e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout;
      throw AtomApiException(timedOut ? 'The server is taking too long. Please try again.' : 'Check your internet connection and try again.');
    }

    atomServerReachable.value = true;
    final status = res.statusCode ?? 500;
    final body = res.data;
    final envelope = body is Map ? Map<String, dynamic>.from(body) : const <String, dynamic>{};
    final ok = status < 400 && envelope['success'] != false;
    if (ok) return envelope.containsKey('data') ? envelope['data'] : body;

    if (status == 401 && res.requestOptions.headers.containsKey('Authorization')) onUnauthorised?.call();
    final data = envelope['data'];
    var message = envelope['message'];
    // Laravel's "The route … could not be found." means the server doesn't
    // have this feature yet; never show framework text to customers.
    if (status == 404 && message is String && message.startsWith('The route ')) {
      message = 'This isn’t available yet. Please try again later.';
    }
    throw AtomApiException(
      message is String && message.isNotEmpty && message != 'Validation Error.' ? message : _fallback(status, data),
      statusCode: status,
      data: data is Map ? Map<String, dynamic>.from(data) : const {},
    );
  }

  static String _fallback(int status, Object? data) {
    if (data is Map) {
      for (final v in data.values) {
        if (v is List && v.isNotEmpty) return v.first.toString();
      }
    }
    return switch (status) {
      401 => 'Please sign in again.',
      403 => 'You are not allowed to do that.',
      404 => 'We could not find that.',
      429 => 'Too many tries. Please wait a little and try again.',
      _ => 'Something went wrong. Please try again.',
    };
  }
}

final atomHttpProvider = Provider<AtomHttp>((ref) => AtomHttp());

/// The customer-facing sentence for any error the data layer throws.
String atomMessage(Object error) {
  if (error is AtomApiException) return error.message;
  final text = error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
  if (text.isEmpty || text.startsWith('Network Error') || text.startsWith('Unexpected Error')) {
    return 'Check your internet connection and try again.';
  }
  return text;
}

/// Random id for one submission (orders), so the server can recognise a
/// repeat of the same request after a timeout or a double tap.
String atomRequestId() {
  final r = Random.secure();
  return List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
}
