import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/atom_api.dart';
import '../data/atom_models.dart';
import '../data/atom_product_detail.dart';
import 'atom_cache.dart';

/// Public settings (contact, store links, plan rules). Small and used on many
/// screens, so it lives for the whole session.
final appConfigProvider = FutureProvider<AppConfig>((ref) => ref.watch(atomCatalogueApiProvider).config());

/// Home rows, admin-driven (admin v2 → App setup). Each row is its own
/// provider so one failing section shows its own retry and the rest render.
///
/// The slider and categories on screen are the design's fixed content for
/// now (lib/data/atom_design_content.dart, owner 2026-10-28); these two
/// providers stay for when they go back to admin control.
final homeSlidesProvider = FutureProvider.autoDispose<List<HomeSlide>>((ref) {
  ref.cacheFor(AtomCacheTime.catalogue);
  return ref.watch(atomCatalogueApiProvider).slides();
});

final homeCategoriesProvider = FutureProvider.autoDispose<List<CatalogueItem>>((ref) {
  ref.cacheFor(AtomCacheTime.catalogue);
  return ref.watch(atomCatalogueApiProvider).categories();
});

final homeBrandsProvider = FutureProvider.autoDispose<List<CatalogueItem>>((ref) {
  ref.cacheFor(AtomCacheTime.catalogue);
  return ref.watch(atomCatalogueApiProvider).brands();
});

/// "Hot right now": featured products shown on app home.
final featuredProductsProvider = FutureProvider.autoDispose<List<ProductCard>>((ref) {
  ref.cacheFor(AtomCacheTime.catalogue);
  return ref.watch(atomCatalogueApiProvider).products(AtomEndpoints.featured);
});

/// "Top picks": app-home products in the admin's order.
final topPicksProvider = FutureProvider.autoDispose<List<ProductCard>>((ref) {
  ref.cacheFor(AtomCacheTime.catalogue);
  return ref.watch(atomCatalogueApiProvider).products(AtomEndpoints.topPicks);
});

final allCategoriesProvider = FutureProvider.autoDispose<List<CatalogueItem>>((ref) {
  ref.cacheFor(AtomCacheTime.catalogue);
  return ref.watch(atomCatalogueApiProvider).categories(all: true);
});

final allBrandsProvider = FutureProvider.autoDispose<List<CatalogueItem>>((ref) {
  ref.cacheFor(AtomCacheTime.catalogue);
  return ref.watch(atomCatalogueApiProvider).brands(all: true);
});

/// Products of one category or brand. A family keyed by id, auto-disposed so
/// only recently viewed lists stay in memory.
final categoryProductsProvider = FutureProvider.autoDispose.family<List<ProductCard>, int>((ref, id) {
  ref.cacheFor(AtomCacheTime.list);
  return ref.watch(atomCatalogueApiProvider).products(AtomEndpoints.categoryProducts(id));
});

final brandProductsProvider = FutureProvider.autoDispose.family<List<ProductCard>, int>((ref, id) {
  ref.cacheFor(AtomCacheTime.list);
  return ref.watch(atomCatalogueApiProvider).products(AtomEndpoints.brandProducts(id));
});

/// Product search by name, brand or category (GET api/products?q=). Kept
/// briefly so going back to the results does not refetch.
final productSearchProvider = FutureProvider.autoDispose.family<List<ProductCard>, String>((ref, query) {
  ref.cacheFor(AtomCacheTime.list);
  return ref.watch(atomCatalogueApiProvider).products(AtomEndpoints.search(query));
});

/// One product page. Kept briefly after the page closes so going back and
/// forth between a list and a product does not refetch.
final productDetailProvider = FutureProvider.autoDispose.family<ProductDetail, int>((ref, id) {
  ref.cacheFor(AtomCacheTime.list);
  return ref.watch(atomCatalogueApiProvider).productDetail(id);
});

/// Pull-to-refresh for the whole home screen.
Future<void> refreshHome(WidgetRef ref) async {
  ref
    ..invalidate(homeBrandsProvider)
    ..invalidate(featuredProductsProvider)
    ..invalidate(topPicksProvider);
  await ref.read(topPicksProvider.future).catchError((_) => const <ProductCard>[]);
}
