import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/atom_order.dart';
import '../design/atom_text.dart';
import '../state/atom_order_providers.dart';
import 'atom_select_field.dart';

/// City and area pickers side by side (stacked with large text); the area
/// list follows the city. Both open a searchable list. Used by the order
/// form, the custom order and make an offer. Lists come from GET api/cities
/// and api/areas/{city}.
class AtomCityAreaFields extends ConsumerWidget {
  const AtomCityAreaFields({
    super.key,
    required this.cityId,
    required this.areaId,
    required this.onCity,
    required this.onArea,
    this.areaRequired = true,
  });

  final int? cityId;
  final int? areaId;

  /// Changing the city should clear the area (the caller owns both).
  final ValueChanged<int?> onCity;
  final ValueChanged<int?> onArea;
  final bool areaRequired;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cities = ref.watch(citiesProvider);
    final city = cityId;
    final areas = city == null ? const AsyncValue<List<AtomPlace>>.data([]) : ref.watch(areasProvider(city));

    Widget field(String label, Widget child) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text(label, style: AtomText.label), const SizedBox(height: 6), child],
        );

    AtomPlace? find(AsyncValue<List<AtomPlace>> value, int? id) => (value.value ?? const <AtomPlace>[]).where((p) => p.id == id).firstOrNull;

    final cityField = field(
      'City',
      AtomSelectField<AtomPlace>(
        title: 'Choose your city',
        searchHint: 'Search cities',
        hint: 'Select city',
        options: cities.value ?? const [],
        label: (p) => p.title,
        selected: find(cities, cityId),
        onChanged: (p) => onCity(p.id),
        missing: 'Select your city.',
        loading: cities.isLoading,
        failed: cities.hasError,
        onRetry: () => ref.invalidate(citiesProvider),
      ),
    );
    final areaField = field(
      'Area',
      AtomSelectField<AtomPlace>(
        title: 'Choose your area',
        searchHint: 'Search areas',
        hint: city == null ? 'Select city first' : 'Select area',
        options: areas.value ?? const [],
        label: (p) => p.title,
        selected: find(areas, areaId),
        onChanged: (p) => onArea(p.id),
        missing: areaRequired ? 'Select your area.' : null,
        enabled: city != null,
        loading: areas.isLoading,
        failed: areas.hasError,
        onRetry: () {
          if (city != null) ref.invalidate(areasProvider(city));
        },
      ),
    );

    // Two columns where they fit; stacked when large text needs the room.
    if (MediaQuery.textScalerOf(context).scale(1) > 1.15) {
      return Column(children: [cityField, const SizedBox(height: 14), areaField]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Expanded(child: cityField), const SizedBox(width: 10), Expanded(child: areaField)],
    );
  }
}
