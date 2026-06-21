import 'dart:io';

import 'package:atompro/core/network/api_endpoints.dart';
import 'package:atompro/core/seller_plan_upgrade_exception.dart';
import 'package:atompro/core/seller_subscription_gate.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class NetworkManager {
  final Dio _dio;

  NetworkManager._(this._dio);

  static NetworkManager create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
      ),
    );
    return NetworkManager._(dio);
  }

  Future<dynamic> getRequest(String endpoint, {String? token}) async {
    try {
      _updateAuthorizationHeader(token);
      final response = await _dio.get(endpoint);
      return _processResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<dynamic> postRequest(
    String endpoint,
    Map<String, dynamic> data, {
    String? token,
  }) async {
    try {
      _updateAuthorizationHeader(token);
      final response = await _dio.post(endpoint, data: data);
      return _processResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
      return _handleError(e);
    }
  }

  Future<dynamic> postMultipartRequest(
    String endpoint,
    Map<String, dynamic> data,
    Map<String, File> files, {
    String? token,
  }) async {
    try {
      _updateAuthorizationHeader(token);

      // Build FormData manually so List<String> values (e.g. detail_titles[])
      // are sent as repeated fields instead of relying on fromMap inference.
      final formData = FormData();
      for (final entry in data.entries) {
        final value = entry.value;
        if (value is List) {
          for (final item in value) {
            formData.fields.add(MapEntry(entry.key, item.toString()));
          }
        } else if (value != null) {
          formData.fields.add(MapEntry(entry.key, value.toString()));
        }
      }

      // Add files to FormData
      for (final entry in files.entries) {
        final file = entry.value;
        final fieldName = entry.key;

        formData.files.add(
          MapEntry(
            fieldName,
            await MultipartFile.fromFile(
              file.path,
              filename: file.path.split('/').last,
            ),
          ),
        );
      }

      final response = await _dio.post(endpoint, data: formData);

      return _processResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
      return _handleError(e);
    }
  }

  // Also add a method for PUT multipart requests (useful for updating user with image)
  Future<dynamic> putMultipartRequest(
    String endpoint,
    Map<String, dynamic> data,
    Map<String, File> files, {
    String? token,
  }) async {
    try {
      _updateAuthorizationHeader(token);

      final formData = FormData();
      for (final entry in data.entries) {
        final value = entry.value;
        if (value is List) {
          for (final item in value) {
            formData.fields.add(MapEntry(entry.key, item.toString()));
          }
        } else if (value != null) {
          formData.fields.add(MapEntry(entry.key, value.toString()));
        }
      }

      // Add files to FormData
      for (final entry in files.entries) {
        final file = entry.value;
        final fieldName = entry.key;

        formData.files.add(
          MapEntry(
            fieldName,
            await MultipartFile.fromFile(
              file.path,
              filename: file.path.split('/').last,
            ),
          ),
        );
      }

      final response = await _dio.put(endpoint, data: formData);

      return _processResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
      return _handleError(e);
    }
  }

  Future<dynamic> patchRequest(
    String endpoint,
    Map<String, dynamic> data, {
    String? token,
  }) async {
    try {
      _updateAuthorizationHeader(token);
      final response = await _dio.patch(endpoint, data: data);
      return _processResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<dynamic> putRequest(
    String endpoint,
    Map<String, dynamic> data, {
    String? token,
  }) async {
    try {
      _updateAuthorizationHeader(token);
      final response = await _dio.put(endpoint, data: data);
      return _processResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // Add delete request method
  Future<dynamic> deleteRequest(
    String endpoint, {
    String? token,
    Map<String, dynamic>? data,
  }) async {
    try {
      _updateAuthorizationHeader(token);
      final response = await _dio.delete(endpoint, data: data);
      return _processResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  void _updateAuthorizationHeader([String? token]) {
    _dio.options.headers['Authorization'] = 'Bearer ${token ?? ''}';
  }

  dynamic _processResponse(Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data;
      if (data is Map) {
        final path = response.requestOptions.path;
        final isSubscriptionEndpoint = path.contains('seller-app/subscription');

        if (data['requires_subscription'] == true) {
          if (!isSubscriptionEndpoint) {
            SellerSubscriptionGate.trigger(false);
          }
          throw Exception(data['message'] ?? 'No active subscription.');
        }
        final msg = data['message'];
        if (data['success'] == false &&
            msg is String &&
            msg.contains('pending monthly payment')) {
          if (!isSubscriptionEndpoint) {
            SellerSubscriptionGate.trigger(true);
          }
          throw Exception(msg);
        }
        if (data['requires_upgrade'] == true || data['requires_plan'] is String) {
          throw SellerPlanUpgradeException(
            message: msg is String && msg.isNotEmpty
                ? msg
                : 'Your current plan does not include access to this feature.',
            messageUr: data['message_ur']?.toString() ?? '',
            phone: data['phone']?.toString() ?? '+923302277522',
          );
        }
      }
      return data;
    } else {
      throw Exception(response.data['message'] ?? 'Something went wrong');
    }
  }

  dynamic _handleError(dynamic error) {
    if (error is SellerPlanUpgradeException) throw error;
    if (error is DioException) {
      if (error.response != null) {
        final data = error.response!.data;
        if (data is Map &&
            (data['requires_upgrade'] == true ||
                data['requires_plan'] is String)) {
          final msg = data['message'];
          throw SellerPlanUpgradeException(
            message: msg is String && msg.isNotEmpty
                ? msg
                : 'Your current plan does not include access to this feature.',
            messageUr: data['message_ur']?.toString() ?? '',
            phone: data['phone']?.toString() ?? '+923302277522',
          );
        }
        throw Exception(data['message'] ?? 'Error occurred');
      } else {
        throw Exception("Network Error: ${error.message}");
      }
    } else {
      throw Exception("Unexpected Error: $error");
    }
  }
}
