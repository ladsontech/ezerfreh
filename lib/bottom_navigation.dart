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
          const AdminOrdersScreen(isTab: true),
          const AdminProductsListScreen(isTab: true),
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
            icon: Icon(Icons.list),
            label: 'Orders',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Products',
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
        items: _getNavbarItems(),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
