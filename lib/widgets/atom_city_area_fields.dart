import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/atom_order.dart';
import '../design/atom_text.dart';
import '../design/atom_tokens.dart';
import '../state/atom_order_providers.dart';

/// City and area pickers side by side (stacked with large text); the area
/// list follows the city. Used by the order form, the custom order and
/// make an offer. Lists come from GET api/cities and api/areas/{city}.
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

    Widget dropdown({
      required AsyncValue<List<AtomPlace>> value,
      required int? selected,
      required String hint,
      required String? missing,
      required ValueChanged<int?> onChanged,
      required VoidCallback onRetry,
      bool enabled = true,
    }) {
      final items = value.value ?? const <AtomPlace>[];
      final known = items.any((p) => p.id == selected) ? selected : null;
      return DropdownButtonFormField<int>(
        key: ValueKey('$hint-${items.length}-$known'),
        initialValue: known,
        isExpanded: true,
        items: [for (final p in items) DropdownMenuItem(value: p.id, child: Text(p.title, overflow: TextOverflow.ellipsis))],
        onChanged: enabled && items.isNotEmpty ? onChanged : null,
        validator: (v) => v == null ? missing : null,
        style: AtomText.body.copyWith(fontSize: 15, color: AtomColors.ink),
        borderRadius: BorderRadius.circular(AtomRadius.input),
        decoration: InputDecoration(
          hintText: value.isLoading ? 'Loading…' : (value.hasError ? 'Could not load' : hint),
          suffixIcon: value.hasError ? IconButton(tooltip: 'Try again', icon: const Icon(Icons.refresh_rounded), onPressed: onRetry) : null,
        ),
      );
    }

    final cityField = field(
      'City',
      dropdown(
        value: cities,
        selected: cityId,
        hint: 'Select city',
        missing: 'Select your city.',
        onChanged: onCity,
        onRetry: () => ref.invalidate(citiesProvider),
      ),
    );
    final areaField = field(
      'Area',
      dropdown(
        value: areas,
        selected: areaId,
        hint: city == null ? 'Select city first' : 'Select area',
        missing: areaRequired ? 'Select your area.' : null,
        enabled: city != null,
        onChanged: onArea,
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
