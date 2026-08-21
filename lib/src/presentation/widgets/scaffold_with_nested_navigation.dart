import 'package:ezer_fresh/src/core/providers/providers.dart';
import 'package:ezer_fresh/src/presentation/widgets/sticky_cart_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class ScaffoldWithNestedNavigation extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNestedNavigation({
    super.key,
    required this.navigationShell,
  });

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userRoleProvider).value ?? 'customer';
    final isWide = MediaQuery.sizeOf(context).width >= 800;
    final destinations = _getDestinations(role);
    final brandColor = _getBrandColor(role);

    final cartItems = ref.watch(cartProvider);
    final hasCartItems = cartItems.isNotEmpty;
    final showStickyCart =
        role == 'customer' && navigationShell.currentIndex != 1 && hasCartItems;

    Widget body = navigationShell;
    if (showStickyCart) {
      body = Stack(
        children: [
          navigationShell,
          Positioned(
            left: isWide ? 20 : 16,
            right: isWide ? 20 : 16,
            bottom: isWide ? 20 : 84,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: const StickyCartBar(bottomOffset: 0),
              ),
            ),
          ),
        ],
      );
    }

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            _DesktopSideRail(
              destinations: destinations,
              selectedIndex: navigationShell.currentIndex,
              onTap: _onTap,
              brandColor: brandColor,
            ),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: _FixedBottomBar(
        destinations: destinations,
        selectedIndex: navigationShell.currentIndex,
        onTap: _onTap,
        brandColor: brandColor,
      ),
    );
  }

  Color _getBrandColor(String role) {
    switch (role) {
      case 'admin':
        return const Color(0xFF2E7D32);
      case 'rider':
        return const Color(0xFF00B894);
      case 'guest':
        return const Color(0xFF0984E3);
      default:
        return const Color(0xFF2E7D32);
    }
  }

  List<_NavItem> _getDestinations(String role) {
    if (role == 'admin') {
      return const [
        _NavItem(
          icon: Icons.grid_view_outlined,
          selectedIcon: Icons.grid_view_rounded,
          label: 'Dashboard',
        ),
        _NavItem(
          icon: Icons.inventory_2_outlined,
          selectedIcon: Icons.inventory_2,
          label: 'Products',
        ),
        _NavItem(
          icon: Icons.person_outline,
          selectedIcon: Icons.person,
          label: 'Profile',
        ),
      ];
    }

    if (role == 'rider') {
      return const [
        _NavItem(
          icon: Icons.delivery_dining_outlined,
          selectedIcon: Icons.delivery_dining,
          label: 'Deliveries',
        ),
        _NavItem(
          icon: Icons.history_outlined,
          selectedIcon: Icons.history,
          label: 'History',
        ),
        _NavItem(
          icon: Icons.person_outline,
          selectedIcon: Icons.person,
          label: 'Profile',
        ),
      ];
    }

    return const [
      _NavItem(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        label: 'Home',
      ),
      _NavItem(
        icon: Icons.shopping_cart_outlined,
        selectedIcon: Icons.shopping_cart,
        label: 'Cart',
      ),
      _NavItem(
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long,
        label: 'Orders',
      ),
      _NavItem(
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
        label: 'Profile',
      ),
    ];
  }
}

class _FixedBottomBar extends StatelessWidget {
  final List<_NavItem> destinations;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final Color brandColor;

