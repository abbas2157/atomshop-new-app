import 'package:atompro/core/network/api_endpoints.dart';
import 'package:atompro/core/network/network_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'reference_cache_models.dart';
import 'reference_cache_service.dart';

/// Single source of truth for cities, areas, categories and brands.
///
/// How it works on every app restart:
///  1. [build] fires [_loadAndSync] as a microtask and returns [ReferenceData.empty].
///  2. [_loadAndSync] reads the JSON file from disk — state updates within
///     milliseconds (instant for the user, fully offline-safe).
///  3. A background API sync runs immediately after. On success the state
///     updates again with fresh data and the file is overwritten.
///  4. On any network failure the cached state stays in place silently.
///
/// Usage in any screen:
/// ```dart
/// final data = ref.watch(referenceDataProvider);
/// final cities  = data.cities;          // List<RefItem>
/// final areas   = data.areasForCity(id); // List<RefArea>
/// final cats    = data.categories;      // List<RefItem>
/// final brands  = data.brands;          // List<RefItem>
/// ```
final referenceDataProvider =
    NotifierProvider<ReferenceDataNotifier, ReferenceData>(
      ReferenceDataNotifier.new,
    );

class ReferenceDataNotifier extends Notifier<ReferenceData> {
  @override
  ReferenceData build() {
    Future(_loadAndSync); // fire-and-forget — same pattern as the rest of the app
    return const ReferenceData.empty();
  }

  Future<void> _loadAndSync() async {
    // ── Step 1: serve persisted cache immediately ─────────────────────────
    final cached = await ref.read(referenceCacheServiceProvider).load();
    if (cached != null) state = cached;

    // ── Step 2: silent background refresh ────────────────────────────────
    try {
      final network = ref.read(networkManagerProvider);

      // Cities, categories and brands are public endpoints — no auth token.
      final [citiesRes, categoriesRes, brandsRes] = await Future.wait([
        network.getRequest(ApiEndpoints.cities),
        network.getRequest(ApiEndpoints.categories),
        network.getRequest(ApiEndpoints.brands),
      ]);

      final cities = _items(citiesRes['data']);
      final categories = _items(categoriesRes['data']);
      final brands = _items(brandsRes['data']);

      // One request per city, all in parallel.
      final areaResponses = await Future.wait(
        cities.map((c) => network.getRequest(ApiEndpoints.areasByCity(c.id))),
      );

      final areas = <RefArea>[];
      for (var i = 0; i < cities.length; i++) {
        final raw = areaResponses[i]['data'];
        if (raw is List) {
          areas.addAll(
            raw.whereType<Map>().map(
              (e) => RefArea.fromJson(
                Map<String, dynamic>.from(e),
                fallbackCityId: cities[i].id, // injected if API omits city_id
              ),
            ),
          );
        }
      }

      final fresh = ReferenceData(
        cities: cities,
        areas: areas,
        categories: categories,
        brands: brands,
      );

      state = fresh;
      await ref.read(referenceCacheServiceProvider).save(fresh);
    } catch (_) {
      // Network or parse failure — cached state remains, no error shown.
    }
  }

  List<RefItem> _items(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => RefItem.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }
}
