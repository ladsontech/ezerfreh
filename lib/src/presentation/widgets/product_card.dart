import 'package:cached_network_image/cached_network_image.dart';
import 'package:ezer_fresh/src/core/providers/cart_provider.dart';
import 'package:ezer_fresh/src/domain/models/product_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ProductCard extends ConsumerStatefulWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final currencyFormat = NumberFormat('#,##0');
    final cartItems = ref.watch(cartProvider);
    final cartIndex = cartItems.indexWhere((i) => i.product.id == product.id);
    final inCartQty = cartIndex != -1 ? cartItems[cartIndex].quantity : 0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isHovered ? const Color(0xFF2E7D32) : const Color(0xFFE8ECE8),
            width: _isHovered ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? const Color(0xFF2E7D32).withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: _isHovered ? 14 : 8,
              offset: Offset(0, _isHovered ? 6 : 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: () => context.push('/product-detail', extra: product),
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Container with Top Category Tag
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.fromLTRB(10, 10, 10, 4),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7FAF7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Hero(
                        tag: 'product-${product.id}',
                        child: _buildProductImage(product.imageUrl),
                      ),
                    ),
                    if (product.categoryName != null &&
                        product.categoryName!.isNotEmpty)
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            product.categoryName!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Info & Action Section
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1B3D25),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'UGX ${currencyFormat.format(product.price)}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    color: const Color(0xFF2E7D32),
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              Text(
                                '/ ${product.unit}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  color: const Color(0xFF7A7F7A),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Add Button with Cart Count Indicator
                        GestureDetector(
                          onTap: () {
                            ref.read(cartProvider.notifier).addItem(product);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: inCartQty > 0
                                  ? const Color(0xFF1B3D25)
                                  : const Color(0xFF2E7D32),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: inCartQty > 0
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.shopping_bag_outlined,
                                        color: Colors.white,
                                        size: 13,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        '$inCartQty',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 15,
                                  ),
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
      ),
    );
  }

  Widget _buildProductImage(String url) {
    final trimmedUrl = url.trim();

    if (trimmedUrl.isEmpty) {
      return const Center(
        child: Icon(
          Icons.shopping_basket_outlined,
          size: 40,
          color: Color(0xFFA5D6A7),
        ),
      );
    }

    if (trimmedUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: trimmedUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF2E7D32),
            ),
          ),
        ),
        errorWidget: (context, url, error) => const Center(
          child: Icon(Icons.broken_image, color: Color(0xFFA5D6A7), size: 36),
        ),
      );
    }

    return Image.asset(
      trimmedUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const Center(
        child: Icon(Icons.image_not_supported, color: Color(0xFFA5D6A7), size: 36),
      ),
    );
  }
}

