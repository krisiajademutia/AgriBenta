import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/agribenta_scaffold.dart';
// REMOVED: import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // REMOVED: _textAnimationController and _textAnimation
  late AnimationController _logoAnimationController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotationAnimation;

  @override
  void initState() {
    super.initState();

    // 1. LOGO ANIMATION SETUP
    _logoAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoScaleAnimation = CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.elasticOut, // Bouncy pop
    );

    _logoRotationAnimation = Tween<double>(begin: -0.05, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: Curves.easeOutBack,
      ),
    );
    // 2. START ANIMATION
    _logoAnimationController.forward();
    // 3. NAVIGATION TIMER
    Timer(const Duration(seconds: 3), _checkLoginStatus);
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    super.dispose();
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
    const Color accentGreen = Color(0xFF40916C);

    return AgriBentaScaffold(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          // ---LOGO ---
          ScaleTransition(
            scale: _logoScaleAnimation,
            child: RotationTransition(
              turns: _logoRotationAnimation,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: brandGreen.withOpacity(0.25),
                      blurRadius: 50,
                      spreadRadius: 10,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/icons/livestock.png',
                  color: accentGreen,
                  width: 200,
                  height: 600,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          const Spacer(flex: 1),

          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: brandGreen,
            ),
          ),

          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
