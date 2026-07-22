import 'package:ezer_fresh/src/core/providers/providers.dart';
import 'package:ezer_fresh/src/core/providers/product_provider.dart';
import 'package:ezer_fresh/src/domain/models/category_model.dart';
import 'package:ezer_fresh/src/presentation/widgets/product_card.dart';
import 'package:ezer_fresh/src/presentation/widgets/sticky_cart_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductListScreen extends ConsumerWidget {
  final Category? category;
  const ProductListScreen({super.key, this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsyncValue = category == null
        ? ref.watch(allProductsProvider)
        : ref.watch(productsProvider(category!.id));
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        title: Text(
          category?.name ?? 'All Products',
          style: GoogleFonts.lato(fontWeight: FontWeight.w800),
        ),
        backgroundColor: const Color(0xFFF8FAF8),
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8,
                ),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: (value) =>
                        ref.read(searchQueryProvider.notifier).query = value,
                    decoration: InputDecoration(
                      hintText: category == null
                          ? 'Search for products...'
                          : 'Search for ${category!.name.toLowerCase()}...',
                      hintStyle: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await refreshProductsCatalog(ref);
                  },
                  child: productsAsyncValue.when(
                    data: (products) {
                      final filteredProducts = products.where((p) {
                        return p.name.toLowerCase().contains(
                              searchQuery.toLowerCase(),
                            ) ||
                            p.description.toLowerCase().contains(
                              searchQuery.toLowerCase(),
                            );
                      }).toList();

                      if (filteredProducts.isEmpty) {
                        return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.5,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 64,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  searchQuery.isEmpty
                                      ? 'No products found'
                                      : 'No matches for "$searchQuery"',
                                  style: GoogleFonts.lato(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return GridView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          16.0,
                          16.0,
                          16.0,
                          ref.watch(cartProvider).isNotEmpty ? 88.0 : 16.0,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16.0,
                              mainAxisSpacing: 16.0,
                              childAspectRatio: 0.68,
                            ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return ProductCard(product: product);
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stackTrace) =>
                        Center(child: Text('Error: $error')),
                  ),
                ),
              ),
            ],
          ),
          const Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: StickyCartBar(bottomOffset: 0),
          ),
        ],
      ),
    );
  }
}
