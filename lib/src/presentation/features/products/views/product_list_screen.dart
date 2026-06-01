import 'package:ezer_fresh/src/core/providers/providers.dart';
import 'package:ezer_fresh/src/core/providers/product_provider.dart';
import 'package:ezer_fresh/src/domain/models/category_model.dart';
import 'package:ezer_fresh/src/presentation/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductListScreen extends ConsumerWidget {
  final Category? category;
  const ProductListScreen({super.key, this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (category == null) {
      return const Scaffold(body: Center(child: Text('Invalid Category')));
    }
    final productsAsyncValue = ref.watch(productsProvider(category!.id));
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        title: Text(
          category!.name,
          style: GoogleFonts.lato(fontWeight: FontWeight.w800),
        ),
        backgroundColor: const Color(0xFFF8FAF8),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) =>
                    ref.read(searchQueryProvider.notifier).query = value,
                decoration: InputDecoration(
                  hintText: 'Search for ${category!.name.toLowerCase()}...',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: productsAsyncValue.when(
              data: (products) {
                final filteredProducts = products.where((p) {
                  return p.name
                          .toLowerCase()
                          .contains(searchQuery.toLowerCase()) ||
                      p.description
                          .toLowerCase()
                          .contains(searchQuery.toLowerCase());
                }).toList();

                if (filteredProducts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          searchQuery.isEmpty
                              ? 'No products found'
                              : 'No matches for "$searchQuery"',
                          style: GoogleFonts.lato(
                              color: Colors.grey[600], fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) =>
                  Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }
}

