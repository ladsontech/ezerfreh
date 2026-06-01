import 'package:ezer_fresh/src/domain/models/product_model.dart';
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
}

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => [];

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
  }

  void removeItem(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
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
    }
  }

  void clear() {
    state = [];
  }

  double get total => state.fold(0, (sum, item) => sum + (item.product.price * item.quantity));
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(() {
  return CartNotifier();
});
