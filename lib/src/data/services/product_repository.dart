import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ezer_fresh/src/core/services/product_cache_service.dart';
import 'package:ezer_fresh/src/domain/models/product_model.dart';

class ProductRepository {
  final FirebaseFirestore _firestore;
  final ProductCacheService _cache;

  ProductRepository({
    FirebaseFirestore? firestore,
    ProductCacheService? cache,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _cache = cache ?? ProductCacheService();

  Stream<List<Product>> watchCachedProducts() async* {
    final cached = await _cache.read();
    var emittedProducts = false;
    List<Product>? lastProducts;

    if (cached != null && cached.products.isNotEmpty) {
      emittedProducts = true;
      lastProducts = cached.products;
      yield cached.products;

      if (cached.isFresh(_cache.now)) return;
    } else {
      try {
        final localProducts = await _getProductsFromFirestore(Source.cache);
        if (localProducts.isNotEmpty) {
          emittedProducts = true;
          lastProducts = localProducts;
          yield localProducts;
        }
      } catch (_) {
        // Firestore's local cache may not have the query yet.
      }
    }

    try {
      final serverProducts = await _getProductsFromFirestore(Source.server);
      await _cache.write(serverProducts);

      if (!emittedProducts || !_sameProducts(lastProducts, serverProducts)) {
        yield serverProducts;
      }
    } catch (_) {
      if (!emittedProducts) rethrow;
    }
  }

  Stream<List<Product>> watchLiveProducts() {
    return _allProductsQuery.snapshots().map(_productsFromSnapshot);
  }

  Stream<Product?> watchProductById(String id) {
    return _firestore
        .collection('products')
        .doc(id)
        .snapshots()
        .map(_productFromDocument);
  }

  Future<void> clearCache() => _cache.clear();

  Query<Map<String, dynamic>> get _allProductsQuery {
    return _firestore.collection('products').orderBy(
          'createdAt',
          descending: true,
        );
  }

  Future<List<Product>> _getProductsFromFirestore(Source source) async {
    final snapshot = await _allProductsQuery.get(GetOptions(source: source));
    return _productsFromSnapshot(snapshot);
  }

  List<Product> _productsFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs
        .map(_productFromDocument)
        .whereType<Product>()
        .toList(growable: false);
  }

  Product? _productFromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (!doc.exists || data == null) return null;

    final categoryId = data['categoryId'] as String? ?? '1';
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
      description:
          data['description'] as String? ?? 'No description available.',
    );
  }

  bool _sameProducts(List<Product>? current, List<Product> next) {
    if (current == null || current.length != next.length) return false;

    for (var i = 0; i < current.length; i++) {
      if (current[i].toJson().toString() != next[i].toJson().toString()) {
        return false;
      }
    }

    return true;
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
}
