import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/atom_order.dart';
import '../design/atom_text.dart';
import '../design/atom_tokens.dart';
import '../state/atom_order_providers.dart';
import 'atom_text_field.dart';

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
    // Cities are a short list; a city can have hundreds of areas, so the
    // area opens a searchable sheet instead of a long dropdown.
    final areaField = field(
      'Area',
      _AreaPicker(
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

class _AreaPicker extends StatelessWidget {
  const _AreaPicker({
    required this.value,
    required this.selected,
    required this.hint,
    required this.missing,
    required this.enabled,
    required this.onChanged,
    required this.onRetry,
  });

  final AsyncValue<List<AtomPlace>> value;
  final int? selected;
  final String hint;
  final String? missing;
  final bool enabled;
  final ValueChanged<int?> onChanged;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final items = value.value ?? const <AtomPlace>[];
    final current = items.where((p) => p.id == selected).firstOrNull;
    return FormField<int>(
      key: ValueKey('area-${items.length}-${current?.id}'),
      initialValue: current?.id,
      validator: (v) => (current == null && missing != null) ? missing : null,
      builder: (state) => InkWell(
        borderRadius: BorderRadius.circular(AtomRadius.input),
        onTap: !enabled || items.isEmpty
            ? null
            : () async {
                final picked = await showModalBottomSheet<AtomPlace>(
                  context: context,
                  isScrollControlled: true,
                  useRootNavigator: true,
                  showDragHandle: true,
                  builder: (_) => _AreaSheet(areas: items, selected: selected),
                );
                if (picked != null) {
                  state.didChange(picked.id);
                  onChanged(picked.id);
                }
              },
        child: InputDecorator(
          isEmpty: current == null,
          decoration: InputDecoration(
            hintText: value.isLoading ? 'Loading…' : (value.hasError ? 'Could not load' : hint),
            errorText: state.errorText,
            enabled: enabled,
            suffixIcon: value.hasError
                ? IconButton(tooltip: 'Try again', icon: const Icon(Icons.refresh_rounded), onPressed: onRetry)
                : const Icon(Icons.arrow_drop_down_rounded),
          ),
          child: current == null
              ? null
              : Text(current.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AtomText.body.copyWith(fontSize: 15, color: AtomColors.ink)),
        ),
      ),
    );
  }
}

/// Bottom sheet: search box over the city's areas.
class _AreaSheet extends StatefulWidget {
  const _AreaSheet({required this.areas, required this.selected});

  final List<AtomPlace> areas;
  final int? selected;

  @override
  State<_AreaSheet> createState() => _AreaSheetState();
}

class _AreaSheetState extends State<_AreaSheet> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final shown = q.isEmpty ? widget.areas : widget.areas.where((a) => a.title.toLowerCase().contains(q)).toList(growable: false);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AtomSpace.gutter),
              child: Text('Choose your area', style: AtomText.heading),
            ),
            const SizedBox(height: AtomSpace.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AtomSpace.gutter),
              child: AtomSearchField(controller: _search, hint: 'Search areas', autofocus: true, onChanged: (v) => setState(() => _query = v)),
            ),
            const SizedBox(height: AtomSpace.xs),
            Expanded(
              child: shown.isEmpty
                  ? Center(child: Text('No area matches "${_query.trim()}"', style: AtomText.body))
                  : ListView.builder(
                      itemCount: shown.length,
                      itemBuilder: (context, i) {
                        final a = shown[i];
                        final on = a.id == widget.selected;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: AtomSpace.gutter),
                          title: Text(a.title, style: AtomText.body.copyWith(color: on ? AtomColors.primary : AtomColors.ink, fontWeight: on ? FontWeight.w800 : FontWeight.w500)),
                          trailing: on ? const Icon(Icons.check_rounded, color: AtomColors.primary) : null,
                          onTap: () => Navigator.of(context).pop(a),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
