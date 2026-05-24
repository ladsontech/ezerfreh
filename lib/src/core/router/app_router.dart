import 'package:ezer_fresh/src/domain/models/category_model.dart';
import 'package:ezer_fresh/src/presentation/features/auth/views/login_screen.dart';
import 'package:ezer_fresh/src/presentation/features/cart/views/cart_screen.dart';
import 'package:ezer_fresh/src/presentation/features/home/views/home_screen.dart';
import 'package:ezer_fresh/src/presentation/features/orders/views/orders_screen.dart';
import 'package:ezer_fresh/src/presentation/features/products/views/product_list_screen.dart';
import 'package:ezer_fresh/src/presentation/features/profile/views/create_profile_screen.dart';
import 'package:ezer_fresh/src/presentation/features/profile/views/profile_screen.dart';
import 'package:ezer_fresh/src/presentation/widgets/scaffold_with_nested_navigation.dart';
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => ScaffoldWithNestedNavigation(child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/cart',
          builder: (context, state) => const CartScreen(),
        ),
        GoRoute(
          path: '/orders',
          builder: (context, state) => const OrdersScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/products',
      builder: (context, state) {
        final category = state.extra as Category;
        return ProductListScreen(category: category);
      },
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/create-profile',
      builder: (context, state) => const CreateProfileScreen(),
    )
  ],
);
