import 'package:atompro/core/network/network_manager.dart';
import 'package:atompro/core/network/network_provider.dart';
import 'package:atompro/features/city_area_selector/model/area_model.dart';
import 'package:atompro/features/city_area_selector/model/city_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'city_area_repository.g.dart';

@riverpod
CityAreaRepository cityAreaRepository(Ref ref) {
  final network = ref.watch(networkManagerProvider);
  return CityAreaRepository(network);
}

class CityAreaRepository {
  final NetworkManager _network;
  CityAreaRepository(this._network);

  Future<List<CityModel>> getCities() async {
    final response = await _network.getRequest("cities");
    if (response["success"] == true) {
      final List data = response["data"];
      return data.map((json) => CityModel.fromJson(json)).toList();
    }
    return [];
  }

  Future<List<AreaModel>> getAreas(int cityId) async {
    final response = await _network.getRequest("areas/$cityId");
    if (response["success"] == true) {
      final List data = response["data"];
      return data.map((json) => AreaModel.fromJson(json)).toList();
    }
    return [];
  }
}
