import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/atom_sellers.dart';
import 'atom_cache.dart';

/// Home's "Top rated sellers" strip and the top of the Sellers screen.
final topRatedSellersProvider = FutureProvider.autoDispose<List<Seller>>((ref) {
  ref.cacheFor(AtomCacheTime.catalogue);
  return ref.watch(atomSellersApiProvider).topRated();
});
