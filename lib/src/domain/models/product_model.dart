import 'dart:convert';

class Product {
  final String id;
  final String name;
  final String categoryId;
  final String? categoryName;
  final String imageUrl;
  final double price;
  final String unit;
  final String description;

  const Product({
    required this.id,
    required this.name,
    required this.categoryId,
    this.categoryName,
    required this.imageUrl,
    required this.price,
    required this.unit,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'imageUrl': imageUrl,
      'price': price,
      'unit': unit,
      'description': description,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'N/A',
      categoryId: map['categoryId'] as String? ?? '1',
      categoryName: map['categoryName'] as String?,
      imageUrl: map['imageUrl'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] as String? ?? '/ Unit',
      description: map['description'] as String? ?? 'No description available.',
    );
  }

  String toJson() => json.encode(toMap());

  factory Product.fromJson(String source) =>
      Product.fromMap(json.decode(source) as Map<String, dynamic>);
}