  const _FixedBottomBar({
    required this.destinations,
    required this.selectedIndex,
    required this.onTap,
    required this.brandColor,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: List.generate(destinations.length, (index) {
              return Expanded(
                child: _FixedNavItem(
                  item: destinations[index],
                  isSelected: selectedIndex == index,
                  brandColor: brandColor,
                  onTap: () => onTap(index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _FixedNavItem extends ConsumerWidget {
  final _NavItem item;
  final bool isSelected;
  final Color brandColor;
  final VoidCallback onTap;

  const _FixedNavItem({
    required this.item,
    required this.isSelected,
    required this.brandColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final cartCount = cartItems.fold<int>(0, (sum, item) => sum + item.quantity);
    final iconColor = isSelected ? brandColor : const Color(0xFF7A7F7A);

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: isSelected ? brandColor : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isSelected ? item.selectedIcon : item.icon,
                    color: iconColor,
                    size: 23,
                  ),
                  if (item.label == 'Cart' && cartCount > 0)
                    Positioned(
                      right: -7,
                      top: -7,
                      child: _CartBadge(count: cartCount),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.lato(
                  color: iconColor,
                  fontSize: destinationsLabelSize(item.label),
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double destinationsLabelSize(String label) {
    return label.length > 9 ? 10 : 11;
  }
}

class _CartBadge extends StatelessWidget {
  final int count;

  const _CartBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: const BoxDecoration(
        color: Color(0xFFFF3B30),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          count > 99 ? '99+' : '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _DesktopSideRail extends ConsumerWidget {
  final List<_NavItem> destinations;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final Color brandColor;

  const _DesktopSideRail({
    required this.destinations,
    required this.selectedIndex,
    required this.onTap,
    required this.brandColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);
    final user = userAsync.value;
    final role = ref.watch(userRoleProvider).value ?? 'customer';

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: const Color(0xFFE8ECE8)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Brand Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.eco_rounded, color: Colors.white, size: 26),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Ezer Fresh',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1B3D25),
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        role == 'admin' ? 'Admin Portal' : (role == 'rider' ? 'Rider App' : 'Farm Direct'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F3F0)),
          const SizedBox(height: 14),

          // Menu Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: destinations.length,
              itemBuilder: (context, index) {
                return _DesktopNavButton(
                  item: destinations[index],
                  isSelected: selectedIndex == index,
                  brandColor: brandColor,
                  onTap: () => onTap(index),
                );
              },
            ),
          ),

          // Bottom Section
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAF7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8ECE8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (user != null) ...[
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFF2E7D32),
                        child: Text(
                          (user.displayName?.isNotEmpty == true
                                  ? user.displayName![0]
                                  : (user.phoneNumber?.isNotEmpty == true ? user.phoneNumber![0] : 'U'))
                              .toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName ?? 'Customer',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1B3D25),
                              ),
                            ),
                            Text(
                              role.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      const Icon(Icons.flash_on, color: Color(0xFF2E7D32), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '30-45m Delivery',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1B3D25),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kampala & Entebbe Express',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      color: const Color(0xFF7A7F7A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopNavButton extends ConsumerStatefulWidget {
  final _NavItem item;
  final bool isSelected;
  final Color brandColor;
  final VoidCallback onTap;

  const _DesktopNavButton({
    required this.item,
    required this.isSelected,
    required this.brandColor,
    required this.onTap,
  });

  @override
  ConsumerState<_DesktopNavButton> createState() => _DesktopNavButtonState();
}

class _DesktopNavButtonState extends ConsumerState<_DesktopNavButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final cartCount = cartItems.fold<int>(0, (sum, item) => sum + item.quantity);

    final isSelected = widget.isSelected;
    final activeBg = isSelected
        ? const Color(0xFFE8F5E9)
        : (_isHovered ? const Color(0xFFF7FAF7) : Colors.transparent);
    final activeColor = isSelected
        ? const Color(0xFF2E7D32)
        : (_isHovered ? const Color(0xFF1B3D25) : const Color(0xFF5A605A));

    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: activeBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? const Color(0xFFC8E6C9) : Colors.transparent,
            ),
          ),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    isSelected ? widget.item.selectedIcon : widget.item.icon,
                    color: activeColor,
                    size: 22,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.item.label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: activeColor,
                      ),
                    ),
                  ),
                  if (widget.item.label == 'Cart' && cartCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$cartCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else if (isSelected)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2E7D32),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

