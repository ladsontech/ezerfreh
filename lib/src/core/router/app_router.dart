import 'package:ezer_fresh/src/presentation/features/auth/views/login_screen.dart';
import 'package:ezer_fresh/src/presentation/features/auth/views/signup_screen.dart';
import 'package:ezer_fresh/src/presentation/features/home/views/home_screen.dart';
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      name: 'signup',
      builder: (context, state) => const SignupScreen(),
    ),
  ],
);
