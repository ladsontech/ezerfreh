import 'package:ezer_fresh/src/domain/models/product_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final productsProvider = FutureProvider.family<List<Product>, String>((ref, categoryId) async {
  // For now, we'll use dummy data. Later, this will be replaced with a real API call.
  await Future.delayed(const Duration(seconds: 1));

  final allProducts = [
    const Product(id: '1', name: 'Carrot', categoryId: '1', imageUrl: 'assets/vegetables.png', price: 1.99),
    const Product(id: '2', name: 'Broccoli', categoryId: '1', imageUrl: 'assets/vegetables.png', price: 2.49),
    const Product(id: '3', name: 'Apple', categoryId: '2', imageUrl: 'assets/fruits.png', price: 0.99),
    const Product(id: '4', name: 'Banana', categoryId: '2', imageUrl: 'assets/fruits.png', price: 0.59),
    const Product(id: '5', name: 'Mint', categoryId: '3', imageUrl: 'assets/herbs.png', price: 1.29),
    const Product(id: '6', name: 'Cilantro', categoryId: '3', imageUrl: 'assets/herbs.png', price: 1.49),
    const Product(id: '7', name: 'Cinnamon', categoryId: '4', imageUrl: 'assets/spices.png', price: 3.99),
    const Product(id: '8', name: 'Turmeric', categoryId: '4', imageUrl: 'assets/spices.png', price: 4.49),
  ];

  return allProducts.where((product) => product.categoryId == categoryId).toList();
});
