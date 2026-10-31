import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/network_manager.dart';
import '../core/network/network_provider.dart';
import 'atom_http.dart';
import 'atom_models.dart';
import 'atom_offline_store.dart';
import 'atom_product_detail.dart';

/// App v2 endpoints (server TRD: docs/trd/2026-10-28-customer-app-v2-api.md).
abstract final class AtomEndpoints {
  static const config = 'app/config';
  static const sliders = 'sliders';
  static const homeCategories = 'categories';
  static const allCategories = 'categories/all';
  static const homeBrands = 'brands';
  static const allBrands = 'brands/all';
  static const featured = 'products/feature';
  static const topPicks = 'products/toprated';
  static String categoryProducts(int id) => 'products/category/$id';
  static String brandProducts(int id) => 'products/brand/$id';
  static String productDetail(int id) => 'products/$id';
  static String search(String q) => 'products?q=${Uri.encodeQueryComponent(q)}';
  static const askAtomSuggestions = 'ask-atom/suggestions';
}

/// Thin typed layer over [NetworkManager] for the public catalogue. Each call
/// returns parsed models; errors propagate as exceptions so providers turn
/// them into `AsyncError` and screens show a retry.
class AtomCatalogueApi {
  const AtomCatalogueApi(this._network);

  final NetworkManager _network;

  Future<List<Map<String, dynamic>>> _list(String endpoint) async {
    final res = await _network.getRequest(endpoint);
    return atomList(res is Map ? res['data'] : null);
  }

  /// Saved on the phone each time it loads; the saved copy is used offline
  /// (plan months and the minimum advance for a custom order).
  Future<AppConfig> config() async {
    try {
      final res = await _network.getRequest(AtomEndpoints.config);
      final data = Map<String, dynamic>.from((res as Map)['data'] as Map);
      await AtomOfflineStore.write('config', data);
      return AppConfig.fromJson(data);
    } on AtomApiException catch (e) {
      final saved = e.isOffline ? await AtomOfflineStore.read('config') : null;
      if (saved is! Map) rethrow;
      return AppConfig.fromJson(Map<String, dynamic>.from(saved));
    }
  }

  Future<List<HomeSlide>> slides() async => (await _list(AtomEndpoints.sliders)).map(HomeSlide.fromJson).toList(growable: false);

  Future<List<CatalogueItem>> categories({bool all = false}) async =>
      (await _list(all ? AtomEndpoints.allCategories : AtomEndpoints.homeCategories)).map(CatalogueItem.fromJson).toList(growable: false);

  Future<List<CatalogueItem>> brands({bool all = false}) async =>
      (await _list(all ? AtomEndpoints.allBrands : AtomEndpoints.homeBrands)).map(CatalogueItem.fromJson).toList(growable: false);

  Future<List<ProductCard>> products(String endpoint) async => (await _list(endpoint)).map(ProductCard.fromJson).toList(growable: false);

  /// Throws [ProductNotFound] when the product is unpublished or gone.
  Future<ProductDetail> productDetail(int id) async {
    final res = await _network.getRequest(AtomEndpoints.productDetail(id));
    final data = res is Map ? res['data'] : null;
    if (data is! Map) throw ProductNotFound(id);
    return ProductDetail.fromJson(Map<String, dynamic>.from(data));
  }
}

final atomCatalogueApiProvider = Provider<AtomCatalogueApi>((ref) => AtomCatalogueApi(ref.watch(networkManagerProvider)));
