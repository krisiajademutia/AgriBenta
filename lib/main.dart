import 'package:agribenta/screens/cart_screen.dart';
import 'package:agribenta/services/cart_manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Screens
import 'screens/get_started_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';

// Services
import 'services/profile_manager.dart';
import 'services/livestock_manager.dart';
import 'services/user_role_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Firestore offline support
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileManager()),
        ChangeNotifierProvider(create: (_) => LivestockManager()),
        ChangeNotifierProvider(create: (_) => UserRoleManager()),
        ChangeNotifierProvider(create: (_) => CartManager()),
      ],
      child: const AgriBentaApp(),
    ),
  );
}

class AgriBentaApp extends StatelessWidget {
  const AgriBentaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AgriBenta',
      theme: ThemeData(
        fontFamily: 'Poppins',
        useMaterial3: true,

        // --- UPDATED THEME TO MATCH NEW SCREENS ---
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF52B788), // Your New Brand Green
          primary: const Color(0xFF52B788),
          secondary: const Color(0xFF40916C),
          surface: const Color(0xFFF9F6F0), // Warm Cream
          background: const Color(0xFFF9F6F0),
        ),
        scaffoldBackgroundColor:
            const Color(0xFFE8F5E9), // Matches top gradient
        // ------------------------------------------
      ),

      // Start with the Splash Screen
      home: const SplashScreen(),

      routes: {
        '/get-started': (context) => const GetStartedScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/home': (_) => const HomeScreen(),
        '/cart': (_) => const CartScreen(),
      },
    );
  }
}
