import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Memory-friendly caching for `autoDispose` providers.
///
/// An autoDispose provider frees its data as soon as no screen watches it.
/// `cacheFor` keeps it for [duration] after the last listener leaves, so
/// switching tabs or going back does not refetch, yet data a user has moved
/// away from is released instead of living for the whole session.
extension AtomCacheRef on Ref {
  void cacheFor(Duration duration) {
    final link = keepAlive();
    Timer? timer;
    onCancel(() => timer = Timer(duration, link.close));
    onResume(() => timer?.cancel());
    onDispose(() => timer?.cancel());
  }
}

/// How long each kind of data stays in memory after its screen closes.
abstract final class AtomCacheTime {
  /// Home rows and catalogue lists: admins change them rarely.
  static const catalogue = Duration(minutes: 5);

  /// One category's or brand's products.
  static const list = Duration(minutes: 2);
}
