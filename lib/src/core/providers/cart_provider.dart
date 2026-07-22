import 'package:ezer_fresh/src/core/services/local_cache_service.dart';
import 'package:ezer_fresh/src/domain/models/product_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartItem {
  final Product product;
  final int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  CartItem copyWith({
    Product? product,
    int? quantity,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product': product.toMap(),
      'quantity': quantity,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      product: Product.fromMap(map['product'] as Map<String, dynamic>),
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}

class CartNotifier extends Notifier<List<CartItem>> {
  static const String _cartKey = 'local_user_cart';
  final LocalCacheService _cacheService = LocalCacheService();

  @override
  List<CartItem> build() {
    _loadPersistedCart();
    return [];
  }

  Future<void> _loadPersistedCart() async {
    try {
      final cachedData = await _cacheService.get(_cartKey, ignoreExpiry: true);
      if (cachedData is List) {
        final items = cachedData
            .map((e) => CartItem.fromMap(e as Map<String, dynamic>))
            .toList();
        state = items;
      }
    } catch (e) {
      debugPrint('Error restoring cart from local storage: $e');
    }
  }

  Future<void> _persistCart() async {
    try {
      final listMap = state.map((item) => item.toMap()).toList();
      await _cacheService.save(_cartKey, listMap, ttlMinutes: 10080); // 7 days TTL
    } catch (e) {
      debugPrint('Error persisting cart: $e');
    }
  }

  void addItem(Product product) {
    if (state.any((item) => item.product.id == product.id)) {
      state = [
        for (final item in state)
          if (item.product.id == product.id)
            item.copyWith(quantity: item.quantity + 1)
          else
            item
      ];
    } else {
      state = [...state, CartItem(product: product)];
    }
    _persistCart();
  }

  void removeItem(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
    _persistCart();
  }

  void decrementItem(String productId) {
    final item = state.firstWhere((i) => i.product.id == productId);
    if (item.quantity <= 1) {
      removeItem(productId);
    } else {
      state = [
        for (final i in state)
          if (i.product.id == productId)
            i.copyWith(quantity: i.quantity - 1)
          else
            i
      ];
      _persistCart();
    }
  }

  void clear() {
    state = [];
    _persistCart();
  }

  double get total => state.fold(0, (sum, item) => sum + (item.product.price * item.quantity));
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(() {
  return CartNotifier();
});
