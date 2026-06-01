import 'package:ezer_fresh/src/core/router/app_router.dart';
import 'package:ezer_fresh/src/core/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ezer_fresh/firebase_options.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Initialize Push Notifications
  await NotificationService().initialize();
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    final lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      textTheme: GoogleFonts.latoTextTheme(textTheme).copyWith(
        displayLarge: GoogleFonts.oswald(
          fontSize: 57,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.bold),
        bodyMedium: GoogleFonts.lato(fontSize: 14),
        bodySmall: GoogleFonts.lato(fontSize: 12),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.lato(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      cardTheme: CardThemeData(
        elevation: 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),
    );

    final appRouter = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Ezer Fresh',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      routerConfig: appRouter,
    );
  }
}

