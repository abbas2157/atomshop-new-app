import 'package:atompro/core/common/widgets/custom_drop_down.dart';
import 'package:atompro/features/city_area_selector/model/area_model.dart';
import 'package:atompro/features/city_area_selector/model/city_model.dart';
import 'package:atompro/features/city_area_selector/viewmodel/city_area_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CityAreaWidget extends ConsumerWidget {
  const CityAreaWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cityAreaViewModelProvider);
    final notifier = ref.read(cityAreaViewModelProvider.notifier);

    return Column(
      children: [
        CustomSearchDropdown<CityModel>(
          labelText: "City",
          items: state.cities,
          selectedItem: state.selectedCity,
          itemAsString: (city) => city.title,
          onChanged: notifier.onCityChanged,
        ),
        const SizedBox(height: 16),
        CustomSearchDropdown<AreaModel>(
          labelText: "Area",
          items: state.areas,
          selectedItem: state.selectedArea,
          itemAsString: (area) => area.title,
          onChanged: notifier.onAreaChanged,
        ),
      ],
    );
  }
}
