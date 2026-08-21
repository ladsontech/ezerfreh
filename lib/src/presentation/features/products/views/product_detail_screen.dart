import 'package:cached_network_image/cached_network_image.dart';
import 'package:ezer_fresh/src/core/providers/cart_provider.dart';
import 'package:ezer_fresh/src/core/providers/product_provider.dart';
import 'package:ezer_fresh/src/domain/models/product_model.dart';
import 'package:ezer_fresh/src/presentation/widgets/product_card.dart';
import 'package:ezer_fresh/src/presentation/widgets/sticky_cart_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ProductDetailScreen extends ConsumerWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final cartItemIndex = cartItems.indexWhere((item) => item.product.id == product.id);
    final quantityInCart = cartItemIndex != -1 ? cartItems[cartItemIndex].quantity : 0;

    // Fetch related products (same category if available, otherwise all products)
    final relatedAsync = product.categoryId.isNotEmpty
        ? ref.watch(productsProvider(product.categoryId))
        : ref.watch(allProductsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF9F4),
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        title: Text(
          product.name,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: const Color(0xFF1B3D25),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share product',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Sharing ${product.name}...'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 900;

              return relatedAsync.when(
                data: (products) {
                  final relatedProducts = products
                      .where((p) => p.id != product.id)
                      .take(6)
                      .toList();

                  if (isDesktop) {
                    return _buildDesktopLayout(
                      context,
                      ref,
                      quantityInCart,
                      relatedProducts,
                    );
                  }

                  return _buildMobileLayout(
                    context,
                    ref,
                    quantityInCart,
                    relatedProducts,
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                ),
                error: (_, __) {
                  if (isDesktop) {
                    return _buildDesktopLayout(
                      context,
                      ref,
                      quantityInCart,
                      [],
                    );
                  }
                  return _buildMobileLayout(
                    context,
                    ref,
                    quantityInCart,
                    [],
                  );
                },
              );
            },
          ),
          // Floating sticky cart bar
          if (cartItems.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: 20,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: const StickyCartBar(bottomOffset: 0),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- DESKTOP SIDE-BY-SIDE LAYOUT ---
  Widget _buildDesktopLayout(
    BuildContext context,
    WidgetRef ref,
    int quantityInCart,
    List<Product> relatedProducts,
  ) {
    final currencyFormat = NumberFormat('#,##0');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 120),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Breadcrumb
              Row(
                children: [
                  InkWell(
                    onTap: () => context.go('/home'),
                    child: Text(
                      'Home',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.grey[600],
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 16, color: Colors.grey[400]),
                  Text(
                    product.categoryName ?? 'Produce',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.grey[600],
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 16, color: Colors.grey[400]),
                  Text(
                    product.name,
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF2E7D32),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Side-by-side main container
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LEFT SIDE (60%): Product Image & Main Purchase Card
                  Expanded(
                    flex: 6,
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE8ECE8)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Product Image
                              SizedBox(
                                width: 300,
                                height: 300,
                                child: Hero(
                                  tag: 'product-${product.id}',
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF7FAF7),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: const Color(0xFFE5E4DC)),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: _buildProductImage(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 28),

                              // Key details column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '100% Fresh Farm Harvest',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF2E7D32),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      product.name,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFF1B3D25),
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          'UGX ${currencyFormat.format(product.price)}',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w900,
                                            color: const Color(0xFF2E7D32),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '/ ${product.unit}',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
                                            color: const Color(0xFF7A7F7A),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),

                                    // Quantity selector & Add to cart
                                    Row(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(color: const Color(0xFFE0E0E0)),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.remove, size: 18),
                                                onPressed: quantityInCart > 0
                                                    ? () => ref
                                                        .read(cartProvider.notifier)
                                                        .decrementItem(product.id)
                                                    : null,
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                                child: Text(
                                                  '$quantityInCart',
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.add, size: 18),
                                                onPressed: () => ref
                                                    .read(cartProvider.notifier)
                                                    .addItem(product),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: _buildAddToCartButton(context, ref),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),

                                    // Perks info
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF9FAF8),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFE8ECE8)),
                                      ),
                                      child: Column(
                                        children: [
                                          _buildPerkRow(
                                            Icons.electric_bolt,
                                            'Fast delivery within 30-45 mins in Kampala & Entebbe',
                                          ),
                                          const SizedBox(height: 8),
                                          _buildPerkRow(
                                            Icons.verified_outlined,
                                            'Hand-picked daily from local farmers for peak freshness',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 40),
                          Text(
                            'About this Produce',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1B3D25),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            product.description.isEmpty
                                ? 'Fresh and naturally sourced ${product.name} directly from farm to your kitchen.'
                                : product.description,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              height: 1.6,
                              color: const Color(0xFF4A4E4A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 28),

                  // RIGHT SIDE (40%): Related Products Panel
                  Expanded(
                    flex: 4,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE8ECE8)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Related Fresh Picks',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1B3D25),
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.push('/all-products'),
                                child: Text(
                                  'See All',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2E7D32),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (relatedProducts.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: Text(
                                  'No other items in this category.',
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: relatedProducts.length,
                              separatorBuilder: (_, __) => const Divider(height: 20),
                              itemBuilder: (context, index) {
                                final item = relatedProducts[index];
                                return _RelatedProductRow(product: item);
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- MOBILE LAYOUT ---
  Widget _buildMobileLayout(
    BuildContext context,
    WidgetRef ref,
    int quantityInCart,
    List<Product> relatedProducts,
  ) {
    final currencyFormat = NumberFormat('#,##0');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Image
          Hero(
            tag: 'product-${product.id}',
            child: AspectRatio(
              aspectRatio: 1.15,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E4DC)),
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildProductImage(),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title & Price Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF1B3D25),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Local Organic Fresh Produce',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF2E7D32),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'UGX ${currencyFormat.format(product.price)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                  Text(
                    product.unit,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF7A7F7A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Description
          Text(
            'Description',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1B3D25),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.description.isEmpty
                ? 'Fresh and naturally sourced ${product.name} directly from farm to your kitchen.'
                : product.description,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              height: 1.5,
              color: const Color(0xFF4A4E4A),
            ),
          ),
          const SizedBox(height: 24),

          _buildAddToCartButton(context, ref),
          const SizedBox(height: 32),

          // Related products on mobile (horizontal list)
          if (relatedProducts.isNotEmpty) ...[
            Text(
              'You Might Also Like',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1B3D25),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 240,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: relatedProducts.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 170,
                    margin: const EdgeInsets.only(right: 12),
                    child: ProductCard(product: relatedProducts[index]),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPerkRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF2E7D32)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF4A4E4A),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductImage() {
    final url = product.imageUrl.trim();

    if (url.isEmpty) {
      return Container(
        color: const Color(0xFFF1F8F1),
        child: const Center(
          child: Icon(
            Icons.shopping_basket_outlined,
            size: 64,
            color: Color(0xFFA5D6A7),
          ),
        ),
      );
    }

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: const Color(0xFFF1F8F1),
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: const Color(0xFFF1F8F1),
          child: const Center(
            child: Icon(Icons.broken_image, size: 64, color: Color(0xFFA5D6A7)),
          ),
        ),
      );
    }

    return Image.asset(url, fit: BoxFit.cover);
  }

  Widget _buildAddToCartButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 52,
      child: FilledButton.icon(
        onPressed: () {
          ref.read(cartProvider.notifier).addItem(product);
        },
        icon: const Icon(Icons.add_shopping_cart, size: 20),
        label: Text(
          'Add to Cart',
          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

class _RelatedProductRow extends ConsumerWidget {
  final Product product;
  const _RelatedProductRow({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat('#,##0');

    return InkWell(
      onTap: () {
        context.pushReplacement('/product-detail', extra: product);
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAF7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E4DC)),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildThumb(product.imageUrl),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1B3D25),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'UGX ${currencyFormat.format(product.price)} / ${product.unit}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Color(0xFF2E7D32), size: 28),
              tooltip: 'Add to cart',
              onPressed: () {
                ref.read(cartProvider.notifier).addItem(product);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumb(String url) {
    if (url.isEmpty) {
      return const Icon(Icons.shopping_basket_outlined, color: Colors.grey, size: 24);
    }
    if (url.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 24),
      );
    }
    return Image.asset(url, fit: BoxFit.cover);
  }
}
