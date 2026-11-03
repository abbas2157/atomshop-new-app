import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/atom_brands.dart';
import 'atom_cache.dart';

/// Every brand with a Brand Partner login, most products first (Home row and
/// the Brand partners screen).
final brandPartnersProvider = FutureProvider.autoDispose<List<BrandPartner>>((ref) {
  ref.cacheFor(AtomCacheTime.catalogue);
  return ref.watch(atomBrandsApiProvider).partners();
});
