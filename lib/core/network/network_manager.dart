import 'dart:io';

import 'package:atompro/core/network/api_endpoints.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class NetworkManager {
  final Dio _dio;

  NetworkManager._(this._dio);

  static NetworkManager create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 30),
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

      // Create FormData for multipart request
      final formData = FormData.fromMap(data);

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

      // Update content type for multipart
      final response = await _dio.post(
        endpoint,
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

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

      // Create FormData for multipart request
      final formData = FormData.fromMap(data);

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

      // Update content type for multipart
      final response = await _dio.put(
        endpoint,
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

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
      return response.data;
    } else {
      throw Exception(response.data['message'] ?? 'Something went wrong');
    }
  }

  dynamic _handleError(dynamic error) {
    if (error is DioException) {
      if (error.response != null) {
        throw Exception(error.response!.data['message'] ?? 'Error occurred');
      } else {
        throw Exception("Network Error: ${error.message}");
      }
    } else {
      throw Exception("Unexpected Error: $error");
    }
  }
}
