class CategoryModel {
  final String name;
  final String imageUrl;

  CategoryModel({required this.name, required this.imageUrl});
}

final List<CategoryModel> categories = [
  CategoryModel(name: "Motor Bikes", imageUrl: "assets/images/motor-bikes.png"),
  CategoryModel(
    name: "Electric Scooty",
    imageUrl: "assets/images/electric-scooty.png",
  ),
  CategoryModel(name: "Smart TV", imageUrl: "assets/images/smart-tv.png"),
  CategoryModel(name: "Laptops", imageUrl: "assets/images/laptops.png"),
  CategoryModel(name: "Mobiles", imageUrl: "assets/images/mobiles.png"),
  CategoryModel(name: "Tablets", imageUrl: "assets/images/tablets.png"),
  CategoryModel(
    name: "Home Appliaances",
    imageUrl: "assets/images/home-appliaances.png",
  ),
  CategoryModel(name: "Gaming", imageUrl: "assets/images/gaming.png"),
];
