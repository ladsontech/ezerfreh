import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ezer_fresh/src/domain/models/product_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final productsProvider = StreamProvider.family<List<Product>, String>((
  ref,
  categoryId,
) {
  final firestore = FirebaseFirestore.instance;

  print('Fetching products for category: $categoryId');
  return firestore
      .collection('products')
      .where('categoryId', isEqualTo: categoryId)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          final unit =
              data['unit'] ?? _getDefaultUnit(data['categoryId'] ?? categoryId);
          return Product(
            id: doc.id,
            name: data['name'] ?? 'N/A',
            categoryId: data['categoryId'] ?? categoryId,
            categoryName: data['categoryName'],
            imageUrl: data['imageUrl'] ?? '',
            price: (data['price'] ?? 0.0).toDouble(),
            unit: unit,
            description: data['description'] ?? 'No description available.',
          );
        }).toList();
      });
});

final allProductsProvider = StreamProvider<List<Product>>((ref) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('products')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          final unit =
              data['unit'] ?? _getDefaultUnit(data['categoryId'] ?? '1');
          return Product(
            id: doc.id,
            name: data['name'] ?? 'N/A',
            categoryId: data['categoryId'] ?? '1',
            categoryName: data['categoryName'],
            imageUrl: data['imageUrl'] ?? '',
            price: (data['price'] ?? 0.0).toDouble(),
            unit: unit,
            description: data['description'] ?? 'No description available.',
          );
        }).toList();
      });
});

String _getDefaultUnit(String categoryId) {
  switch (categoryId) {
    case '1':
      return '/ Kg';
    case '2':
      return '/ Piece';
    case '3':
      return '/ Bundle';
    case '4':
      return '/ Pack';
    default:
      return '/ Unit';
  }
}
