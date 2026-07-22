import 'package:ezer_fresh/src/core/providers/providers.dart';
import 'dart:async';
import 'package:ezer_fresh/src/core/providers/category_provider.dart';
import 'package:ezer_fresh/src/core/providers/product_provider.dart';
import 'package:ezer_fresh/src/presentation/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ezer_fresh/src/presentation/widgets/responsive_layout.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F4),
      body: RefreshIndicator(
        onRefresh: () async {
          await refreshProductsCatalog(ref);
          ref.invalidate(categoriesProvider);
        },
        child: CustomScrollView(
          slivers: [
            _buildTopBar(context),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildSearchBar(ref),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            if (searchQuery.isNotEmpty)
              _buildSearchResults(context, ref, searchQuery)
            else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPromoBanner(),
                      const SizedBox(height: 24),
                      _buildSectionHeader('Categories'),
                      const SizedBox(height: 16),
                      _buildCategoryList(context, categories),
                      const SizedBox(height: 24),
                      _buildSectionHeader(
                        'Flash Sales',
                        () => context.push('/all-products'),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              _buildFeaturedProductsGrid(context, ref, '1'),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildSectionHeader(
                    'All Products',
                    () => context.push('/all-products'),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              _buildFeaturedProductsGrid(context, ref, '2'),
              SliverPadding(
                padding: EdgeInsets.only(
                  bottom: ref.watch(cartProvider).isNotEmpty ? 180.0 : 32.0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(
    BuildContext context,
    WidgetRef ref,
    String query,
  ) {
    final productsAsync = ref.watch(allProductsProvider);

    return productsAsync.when(
      data: (products) {
        final filtered = products
            .where(
              (p) =>
                  p.name.toLowerCase().contains(query.toLowerCase()) ||
                  p.description.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();

        if (filtered.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No matches for "$query"',
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

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 0.68,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => ProductCard(product: filtered[index]),
              childCount: filtered.length,
            ),
          ),
        );
      },
      loading: () => const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, __) =>
          SliverFillRemaining(child: Center(child: Text('Error: $e'))),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      pinned: false,
      backgroundColor: const Color(0xFFFAF9F4),
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 80,
      flexibleSpace: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => context.push('/create-profile'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Location',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0xFF7A7F7A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Color(0xFF2E7D32),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Consumer(
                              builder: (context, ref, child) {
                                final authAsync = ref.watch(authStateProvider);
                                return authAsync.when(
                                  data: (user) {
                                    if (user == null) {
                                      return const Text('Select Location');
                                    }
                                    final profileAsync = ref.watch(
                                      userProfileProvider(user.uid),
                                    );
                                    return profileAsync.when(
                                      data: (doc) {
                                        final data =
                                            doc.data() as Map<String, dynamic>?;
                                        final address =
                                            data?['address'] as String?;
                                        final suite =
                                            data?['apartmentSuite'] as String?;
                                        final displayAddress =
                                            (address != null &&
                                                suite != null &&
                                                suite.isNotEmpty)
                                            ? '$address ($suite)'
                                            : (address ?? 'Select Location');
                                        return Text(
                                          displayAddress,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
                                            color: const Color(0xFF1B3D25),
                                            fontWeight: FontWeight.w800,
                                          ),
                                        );
                                      },
                                      loading: () => const SizedBox(
                                        height: 15,
                                        width: 15,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      error: (_, __) => const Text('Error'),
                                    );
                                  },
                                  loading: () => const SizedBox(
                                    height: 15,
                                    width: 15,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  error: (_, __) => const Text('Error'),
                                );
                              },
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.grey,
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.notifications_none,
                  color: Colors.black87,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E4DC)),
            ),
            child: TextField(
              onChanged: (value) =>
                  ref.read(searchQueryProvider.notifier).query = value,
              decoration: InputDecoration(
                hintText: 'Search vegetables, fruits, etc',
                hintStyle: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF8A8F8A),
                  fontSize: 14,
                ),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF8A8F8A)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          height: 52,
          width: 52,
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.tune, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildPromoBanner() {
    return const _BannerCarousel();
  }

  Widget _buildSectionHeader(String title, [VoidCallback? onSeeAll]) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF1B3D25),
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: Text(
              'See All',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF2E7D32),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryList(BuildContext context, categories) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return GestureDetector(
            onTap: () => context.push('/products', extra: category),
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                children: [
                  Container(
                    height: 64,
                    width: 64,
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF0EEE4),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      category.imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.category_outlined,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4A4E4A),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedProductsGrid(
    BuildContext context,
    WidgetRef ref,
    String categoryId,
  ) {
    final productsAsyncValue = ref.watch(productsProvider(categoryId));

    return productsAsyncValue.when(
      data: (products) {
        if (products.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox());
        }
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: ResponsiveLayout.isDesktop(context) ? 4 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.68,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => ProductCard(product: products[index]),
              childCount: products.length > 4 ? 4 : products.length,
            ),
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, s) => const SliverToBoxAdapter(child: SizedBox()),
    );
  }
}

class _BannerCarousel extends StatefulWidget {
  const _BannerCarousel();

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  late final Timer _timer;

  final List<String> _banners = [
    'assets/banners/vegetables_banner.png',
    'assets/banners/fruits_banner.png',
    'assets/banners/spices_banner (1).png',
    'assets/banners/delivery_banner.png',
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_currentIndex < _banners.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemCount: _banners.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  image: DecorationImage(
                    image: AssetImage(_banners[index]),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _banners.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: _currentIndex == index ? 24 : 6,
              decoration: BoxDecoration(
                color: _currentIndex == index
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFE5E4DC),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
