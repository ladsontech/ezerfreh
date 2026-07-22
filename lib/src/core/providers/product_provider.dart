import 'package:ezer_fresh/src/data/services/product_repository.dart';
import 'package:ezer_fresh/src/domain/models/product_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

final allProductsProvider = StreamProvider<List<Product>>((ref) {
  ref.keepAlive();
  final repository = ref.watch(productRepositoryProvider);

  return repository.watchCachedProducts();
});

final productsProvider = Provider.family<AsyncValue<List<Product>>, String>((
  ref,
  categoryId,
) {
  ref.keepAlive();

  return ref
      .watch(allProductsProvider)
      .whenData(
        (products) => products
            .where((product) => product.categoryId == categoryId)
            .toList(growable: false),
      );
});

final adminProductsProvider = StreamProvider<List<Product>>((ref) {
  ref.keepAlive();
  final repository = ref.watch(productRepositoryProvider);

  return repository.watchLiveProducts();
});

final productByIdProvider = StreamProvider.family<Product?, String>((ref, id) {
  ref.keepAlive();
  final repository = ref.watch(productRepositoryProvider);

  return repository.watchProductById(id);
});
Future<List<Product>> refreshProductsCatalog(WidgetRef ref) async {
  await ref.read(productRepositoryProvider).clearCache();
  return ref.refresh(allProductsProvider.future);
}
