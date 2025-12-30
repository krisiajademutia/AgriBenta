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
    with TickerProviderStateMixin {
  late AnimationController _textAnimationController;
  late AnimationController _logoAnimationController;
  late Animation<double> _textAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotationAnimation;

  @override
  void initState() {
    super.initState();

    // 1. LOGO ANIMATION: A "Pop" with a slight tilt correction
    _logoAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoScaleAnimation = CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.elasticOut, // Bouncy pop
    );

    // Starts slightly tilted (-0.05) and straightens to (0.0)
    _logoRotationAnimation = Tween<double>(begin: -0.05, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: Curves.easeOutBack,
      ),
    );

    // 2. TEXT ANIMATION: The "Handwriting" effect
    _textAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _textAnimation = CurvedAnimation(
      parent: _textAnimationController,
      curve: Curves.easeInOutCubic,
    );

    // 3. SEQUENCE
    // Start Logo immediately
    _logoAnimationController.forward();

    // Start Text 0.6s later
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _textAnimationController.forward();
    });

    Timer(const Duration(seconds: 4), _checkLoginStatus);
  }

  @override
  void dispose() {
    _textAnimationController.dispose();
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
    // Brand Colors
    const Color darkGreen = Color(0xFF2D6A4F);
    const Color brandGreen = Color(0xFF52B788);
    const Color harvestGold = Color(0xFFD4A574);
    const Color deepForest = Color(0xFF1B4332);

    return AgriBentaScaffold(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- MINIMALIST LOGO ---
            // No rings, just the icon popping in with a shadow
            ScaleTransition(
              scale: _logoScaleAnimation,
              child: RotationTransition(
                turns: _logoRotationAnimation,
                child: Container(
                  // Soft glow behind the icon
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
                    color: deepForest, // Very dark green (Looks like ink)
                    width: 170, // Much larger size
                    height: 170,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            // const SizedBox(height: 20),

            // --- TEXT ANIMATION ---
            AnimatedBuilder(
              animation: _textAnimation,
              builder: (context, child) {
                return Column(
                  children: [
                    // 1. "Handwriting" Text
                    ShaderMask(
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            darkGreen,
                            darkGreen,
                            Colors.transparent,
                            Colors.transparent,
                          ],
                          stops: [
                            0.0,
                            _textAnimation.value,
                            _textAnimation.value + 0.08,
                            1.0,
                          ],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.srcIn,
                      child: Text(
                        "AgriBenta",
                        style: GoogleFonts.pacifico(
                          fontSize: 56,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                          color: darkGreen,
                        ),
                      ),
                    ),

                    // 2. Subtitle (With Crash Fix)
                    Opacity(
                      opacity: (_textAnimation.value > 0.6
                              ? (_textAnimation.value - 0.6) / 0.4
                              : 0.0)
                          .clamp(0.0, 1.0), // <--- FIX APPLIED
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          "Livestock Marketplace",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 4.0,
                            color: harvestGold,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 60),

            // Minimalist Loader
            FadeTransition(
              opacity: _textAnimation,
              child: const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: brandGreen,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
