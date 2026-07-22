import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ezer_fresh/src/core/services/local_cache_service.dart';
import 'package:ezer_fresh/src/domain/models/product_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const String _allProductsCacheKey = 'cache_all_products';
const int _productCacheTtlMinutes = 120; // Cache products locally for 2 hours

final _localCache = LocalCacheService();

/// Main product catalog provider backed by local device cache & Firestore fallback.
/// Uses Stale-While-Revalidate pattern to minimize Firestore database read costs.
final allProductsProvider = FutureProvider<List<Product>>((ref) async {
  ref.keepAlive();

  // 1. Try reading from Local Device Storage first
  final cachedData = await _localCache.get(_allProductsCacheKey);
  if (cachedData is List && cachedData.isNotEmpty) {
    try {
      final cachedProducts = cachedData
          .map((e) => Product.fromMap(e as Map<String, dynamic>))
          .toList();
      debugPrint('Loaded ${cachedProducts.length} products from Local Device Cache (0 DB reads).');

      // Return cached products immediately to UI.
      // Trigger a silent background update only if cache is close to expiry or empty.
      _fetchAndCacheServerProductsSilently(ref);
      return cachedProducts;
    } catch (e) {
      debugPrint('Cache parsing error: $e');
    }
  }

  // 2. Cache miss or expired: Fetch from Firestore (Source.cache first, then Source.serverAndCache)
  return await _fetchProductsFromFirestore();
});

/// Fetches fresh products from Firestore and updates local device storage.
Future<List<Product>> _fetchProductsFromFirestore() async {
  try {
    debugPrint('Fetching products from Firestore server...');
    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .orderBy('createdAt', descending: true)
        .get(const GetOptions(source: Source.serverAndCache));

    final products = snapshot.docs
        .map((doc) => _productFromDocument(doc))
        .whereType<Product>()
        .toList();

    // Persist to local storage for 2 hours
    final jsonList = products.map((p) => p.toMap()).toList();
    await _localCache.save(_allProductsCacheKey, jsonList, ttlMinutes: _productCacheTtlMinutes);

    return products;
  } catch (e) {
    debugPrint('Firestore product fetch error: $e');
    // Fallback to expired cache if network is down/offline
    final fallbackData = await _localCache.get(_allProductsCacheKey, ignoreExpiry: true);
    if (fallbackData is List && fallbackData.isNotEmpty) {
      return fallbackData
          .map((e) => Product.fromMap(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}

/// Silently updates the local cache from Firestore without blocking UI
void _fetchAndCacheServerProductsSilently(Ref ref) async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .orderBy('createdAt', descending: true)
        .get(const GetOptions(source: Source.serverAndCache));

    final products = snapshot.docs
        .map((doc) => _productFromDocument(doc))
        .whereType<Product>()
        .toList();

    if (products.isNotEmpty) {
      final jsonList = products.map((p) => p.toMap()).toList();
      await _localCache.save(_allProductsCacheKey, jsonList, ttlMinutes: _productCacheTtlMinutes);
    }
  } catch (_) {
    // Ignore background refresh errors
  }
}

/// Filter products by category ID from in-memory cached catalog (0 extra Firestore reads).
final productsProvider = Provider.family<AsyncValue<List<Product>>, String>((ref, categoryId) {
  final allProductsState = ref.watch(allProductsProvider);

  return allProductsState.whenData((products) {
    if (categoryId == 'all' || categoryId.isEmpty) return products;
    return products.where((p) => p.categoryId == categoryId).toList();
  });
});

/// Get single product by ID from in-memory cached catalog (0 extra Firestore reads).
final productByIdProvider = Provider.family<AsyncValue<Product?>, String>((ref, id) {
  final allProductsState = ref.watch(allProductsProvider);

  return allProductsState.whenData((products) {
    return products.firstWhere(
      (p) => p.id == id,
      orElse: () => Product(
        id: id,
        name: 'Product Not Found',
        categoryId: '1',
        imageUrl: '',
        price: 0,
        unit: '',
        description: '',
      ),
    );
  });
});

/// Force manual refresh of product catalog (bypassing local cache for pull-to-refresh).
Future<List<Product>> refreshProductsCatalog(WidgetRef ref) async {
  await _localCache.remove(_allProductsCacheKey);
  return ref.refresh(allProductsProvider.future);
}

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
