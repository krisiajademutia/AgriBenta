import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/agribenta_scaffold.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), _checkLoginStatus);
  }

  void _checkLoginStatus() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/get-started');
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color brandGreen = Color(0xFF52B788);
    const Color harvestGold = Color(0xFFD4A574);

    return AgriBentaScaffold(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- FIXED: PREMIUM LOGO STACK ---
            Stack(
              alignment: Alignment.center,
              children: [
                // 1. Outer Ring (Gold/Green Tint)
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: harvestGold.withOpacity(0.3), width: 2),
                    color: harvestGold.withOpacity(0.1),
                  ),
                ),
                // 2. Gradient Middle Ring
                Container(
                  width: 140,
                  height: 140,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFD4A574), // Gold
                        Color(0xFF52B788), // Green
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: brandGreen.withOpacity(0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  // 3. Inner White Circle background
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                ),
                // 4. The Icon
                ClipOval(
                  child: Container(
                    width: 110,
                    height: 110,
                    padding: const EdgeInsets.all(18),
                    color: Colors.transparent,
                    child: Image.asset(
                      'assets/icons/livestock.png',
                      color: const Color(0xFF40916C), // Dark Green Icon
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
            // ---------------------------------

            const SizedBox(height: 30),

            // Loading Indicator
            const CircularProgressIndicator(color: brandGreen),
          ],
        ),
      ),
    );
  }
}
