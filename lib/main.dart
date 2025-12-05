import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import 'screens/get_started_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'services/profile_manager.dart'; 
import 'services/livestock_manager.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp();

  // Firestore offline support
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // 3. 🎯 CRITICAL CHANGE: Use MultiProvider
  runApp(
    // MultiProvider allows you to register more than one ChangeNotifier
    MultiProvider(
      providers: [
        // Register the Profile Manager
        ChangeNotifierProvider(create: (_) => ProfileManager()), 
        // Register the new Livestock Manager
        ChangeNotifierProvider(create: (_) => LivestockManager()), 
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E8B57),
          primary: const Color(0xFF2E8B57),
          secondary: const Color(0xFF1A5F3A),
          surface: const Color(0xFFF5F5DC),
          background: const Color(0xFFF5F5DC),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5DC),
      ),
      home: const GetStartedScreen(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/home': (_) => const HomeScreen(),
      },
    );
  } 
}