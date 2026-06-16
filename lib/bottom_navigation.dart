import 'package:flutter/material.dart';
import 'package:ezer_fresh/src/presentation/features/admin/views/admin_dashboard_view.dart';
import 'package:ezer_fresh/src/presentation/features/admin/views/admin_orders_screen.dart';
import 'package:ezer_fresh/src/presentation/features/admin/views/admin_products_list_screen.dart';
import 'package:ezer_fresh/src/presentation/features/cart/views/cart_screen.dart';
import 'package:ezer_fresh/src/presentation/features/home/views/home_screen.dart';
import 'package:ezer_fresh/src/presentation/features/orders/views/orders_screen.dart';
import 'package:ezer_fresh/src/presentation/features/profile/views/profile_screen.dart';
import 'package:ezer_fresh/src/presentation/features/rider/views/rider_dashboard_screen.dart';
import 'package:ezer_fresh/src/presentation/features/rider/views/rider_history_screen.dart';

class BottomNavigation extends StatefulWidget {
  final String userType;

  const BottomNavigation({super.key, required this.userType});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  int _selectedIndex = 0;

  List<Widget> _getScreens() {
    switch (widget.userType) {
      case 'admin':
        return [
          const AdminOverviewTab(),
          const AdminProductsListScreen(isTab: true),
          const AdminOrdersScreen(isTab: true),
          const AdminUsersTab(),
          const ProfileScreen(),
        ];
      case 'rider':
        return [
          const RiderDashboardScreen(),
          const RiderHistoryScreen(),
          const ProfileScreen(),
        ];
      default:
        return [
          const HomeScreen(),
          const CartScreen(),
          const OrdersScreen(),
          const ProfileScreen(),
        ];
    }
  }

  List<BottomNavigationBarItem> _getNavbarItems() {
    switch (widget.userType) {
      case 'admin':
        return [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Products',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ];
      case 'rider':
        return [
          const BottomNavigationBarItem(
            icon: Icon(Icons.delivery_dining),
            label: 'Deliveries',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ];
      default:
        return [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ];
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getScreens()[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 12,
        selectedItemColor: const Color(0xFF2E7D32),
        unselectedItemColor: const Color(0xFF7A7F7A),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        items: _getNavbarItems(),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
