import 'package:cached_network_image/cached_network_image.dart';
import 'package:ezer_fresh/src/core/providers/cart_provider.dart';
import 'package:ezer_fresh/src/domain/models/product_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductCard extends ConsumerWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => context.push('/product-detail', extra: product),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Responsive Landscape Image Section
            AspectRatio(
              aspectRatio: 1.3,
              child: Container(
                padding: const EdgeInsets.all(10),
                width: double.infinity,
                child: Hero(
                  tag: 'product-${product.id}',
                  child: _buildProductImage(),
                ),
              ),
            ),
            // Info Section
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fresh ${product.categoryName ?? "Produce"}',
                    style: GoogleFonts.lato(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lato(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'UGX ${product.price.toStringAsFixed(0)}',
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              color: const Color(0xFF2E7D32),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            product.unit,
                            style: GoogleFonts.lato(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      // Add to Cart Button
                      GestureDetector(
                        onTap: () {
                          ref.read(cartProvider.notifier).addItem(product);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${product.name} added to cart'),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              backgroundColor: const Color(0xFF2E7D32),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4CAF50).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.add,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
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

    if (url.isEmpty ||
        url == 'assets/vegetables.png' ||
        url == 'assets/fruits.png' ||
        url == 'assets/herbs.png' ||
        url == 'assets/spices.png') {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF1F8F1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Center(
          child: Icon(
            Icons.shopping_basket_outlined,
            size: 40,
            color: Color(0xFFA5D6A7),
          ),
        ),
      );
    }

    if (url.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: const Color(0xFFF1F8F1),
            child: const Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF4CAF50),
                ),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: const Color(0xFFF1F8F1),
            child: const Icon(Icons.broken_image, color: Color(0xFFA5D6A7)),
          ),
        ),
      );
    }

    return Image.asset(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: const Color(0xFFF1F8F1),
        child: const Icon(Icons.image_not_supported, color: Color(0xFFA5D6A7)),
      ),
    );
  }
}

