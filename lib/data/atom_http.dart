import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/session_manager.dart';
import '../core/network/api_endpoints.dart';
import '../core/network/reachability.dart';
import 'atom_errors.dart';

export 'atom_errors.dart';

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

  /// First message for [field] from Laravel's `{field: [messages]}`, in
  /// customer words. Only lists count: older endpoints echo the request
  /// back as plain strings, which are not errors.
  String? fieldError(String field) {
    final v = data[field];
    if (v is List && v.isNotEmpty) return atomFriendlyMessage('Validation Error.', status: 422, data: {field: v});
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

  /// Like [get] and [post] but returns the whole envelope. Some older
  /// endpoints put their result in `message` and a sentence in `data`.
  Future<Map<String, dynamic>> getEnvelope(String path) async =>
      Map<String, dynamic>.from(await _send(() async => _dio.get(path, options: await _options()), raw: true) as Map);

  Future<Map<String, dynamic>> postEnvelope(String path, [Map<String, dynamic>? body]) async =>
      Map<String, dynamic>.from(await _send(() async => _dio.post(path, data: body ?? const {}, options: await _options()), raw: true) as Map);

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
      final status = res.statusCode ?? 500;
      if (status >= 400) throw AtomApiException('We could not download this file. Please try again.', statusCode: status);
      return res.data ?? const [];
    } on DioException catch (e) {
      throw AtomApiException(atomDioMessage(e));
    }
  }

  Future<Options> _options() async {
    final token = await SessionManager.getToken();
    return Options(headers: {if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token'});
  }

  Future<dynamic> _send(Future<Response<dynamic>> Function() request, {bool raw = false}) async {
    final Response<dynamic> res;
    try {
      res = await request();
    } on DioException catch (e) {
      atomServerReachable.value = false;
      throw AtomApiException(atomDioMessage(e));
    }

    atomServerReachable.value = true;
    final status = res.statusCode ?? 500;
    final body = res.data;
    final envelope = body is Map ? Map<String, dynamic>.from(body) : const <String, dynamic>{};
    final ok = status < 400 && envelope['success'] != false;
    if (ok) {
      if (raw) return envelope;
      return envelope.containsKey('data') ? envelope['data'] : body;
    }

    if (status == 401 && res.requestOptions.headers.containsKey('Authorization')) onUnauthorised?.call();
    final answer = envelope['data'];
    // Older endpoints echo the request (password included) back on errors;
    // never keep a password in memory longer than the request.
    final data = answer is Map
        ? <String, dynamic>{
            for (final e in answer.entries)
              if (!'${e.key}'.contains('password')) '${e.key}': e.value,
          }
        : const <String, dynamic>{};
    final message = envelope['message'];
    throw AtomApiException(
      atomFriendlyMessage(message is String ? message : null, status: status, data: data),
      statusCode: status,
      data: data,
    );
  }
}

/// A request that never got an answer: offline, too slow, or a certificate
/// or cancel problem, in customer words.
String atomDioMessage(DioException e) => switch (e.type) {
      DioExceptionType.connectionTimeout || DioExceptionType.sendTimeout || DioExceptionType.receiveTimeout => atomSlowMessage,
      DioExceptionType.badCertificate => 'We could not make a secure connection. Check the date and time on your phone, then try again.',
      DioExceptionType.cancel => 'That was cancelled. Please try again.',
      _ => atomStatusMessage(0),
    };

final atomHttpProvider = Provider<AtomHttp>((ref) => AtomHttp());

/// The customer-facing sentence for any error the data layer throws.
String atomMessage(Object error) {
  if (error is AtomApiException) return error.message;
  if (error is DioException) return atomDioMessage(error);
  final text = error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
  if (text.startsWith('Network Error')) return atomStatusMessage(0);
  return atomFriendlyMessage(text, status: 500);
}

/// Random id for one submission (orders), so the server can recognise a
/// repeat of the same request after a timeout or a double tap.
String atomRequestId() {
  final r = Random.secure();
  return List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
}
