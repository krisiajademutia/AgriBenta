import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/agribenta_scaffold.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // 1. Add Animation Controller
  late AnimationController _textAnimationController;
  late Animation _textAnimation;

  @override
  void initState() {
    super.initState();

    // 2. Configure the "Writing" Animation
    _textAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500), // Speed of writing
    );

    // This curve makes it start fast and slow down slightly, like natural writing
    _textAnimation = CurvedAnimation(
      parent: _textAnimationController,
      curve: Curves.easeInOutCubic,
    );

    // Start the text animation after a small delay (so the logo appears first)
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _textAnimationController.forward();
    });

    Timer(const Duration(seconds: 4), _checkLoginStatus);
  }

  @override
  void dispose() {
    _textAnimationController.dispose();
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
    const Color harvestGold = Color(0xFFD4A574);
    const Color darkGreen = Color(0xFF2D6A4F); // Darker shade for text

    return AgriBentaScaffold(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- PREMIUM LOGO STACK ---
            Stack(
              alignment: Alignment.center,
              children: [
                // 1. Outer Ring
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
                        Color(0xFFD4A574),
                        Color(0xFF52B788),
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
                  // 3. Inner White Circle
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
                    width: 150,
                    height: 150,
                    padding: const EdgeInsets.all(18),
                    color: Colors.transparent,
                    child: Image.asset(
                      'assets/icons/livestock.png',
                      color: const Color(0xFF40916C),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- 3. THE "HANDWRITING" EFFECT ---
            AnimatedBuilder(
              animation: _textAnimation,
              builder: (context, child) {
                // We use a ShaderMask to "reveal" the text from left to right
                return ShaderMask(
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: const [
                        darkGreen, // Visible Color
                        darkGreen,
                        Colors.transparent, // Hidden
                        Colors.transparent,
                      ],
                      // These stops move across the text based on the controller
                      stops: [
                        0.0,
                        _textAnimation.value, // The leading edge of the ink
                        _textAnimation.value + 0.1, // Soft fade edge
                        1.0,
                      ],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.srcIn,
                  child: Text(
                    "AgriBenta",
                    style: GoogleFonts.pacifico(
                      // <--- USING GOOGLE FONTS HERE
                      fontSize: 48,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.5,
                      color: const Color(0xFF2D6A4F), // Base color
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 40),

            // Loading Indicator
            const CircularProgressIndicator(color: brandGreen),
          ],
        ),
      ),
    );
  }
}
