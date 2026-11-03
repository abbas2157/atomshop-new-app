import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/atom_sellers.dart';
import 'atom_cache.dart';
import 'atom_delivery_area.dart';

/// Home's "Top rated sellers" strip and the top of the Sellers screen.
final topRatedSellersProvider = FutureProvider.autoDispose<List<Seller>>((ref) {
  ref.cacheFor(AtomCacheTime.catalogue);
  return ref.watch(atomSellersApiProvider).topRated();
});

/// A seller's profile and products for one set of filters.
final sellerProfileProvider = FutureProvider.autoDispose.family<SellerProfile, SellerProfileQuery>((ref, query) {
  ref.cacheFor(AtomCacheTime.list);
  return ref.watch(atomSellersApiProvider).profile(query);
});

/// One seller item, for the buyer's area ([areaId] may be null).
final sellerItemProvider = FutureProvider.autoDispose.family<SellerItemPage, (String, int, int?)>((ref, key) {
  ref.cacheFor(AtomCacheTime.list);
  final (seller, item, areaId) = key;
  return ref.watch(atomSellersApiProvider).item(seller, item, areaId: areaId);
});

/// Sellers' stock in the buyer's saved area (Home's "From sellers in …" row
/// and the "In stock near you" badges). Empty without a saved area.
final sellersNearProvider = FutureProvider.autoDispose<SellersNear>((ref) async {
  ref.cacheFor(AtomCacheTime.catalogue);
  final areaId = (await ref.watch(deliveryAreaProvider.future))?.areaId;
  if (areaId == null) return SellersNear.empty;
  return ref.watch(atomSellersApiProvider).near(areaId);
});

/// Catalogue product ids a nearby seller has in stock; empty while loading,
/// on error, or without an area, so badges simply don't show.
final inStockNearProvider = Provider.autoDispose<Set<int>>((ref) => ref.watch(sellersNearProvider).value?.catalogueProductIds ?? const {});
