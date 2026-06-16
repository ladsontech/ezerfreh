import 'package:ezer_fresh/src/core/providers/providers.dart';
import 'package:ezer_fresh/src/domain/models/category_model.dart';
import 'package:ezer_fresh/src/presentation/features/auth/views/login_screen.dart';
import 'package:ezer_fresh/src/presentation/features/cart/views/cart_screen.dart';
import 'package:ezer_fresh/src/presentation/features/home/views/home_screen.dart';
import 'package:ezer_fresh/src/presentation/features/orders/views/orders_screen.dart';
import 'package:ezer_fresh/src/presentation/features/products/views/product_list_screen.dart';
import 'package:ezer_fresh/src/presentation/features/profile/views/create_profile_screen.dart';
import 'package:ezer_fresh/src/presentation/features/profile/views/profile_screen.dart';
import 'package:ezer_fresh/src/domain/models/product_model.dart';
import 'package:ezer_fresh/src/presentation/features/products/views/product_detail_screen.dart';
import 'package:ezer_fresh/src/presentation/widgets/scaffold_with_nested_navigation.dart';
import 'package:ezer_fresh/src/presentation/widgets/ezer_header_scaffold.dart';
import 'package:ezer_fresh/src/presentation/features/admin/views/admin_dashboard_view.dart';
import 'package:ezer_fresh/src/presentation/features/admin/views/admin_products_list_screen.dart';
import 'package:ezer_fresh/src/presentation/features/admin/views/admin_orders_screen.dart';
import 'package:ezer_fresh/src/presentation/features/admin/views/admin_users_screen.dart';
import 'package:ezer_fresh/src/presentation/features/rider/views/rider_dashboard_screen.dart';
import 'package:ezer_fresh/src/presentation/features/rider/views/rider_history_screen.dart';
import 'package:ezer_fresh/src/presentation/features/admin/views/upload_product_screen.dart';
import 'package:ezer_fresh/src/presentation/features/onboarding/views/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
    _ref.listen(userRoleProvider, (_, __) => notifyListeners());
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final roleState = ref.read(userRoleProvider);

      final isAuth = authState.value != null;
      final isLoggingIn =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/create-profile' ||
          state.matchedLocation == '/onboarding';

      if (!isAuth && !authState.isLoading) {
        return isLoggingIn ? null : '/onboarding';
      }

      if (isAuth && (roleState.isLoading || !roleState.hasValue)) {
        return state.matchedLocation == '/' ? null : '/';
      }

      if (isAuth && roleState.hasValue) {
        final role = roleState.value;
        final loc = state.matchedLocation;

        if (loc == '/login' || loc == '/') {
          if (role == 'admin') return '/admin';
          if (role == 'rider') return '/rider';
          return '/home';
        }

        // Bound enforcement
        if (role == 'admin' &&
            !loc.startsWith('/admin') &&
            !loc.startsWith('/product-detail') &&
            !loc.startsWith('/products') &&
            loc != '/create-profile') {
          return '/admin';
        }
        if (role == 'rider' && !loc.startsWith('/rider') && loc != '/create-profile') {
          return '/rider';
        }
        if (role == 'customer' && (loc.startsWith('/admin') || loc.startsWith('/rider'))) {
          return '/home';
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: Colors.green),
          ),
        ),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/create-profile',
        builder: (context, state) => const CreateProfileScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // --- ADMIN SHELL ---
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ScaffoldWithNestedNavigation(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin',
                builder: (context, state) => const EzerHeaderScaffold(
                  title: 'Overview',
                  subtitle: 'Shop health and quick stats',
                  body: AdminOverviewTab(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/products',
                builder: (context, state) => const EzerHeaderScaffold(
                  title: 'Inventory',
                  subtitle: 'Manage and update products',
                  body: AdminProductsListScreen(isTab: true),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/profile',
                builder: (context, state) => const EzerHeaderScaffold(
                  title: 'Admin Profile',
                  subtitle: 'Global shop preferences',
                  body: ProfileScreen(),
                ),
              ),
            ],
          ),
        ],
      ),

      // --- RIDER SHELL ---
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ScaffoldWithNestedNavigation(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/rider',
                builder: (context, state) => const EzerHeaderScaffold(
                  title: 'Deliveries',
                  subtitle: 'Active routes and pending orders',
                  body: RiderDashboardScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/rider/history',
                builder: (context, state) => const EzerHeaderScaffold(
                  title: 'Trip History',
                  subtitle: 'Review your past deliveries',
                  body: RiderHistoryScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/rider/profile',
                builder: (context, state) => const EzerHeaderScaffold(
                  title: 'Rider Profile',
                  subtitle: 'Personal info and performance',
                  body: ProfileScreen(),
                ),
              ),
            ],
          ),
        ],
      ),

      // --- CUSTOMER SHELL ---
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ScaffoldWithNestedNavigation(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/orders', builder: (context, state) => const OrdersScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
            ],
          ),
        ],
      ),

      // Standalone Pages
      GoRoute(
        path: '/admin/upload',
        builder: (context, state) {
          final product = state.extra as Product?;
          return UploadProductScreen(productToEdit: product);
        },
      ),
      GoRoute(
        path: '/admin/orders',
        builder: (context, state) => const AdminOrdersScreen(isTab: false),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const AdminUsersScreen(),
      ),
      GoRoute(
        path: '/products',
        builder: (context, state) {
          final category = state.extra as Category?;
          return ProductListScreen(category: category);
        },
      ),
      GoRoute(
        path: '/product-detail',
        builder: (context, state) => ProductDetailScreen(product: state.extra as Product),
      ),
    ],
  );
});

