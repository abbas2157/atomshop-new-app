import 'dart:convert';

/// Lightweight {id, title} pair used for cities, categories and brands.
class RefItem {
  final int id;
  final String title;

  const RefItem({required this.id, required this.title});

  factory RefItem.fromJson(Map<String, dynamic> json) => RefItem(
    id: _asInt(json['id']),
    title: _text(
      json['title'] ?? json['name'] ?? json['category'] ?? json['brand'],
    ),
  );

  Map<String, dynamic> toJson() => {'id': id, 'title': title};

  @override
  String toString() => title;
}

/// Area with a parent city reference.
class RefArea {
  final int id;
  final String title;
  final int cityId;

  const RefArea({required this.id, required this.title, required this.cityId});

  factory RefArea.fromJson(Map<String, dynamic> json, {int? fallbackCityId}) =>
      RefArea(
        id: _asInt(json['id']),
        title: _text(json['title'] ?? json['name']),
        cityId: json['city_id'] != null
            ? _asInt(json['city_id'])
            : (fallbackCityId ?? 0),
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'title': title, 'city_id': cityId};

  @override
  String toString() => title;
}

/// All four reference datasets in one object.
/// Persisted to disk as a single JSON file; served from memory at runtime.
class ReferenceData {
  final List<RefItem> cities;
  final List<RefArea> areas;
  final List<RefItem> categories;
  final List<RefItem> brands;

  const ReferenceData({
    required this.cities,
    required this.areas,
    required this.categories,
    required this.brands,
  });

  const ReferenceData.empty()
      : cities = const [],
        areas = const [],
        categories = const [],
        brands = const [];

  bool get hasData => cities.isNotEmpty;

  /// All areas that belong to [cityId], ready for a dropdown.
  List<RefArea> areasForCity(int cityId) =>
      areas.where((a) => a.cityId == cityId).toList(growable: false);

  // ── Serialisation ──────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'cities': cities.map((e) => e.toJson()).toList(),
    'areas': areas.map((e) => e.toJson()).toList(),
    'categories': categories.map((e) => e.toJson()).toList(),
    'brands': brands.map((e) => e.toJson()).toList(),
  };

  factory ReferenceData.fromJson(Map<String, dynamic> json) => ReferenceData(
    cities: _parseList(json['cities'], RefItem.fromJson),
    areas: _parseList(json['areas'], (j) => RefArea.fromJson(j)),
    categories: _parseList(json['categories'], RefItem.fromJson),
    brands: _parseList(json['brands'], RefItem.fromJson),
  );

  String toJsonString() => jsonEncode(toJson());

  static ReferenceData? tryFromJsonString(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return ReferenceData.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return null;
    }
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

List<T> _parseList<T>(
  dynamic raw,
  T Function(Map<String, dynamic>) fromJson,
) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => fromJson(Map<String, dynamic>.from(e)))
      .toList(growable: false);
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

String _text(dynamic value, {String fallback = ''}) {
  final s = value?.toString().trim();
  if (s == null || s.isEmpty || s == 'null') return fallback;
  return s;
}
