import 'package:flutter/material.dart';
import 'package:ezer_fresh/src/presentation/features/admin/views/admin_screen.dart';
import 'package:ezer_fresh/src/presentation/features/home/views/home_screen.dart';
import 'package:ezer_fresh/src/presentation/features/rider/views/rider_screen.dart';

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
          const AdminScreen(),
          const Center(child: Text('Placeholder Screen 1')),
          const Center(child: Text('Placeholder Screen 2')),
        ];
      case 'rider':
        return [
          const RiderScreen(),
          const Center(child: Text('Placeholder Screen 1')),
          const Center(child: Text('Placeholder Screen 2')),
        ];
      default:
        return [
          const HomeScreen(),
          const Center(child: Text('Placeholder Screen 1')),
          const Center(child: Text('Placeholder Screen 2')),
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
            icon: Icon(Icons.settings),
            label: 'Settings',
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
