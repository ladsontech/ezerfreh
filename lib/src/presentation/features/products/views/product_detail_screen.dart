import 'package:cached_network_image/cached_network_image.dart';
import 'package:ezer_fresh/src/domain/models/product_model.dart';
import 'package:ezer_fresh/src/core/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductDetailScreen extends ConsumerWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: Text(
          product.name,
          style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image now clearly below the App Bar
            Hero(
              tag: 'product-${product.id}',
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child: _buildProductImage(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: GoogleFonts.lato(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'UGX ${product.price.toStringAsFixed(0)}',
                            style: GoogleFonts.lato(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF2E7D32),
                            ),
                          ),
                          Text(
                            product.unit,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Local Fresh Produce',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Description',
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    product.description,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildAddToCartButton(context, ref),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    final url = product.imageUrl.trim();

    // Empty or default asset fallback
    if (url.isEmpty ||
        url.startsWith('assets/')) {
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(
            Icons.shopping_basket_outlined,
            size: 100,
            color: Colors.grey,
          ),
        ),
      );
    }

    // Network images (Firebase Storage download URLs)
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[200],
          child: const Center(
            child: Icon(Icons.broken_image, size: 100, color: Colors.grey),
          ),
        ),
      );
    }

    return Image.asset(url, fit: BoxFit.cover);
  }

  Widget _buildAddToCartButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: () {
          ref.read(cartProvider.notifier).addItem(product);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${product.name} added to cart!')),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Add to Cart',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
