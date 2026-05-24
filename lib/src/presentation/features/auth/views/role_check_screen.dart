import 'package:flutter/material.dart';
import 'package:myapp/src/presentation/features/admin/views/admin_login_screen.dart';
import 'package:myapp/src/presentation/features/admin/views/admin_screen.dart';
import 'package:myapp/src/presentation/features/home/views/home_screen.dart';
import 'package:myapp/src/presentation/features/rider/views/rider_screen.dart';

class RoleCheckScreen extends StatefulWidget {
  const RoleCheckScreen({super.key});

  @override
  _RoleCheckScreenState createState() => _RoleCheckScreenState();
}

class _RoleCheckScreenState extends State<RoleCheckScreen> {
  String _userRole = 'user'; // Default role
  bool _isAdminLoggedIn = false;

  // In a real app, you would fetch this from your database
  Future<String> _getUserRole(String email) async {
    if (email == 'admin@example.com') {
      return 'admin';
    } else if (email == 'rider@example.com') {
      return 'rider';
    } else {
      return 'user';
    }
  }

  void _handleLogin(String email) async {
    final role = await _getUserRole(email);
    if (role == 'admin') {
      setState(() {
        _isAdminLoggedIn = true;
      });
    } else {
      // Handle non-admin login if necessary
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userRole == 'admin' && !_isAdminLoggedIn) {
      return AdminLoginScreen(onLogin: _handleLogin);
    }

    switch (_userRole) {
      case 'admin':
        return const AdminScreen();
      case 'rider':
        return const RiderScreen();
      default:
        return const HomeScreen();
    }
  }
}
