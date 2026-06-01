import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ezer_fresh/src/core/providers/providers.dart';
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

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _onTap,
              labelType: NavigationRailLabelType.all,
              backgroundColor: Colors.white,
              indicatorColor: const Color(0xFFE8F5E9),
              selectedIconTheme: const IconThemeData(color: Color(0xFF2E7D32)),
              selectedLabelTextStyle: GoogleFonts.lato(
                color: const Color(0xFF2E7D32),
                fontWeight: FontWeight.bold,
              ),
              destinations: destinations
                  .map(
                    (d) => NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: Text(d.label),
                    ),
                  )
                  .toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1, color: Color(0xFFF0F0F0)),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      extendBody: true, // Crucial for floating nav effect
      body: navigationShell,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32).withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(destinations.length, (index) {
              final item = destinations[index];
              final isSelected = navigationShell.currentIndex == index;
              return _buildNavItem(index, item, isSelected);
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, _NavItem item, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF2E7D32).withOpacity(0.1)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSelected ? item.selectedIcon : item.icon,
                  color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[400],
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: GoogleFonts.lato(
                color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[400],
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
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

