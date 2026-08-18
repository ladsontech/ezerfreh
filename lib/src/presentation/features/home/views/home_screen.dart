import 'package:ezer_fresh/src/core/providers/providers.dart';
import 'dart:async';
import 'package:ezer_fresh/src/core/providers/category_provider.dart';
import 'package:ezer_fresh/src/core/providers/product_provider.dart';
import 'package:ezer_fresh/src/core/services/location_service.dart';
import 'package:ezer_fresh/src/presentation/widgets/location_picker.dart';
import 'package:ezer_fresh/src/presentation/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
                padding: ResponsiveLayout.pagePadding(context),
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
                  padding: ResponsiveLayout.pagePadding(context),
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
                  padding: ResponsiveLayout.pagePadding(context),
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
          padding: ResponsiveLayout.pagePadding(context),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: ResponsiveLayout.productGridColumns(
                MediaQuery.sizeOf(context).width,
              ),
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 0.60,
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
          padding: ResponsiveLayout.pagePadding(
            context,
          ).add(const EdgeInsets.symmetric(vertical: 8.0)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(child: _LocationBar()),
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
        final columns = ResponsiveLayout.productGridColumns(
          MediaQuery.sizeOf(context).width,
        );
        return SliverPadding(
          padding: ResponsiveLayout.pagePadding(context),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              // Matches the fix in product_list_screen.dart — ProductCard's
              // image is now a square, so this needs the same extra
              // headroom to avoid a bottom overflow.
              childAspectRatio: 0.60,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => ProductCard(product: products[index]),
              // Show one full row on wide/web layouts (more columns) so the
              // "Flash Sales" preview doesn't look sparse next to "See All".
              childCount: products.length > columns
                  ? columns
                  : products.length,
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

/// Delivery location shown in the home top bar. Tapping it opens the same
/// map picker used at checkout and writes the chosen address straight back
/// to the user's profile, so the address can be changed from the home page
/// instead of only inside profile settings.
///
/// The previous version pushed `/create-profile` with no `?edit=true`, which
/// the router's redirect bounced straight back to `/home` — so tapping the
/// location appeared to do nothing at all.
class _LocationBar extends ConsumerWidget {
  const _LocationBar();

  Future<void> _editLocation(
    BuildContext context,
    WidgetRef ref,
    String uid,
    Map<String, dynamic>? profile,
  ) async {
    final savedAddress = (profile?['address'] as String?)?.trim() ?? '';
    final savedSuite = (profile?['apartmentSuite'] as String?)?.trim() ?? '';
    final savedLat = (profile?['latitude'] as num?)?.toDouble();
    final savedLng = (profile?['longitude'] as num?)?.toDouble();

    final picked = await showModalBottomSheet<_PickedLocation>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Container(
          height: MediaQuery.sizeOf(sheetContext).height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: LocationPicker(
            initialAddress: savedAddress.isNotEmpty ? savedAddress : null,
            initialLatLng: (savedLat != null && savedLng != null)
                ? LatLng(savedLat, savedLng)
                : null,
            initialApartmentSuite: savedSuite.isNotEmpty ? savedSuite : null,
            confirmButtonLabel: 'Save Address',
            onLocationSelected: (latLng, address, apartmentSuite) {
              Navigator.of(sheetContext).pop(
                _PickedLocation(latLng, address, apartmentSuite),
              );
            },
          ),
        ),
      ),
    );

    if (picked == null) return;

    // Merge onto the existing profile rather than writing only the four
    // location keys. FirestoreService mirrors whatever map it's handed into
    // the local cache wholesale, so a partial write would leave a cached
    // profile with no name/contact/role on it.
    final merged = Map<String, dynamic>.from(profile ?? <String, dynamic>{})
      ..['address'] = picked.address
      ..['apartmentSuite'] = picked.apartmentSuite
      ..['latitude'] = picked.latLng.latitude
      ..['longitude'] = picked.latLng.longitude;

    try {
      await ref.read(firestoreServiceProvider).setUserProfile(uid, merged);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery address updated.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save address: $error')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;

    // Guests have no profile to save an address onto, so send them to sign
    // in rather than opening a picker whose result would be discarded.
    if (user == null) {
      return _LocationBarShell(
        value: 'Sign in to set address',
        onTap: () => context.push('/login'),
      );
    }

    final profileAsync = ref.watch(userProfileProvider(user.uid));
    final profile = profileAsync.value?.data() as Map<String, dynamic>?;

    final address = LocationService.tidyAddress(
      (profile?['address'] as String?)?.trim() ?? '',
    );
    final suite = (profile?['apartmentSuite'] as String?)?.trim() ?? '';
    final display = address.isEmpty
        ? 'Set delivery address'
        : (suite.isEmpty ? address : '$address ($suite)');

    return _LocationBarShell(
      value: display,
      loading: profileAsync.isLoading && profile == null,
      onTap: () => _editLocation(context, ref, user.uid, profile),
    );
  }
}

class _PickedLocation {
  final LatLng latLng;
  final String address;
  final String apartmentSuite;

  const _PickedLocation(this.latLng, this.address, this.apartmentSuite);
}

class _LocationBarShell extends StatelessWidget {
  final String value;
  final bool loading;
  final VoidCallback onTap;

  const _LocationBarShell({
    required this.value,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
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
                  child: loading
                      ? const Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            height: 15,
                            width: 15,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: const Color(0xFF1B3D25),
                            fontWeight: FontWeight.w800,
                          ),
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
