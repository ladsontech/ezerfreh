import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ezer_fresh/src/domain/models/product_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final productsProvider = StreamProvider.family<List<Product>, String>((
  ref,
  categoryId,
) {
  ref.keepAlive();
  final firestore = FirebaseFirestore.instance;

  debugPrint('Fetching products for category: $categoryId');
  return firestore
      .collection('products')
      .where('categoryId', isEqualTo: categoryId)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map(
              (doc) =>
                  _productFromDocument(doc, fallbackCategoryId: categoryId)!,
            )
            .toList();
      });
});

final allProductsProvider = StreamProvider<List<Product>>((ref) {
  ref.keepAlive();
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('products')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) => _productFromDocument(doc)!).toList();
      });
});

final productByIdProvider = StreamProvider.family<Product?, String>((ref, id) {
  ref.keepAlive();
  return FirebaseFirestore.instance
      .collection('products')
      .doc(id)
      .snapshots()
      .map(_productFromDocument);
});

Product? _productFromDocument(
  DocumentSnapshot<Map<String, dynamic>> doc, {
  String fallbackCategoryId = '1',
}) {
  final data = doc.data();
  if (!doc.exists || data == null) return null;

  final categoryId = data['categoryId'] as String? ?? fallbackCategoryId;
  final price = data['price'];
  final unit = data['unit'] as String? ?? _getDefaultUnit(categoryId);

  return Product(
    id: doc.id,
    name: data['name'] as String? ?? 'N/A',
    categoryId: categoryId,
    categoryName: data['categoryName'] as String?,
    imageUrl: data['imageUrl'] as String? ?? '',
    price: price is num ? price.toDouble() : 0,
    unit: unit,
    description: data['description'] as String? ?? 'No description available.',
  );
}

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
