import 'package:atompro/features/city_area_selector/model/area_model.dart';
import 'package:atompro/features/city_area_selector/model/city_model.dart';
import 'package:atompro/features/city_area_selector/repo/city_area_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'city_area_viewmodel.g.dart';

// State class remains the same
class CityAreaState {
  final List<CityModel> cities;
  final List<AreaModel> areas;
  final CityModel? selectedCity;
  final AreaModel? selectedArea;
  final bool isLoading;

  CityAreaState({
    this.cities = const [],
    this.areas = const [],
    this.selectedCity,
    this.selectedArea,
    this.isLoading = false,
  });

  CityAreaState copyWith({
    List<CityModel>? cities,
    List<AreaModel>? areas,
    CityModel? selectedCity,
    AreaModel? selectedArea,
    bool? isLoading,
  }) {
    return CityAreaState(
      cities: cities ?? this.cities,
      areas: areas ?? this.areas,
      selectedCity: selectedCity ?? this.selectedCity,
      selectedArea: selectedArea,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

@riverpod
class CityAreaViewModel extends _$CityAreaViewModel {
  @override
  CityAreaState build() {
    Future.microtask(() => fetchCities());
    return CityAreaState();
  }

  // void _init() => fetchCities();

  Future<void> fetchCities() async {
    state = state.copyWith(isLoading: true);
    try {
      // Watching the generated repo provider
      final repo = ref.read(cityAreaRepositoryProvider);
      final cities = await repo.getCities();
      state = state.copyWith(cities: cities, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> onCityChanged(CityModel? city) async {
    state = state.copyWith(
      selectedCity: city,
      selectedArea: null,
      isLoading: true,
    );
    if (city == null) return;

    try {
      final repo = ref.read(cityAreaRepositoryProvider);
      final areas = await repo.getAreas(city.id);
      state = state.copyWith(areas: areas, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void onAreaChanged(AreaModel? area) {
    state = state.copyWith(selectedArea: area);
  }

  void reset() {
    state = state.copyWith(
      selectedCity: null,
      selectedArea: null,
      areas: [], // Clear areas since no city is selected
    );
  }
}
