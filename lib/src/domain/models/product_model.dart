class Product {
  final String id;
  final String name;
  final String categoryId;
  final String? categoryName; // Added field
  final String imageUrl;
  final double price;
  final String unit;
  final String description;

  const Product({
    required this.id,
    required this.name,
    required this.categoryId,
    this.categoryName, // Optional parameter
    required this.imageUrl,
    required this.price,
    required this.unit,
    required this.description,
  });
}
