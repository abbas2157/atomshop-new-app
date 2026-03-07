class CategoryModel {
  final String name;
  final String imageUrl;

  CategoryModel({required this.name, required this.imageUrl});
}

final List<CategoryModel> categories = [
  CategoryModel(
    name: "Motor Bikes",
    imageUrl: "https://atomshop.pk/public/web/img/motor-bikes.png",
  ),
  CategoryModel(
    name: "Electric Scooty",
    imageUrl: "https://atomshop.pk/public/web/img/electric-scooty.png",
  ),
  CategoryModel(
    name: "Smart TV",
    imageUrl: "https://atomshop.pk/public/web/img/smart-tv.png",
  ),
  CategoryModel(
    name: "Laptops",
    imageUrl: "https://atomshop.pk/public/web/img/laptops.png",
  ),
  CategoryModel(
    name: "Mobiles",
    imageUrl: "https://atomshop.pk/public/web/img/mobiles.png",
  ),
  CategoryModel(
    name: "Tablets",
    imageUrl: "https://atomshop.pk/public/web/img/tablets.png",
  ),
  CategoryModel(
    name: "Home Appliaances",
    imageUrl: "https://atomshop.pk/public/web/img/home-appliaances.png",
  ),
  CategoryModel(
    name: "Gaming",
    imageUrl: "https://atomshop.pk/public/web/img/gaming.png",
  ),
];
