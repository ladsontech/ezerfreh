import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ezer_fresh/src/core/providers/providers.dart';
import 'package:ezer_fresh/src/presentation/widgets/sticky_cart_bar.dart';
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
    final role = ref.watch(userRoleProvider).value;
    final isWide = MediaQuery.sizeOf(context).width >= 800;
    final destinations = _getDestinations(role ?? 'customer');
    final brandColor = _getBrandColor(role ?? 'customer');

    final cartItems = ref.watch(cartProvider);
    final hasCartItems = cartItems.isNotEmpty;
    final showStickyCart = (role ?? 'customer') == 'customer' &&
        navigationShell.currentIndex != 1 &&
        hasCartItems;

    Widget mobileBody = navigationShell;
    if (showStickyCart) {
      mobileBody = Stack(
        children: [
          navigationShell,
          const Positioned(
            left: 16,
            right: 16,
            bottom: 96,
            child: StickyCartBar(bottomOffset: 0),
          ),
        ],
      );
    }

    Widget desktopBody = navigationShell;
    if (showStickyCart) {
      desktopBody = Stack(
        children: [
          navigationShell,
          const Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: StickyCartBar(bottomOffset: 0),
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
              role: role ?? 'customer',
            ),
            Expanded(child: desktopBody),
          ],
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      body: mobileBody,
      bottomNavigationBar: _AnimatedBottomBar(
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
      default:
        return const Color(0xFF2E7D32);
    }
  }

  List<_NavItem> _getDestinations(String role) {
    if (role == 'admin') {
      return [
        const _NavItem(icon: Icons.grid_view_outlined, selectedIcon: Icons.grid_view_rounded, label: 'Dashboard'),
        const _NavItem(icon: Icons.inventory_2_outlined, selectedIcon: Icons.inventory_2, label: 'Products'),
        const _NavItem(icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long, label: 'Orders'),
        const _NavItem(icon: Icons.people_outline, selectedIcon: Icons.people, label: 'Users'),
        const _NavItem(icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profile'),
      ];
    } else if (role == 'rider') {
      return [
        const _NavItem(icon: Icons.delivery_dining_outlined, selectedIcon: Icons.delivery_dining, label: 'Deliveries'),
        const _NavItem(icon: Icons.history_outlined, selectedIcon: Icons.history, label: 'History'),
        const _NavItem(icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profile'),
      ];
    } else {
      return [
        const _NavItem(icon: Icons.home_outlined, selectedIcon: Icons.home_rounded, label: 'Home'),
        const _NavItem(icon: Icons.shopping_cart_outlined, selectedIcon: Icons.shopping_cart, label: 'Cart'),
        const _NavItem(icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long, label: 'Orders'),
        const _NavItem(icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profile'),
      ];
    }
  }
}

// ─── Premium Animated Bottom Bar ────────────────────────────────────────────

class _AnimatedBottomBar extends StatelessWidget {
  final List<_NavItem> destinations;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final Color brandColor;

  const _AnimatedBottomBar({
    required this.destinations,
    required this.selectedIndex,
    required this.onTap,
    required this.brandColor,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = destinations.length > 4;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: brandColor.withValues(alpha: 0.08),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(destinations.length, (index) {
                return _AnimatedNavItem(
                  item: destinations[index],
                  isSelected: selectedIndex == index,
                  brandColor: brandColor,
                  onTap: () => onTap(index),
                  isCompact: isCompact,
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedNavItem extends ConsumerWidget {
  final _NavItem item;
  final bool isSelected;
  final Color brandColor;
  final VoidCallback onTap;
  final bool isCompact;

  const _AnimatedNavItem({
    required this.item,
    required this.isSelected,
    required this.brandColor,
    required this.onTap,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final cartCount = cartItems.fold<int>(0, (sum, i) => sum + i.quantity);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected 
              ? (isCompact ? 12 : 18) 
              : (isCompact ? 8 : 14),
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? brandColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedScale(
                  scale: isSelected ? 1.15 : 1.0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutBack,
                  child: Icon(
                    isSelected ? item.selectedIcon : item.icon,
                    color: isSelected ? brandColor : const Color(0xFFB0B0B0),
                    size: isCompact ? 22 : 24,
                  ),
                ),
                if (item.label == 'Cart' && cartCount > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          '$cartCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              child: isSelected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        item.label,
                        style: GoogleFonts.lato(
                          color: brandColor,
                          fontSize: isCompact ? 11.5 : 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Desktop Side Rail ──────────────────────────────────────────────────────

class _DesktopSideRail extends StatelessWidget {
  final List<_NavItem> destinations;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final Color brandColor;
  final String role;

  const _DesktopSideRail({
    required this.destinations,
    required this.selectedIndex,
    required this.onTap,
    required this.brandColor,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey.shade100),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          SafeArea(
            bottom: false,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [brandColor, brandColor.withValues(alpha: 0.7)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  'EF',
                  style: GoogleFonts.lato(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ...List.generate(destinations.length, (index) {
            final item = destinations[index];
            final isSelected = selectedIndex == index;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: _DesktopNavButton(
                item: item,
                isSelected: isSelected,
                brandColor: brandColor,
                onTap: () => onTap(index),
              ),
            );
          }),
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
    final cartCount = cartItems.fold<int>(0, (sum, i) => sum + i.quantity);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 56,
          height: 52,
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.brandColor.withValues(alpha: 0.1)
                : (_isHovered ? Colors.grey.shade50 : Colors.transparent),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    widget.isSelected ? widget.item.selectedIcon : widget.item.icon,
                    color: widget.isSelected
                        ? widget.brandColor
                        : (_isHovered ? Colors.black54 : const Color(0xFFB0B0B0)),
                    size: 22,
                  ),
                  if (widget.item.label == 'Cart' && cartCount > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Center(
                          child: Text(
                            '$cartCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                widget.item.label,
                style: GoogleFonts.lato(
                  fontSize: 9,
                  fontWeight: widget.isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: widget.isSelected
                      ? widget.brandColor
                      : (_isHovered ? Colors.black54 : const Color(0xFFB0B0B0)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Nav Item Model ─────────────────────────────────────────────────────────

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
