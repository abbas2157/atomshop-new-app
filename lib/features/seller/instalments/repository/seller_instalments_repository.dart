import 'dart:io';

import 'package:atompro/core/auth/seller_session_manager.dart';
import 'package:atompro/core/network/api_endpoints.dart';
import 'package:atompro/core/network/network_manager.dart';
import 'package:atompro/core/network/network_provider.dart';
import 'package:atompro/features/seller/core/services/seller_file_service.dart';
import 'package:atompro/features/seller/instalments/model/seller_instalments_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sellerInstalmentsRepositoryProvider =
    Provider<SellerInstalmentsRepository>((ref) {
      return SellerInstalmentsRepository(ref.watch(networkManagerProvider));
    });

class SellerInstalmentsRepository {
  final NetworkManager _network;

  SellerInstalmentsRepository(this._network);

  Future<SellerInstalmentsListResponse> getInstalmentsList(
    SellerInstalmentsQuery query,
  ) async {
    final queryString = Uri(queryParameters: query.toQueryParameters()).query;
    final endpoint = queryString.isEmpty
        ? ApiEndpoints.sellerInstalments
        : '${ApiEndpoints.sellerInstalments}?$queryString';
    final response = await _get(endpoint);
    return SellerInstalmentsListResponse.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  Future<SellerInstalmentOrderDetail> getOrderDetail(int orderId) async {
    final response = await _get(
      ApiEndpoints.sellerInstalmentOrderDetail(orderId),
    );
    return SellerInstalmentOrderDetail.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  Future<SellerInstalmentInvoiceData> getInvoiceData(int instalmentId) async {
    final response = await _get(
      ApiEndpoints.sellerInstalmentInvoiceData(instalmentId),
    );
    return SellerInstalmentInvoiceData.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  Future<void> payInstalment({
    required int orderId,
    required String instalmentPrice,
    required String paymentMethod,
    String? recoveryMemberId,
    File? receipt,
  }) async {
    final token = await SellerSessionManager.getToken();
    final files = <String, File>{};
    if (receipt != null) files['instalment_pictrue'] = receipt;

    final response = await _network.postMultipartRequest(
      ApiEndpoints.sellerPayInstalment,
      {
        'order_id': orderId.toString(),
        'instalment_price': instalmentPrice,
        'payment_method': paymentMethod,
        if (recoveryMemberId != null && recoveryMemberId.isNotEmpty)
          'recovery_member_id': recoveryMemberId,
      },
      files,
      token: token,
    );

    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to pay instalment.');
    }
  }

  Future<String> getTopupPdfUrl() async {
    final response = await _get(ApiEndpoints.sellerInstalmentsTopupPdf);
    return _urlFromResponse(response, 'Top-up PDF is unavailable.');
  }

  Future<String> getInvoiceUrl(int instalmentId) async {
    final response = await _get(
      ApiEndpoints.sellerInstalmentInvoice(instalmentId),
    );
    return _urlFromResponse(response, 'Invoice is unavailable.');
  }

  Future<String> getExportUrl({String? status}) async {
    return SellerFileService.downloadAuthenticatedFile(
      endpoint: ApiEndpoints.sellerInstalmentsExport(status: status),
      fileName:
          'atomshop_instalments_${(status ?? 'all').toLowerCase()}_export.xlsx',
    );
  }

  Future<dynamic> _get(String endpoint) async {
    final token = await SellerSessionManager.getToken();
    final response = await _network.getRequest(endpoint, token: token);
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Request failed.');
    }
    return response;
  }

  String _urlFromResponse(dynamic response, String fallback) {
    final data = response['data'] is Map
        ? Map<String, dynamic>.from(response['data'])
        : <String, dynamic>{};
    final url = data['url']?.toString().trim();
    if (url == null || url.isEmpty) throw Exception(fallback);
    return url;
  }
}
