class AreaModel {
  final int id;
  final String title;
  final int cityId;

  AreaModel({required this.id, required this.title, required this.cityId});

  factory AreaModel.fromJson(Map<String, dynamic> json) {
    return AreaModel(
      id: json['id'],
      title: json['title'],
      cityId: json['city_id'],
    );
  }
}
