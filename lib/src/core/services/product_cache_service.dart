import 'dart:convert';

import 'package:ezer_fresh/src/domain/models/product_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductCacheEntry {
  final List<Product> products;
  final DateTime cachedAt;
  final Duration ttl;

  const ProductCacheEntry({
    required this.products,
    required this.cachedAt,
    required this.ttl,
  });

  bool isFresh(DateTime now) => now.difference(cachedAt) < ttl;
}

class ProductCacheService {
  static const cacheTtl = Duration(hours: 6);
  static const _productsKey = 'product_catalog_cache_v1';
  static const _cachedAtKey = 'product_catalog_cache_cached_at_v1';

  final SharedPreferences? _preferences;
  final DateTime Function() _now;

  ProductCacheService({
    SharedPreferences? preferences,
    DateTime Function()? now,
  }) : _preferences = preferences,
       _now = now ?? DateTime.now;

  Future<ProductCacheEntry?> read() async {
    final prefs = await _prefs;
    final rawProducts = prefs.getString(_productsKey);
    final cachedAtMs = prefs.getInt(_cachedAtKey);

    if (rawProducts == null || cachedAtMs == null) return null;

    try {
      final decoded = jsonDecode(rawProducts);
      if (decoded is! List) return null;

      final products = decoded
          .whereType<Map>()
          .map((item) => Product.fromJson(Map<String, dynamic>.from(item)))
          .where((product) => product.id.isNotEmpty)
          .toList(growable: false);

      return ProductCacheEntry(
        products: products,
        cachedAt: DateTime.fromMillisecondsSinceEpoch(cachedAtMs, isUtc: true),
        ttl: cacheTtl,
      );
    } catch (_) {
      await clear();
      return null;
    }
  }

  Future<void> write(List<Product> products) async {
    final prefs = await _prefs;
    final encoded = jsonEncode(
      products.map((product) => product.toJson()).toList(),
    );

    await prefs.setString(_productsKey, encoded);
    await prefs.setInt(_cachedAtKey, _now().toUtc().millisecondsSinceEpoch);
  }

  Future<void> clear() async {
    final prefs = await _prefs;
    await prefs.remove(_productsKey);
    await prefs.remove(_cachedAtKey);
  }

  DateTime get now => _now();

  Future<SharedPreferences> get _prefs async =>
      _preferences ?? SharedPreferences.getInstance();
}
