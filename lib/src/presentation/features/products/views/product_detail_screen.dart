import 'package:cached_network_image/cached_network_image.dart';
import 'package:ezer_fresh/src/domain/models/product_model.dart';
import 'package:ezer_fresh/src/core/providers/providers.dart';
import 'package:ezer_fresh/src/presentation/widgets/sticky_cart_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductDetailScreen extends ConsumerWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF9F4),
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: Text(
          product.name,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'product-${product.id}',
                  child: AspectRatio(
                    aspectRatio: 1.3,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE5E4DC)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _buildProductImage(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF1B3D25),
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'UGX ${product.price.toStringAsFixed(0)}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF2E7D32),
                                ),
                              ),
                              Text(
                                product.unit,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: const Color(0xFF7A7F7A),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Local Organic Fresh Produce',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: const Color(0xFF2E7D32),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Description',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1B3D25),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        product.description,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          height: 1.6,
                          color: const Color(0xFF4A4E4A),
                        ),
                      ),
                      const SizedBox(height: 40),
                      _buildAddToCartButton(context, ref),
                      SizedBox(
                        height: ref.watch(cartProvider).isNotEmpty ? 92.0 : 20.0,
                      ),
                    ],
                  ),
                ),
              ],
            ),
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

  Widget _buildProductImage() {
    final url = product.imageUrl.trim();

    if (url.isEmpty) {
      return Container(
        color: const Color(0xFFF0EEE4),
        child: const Center(
          child: Icon(
            Icons.shopping_basket_outlined,
            size: 80,
            color: Color(0xFFB5B9B5),
          ),
        ),
      );
    }

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: const Color(0xFFF0EEE4),
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: const Color(0xFFF0EEE4),
          child: const Center(
            child: Icon(Icons.broken_image, size: 80, color: Color(0xFFB5B9B5)),
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
            SnackBar(
              content: Text('${product.name} added to cart!'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: const Color(0xFF2E7D32),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          'Add to Cart',
          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
