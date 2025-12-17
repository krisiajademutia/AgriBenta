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
  late AnimationController _pulseController;
  late Animation<double> _textAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotationAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Logo animations
    _logoAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _logoScaleAnimation = CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.elasticOut,
    );

    _logoRotationAnimation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: Curves.easeOutBack,
      ),
    );

    // Pulse effect for logo
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Text writing animation
    _textAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _textAnimation = CurvedAnimation(
      parent: _textAnimationController,
      curve: Curves.easeInOutCubic,
    );

    // Start animations with delays
    _logoAnimationController.forward();

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _textAnimationController.forward();
    });

    Timer(const Duration(seconds: 4), _checkLoginStatus);
  }

  @override
  void dispose() {
    _textAnimationController.dispose();
    _logoAnimationController.dispose();
    _pulseController.dispose();
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
    const Color darkGreen = Color(0xFF2D6A4F);
    const Color deepGreen = Color(0xFF1B4332);

    return AgriBentaScaffold(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _logoScaleAnimation,
              child: RotationTransition(
                turns: _logoRotationAnimation,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outermost glow effect
                          Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: harvestGold.withOpacity(0.3),
                                  blurRadius: 60,
                                  spreadRadius: 10,
                                ),
                                BoxShadow(
                                  color: brandGreen.withOpacity(0.2),
                                  blurRadius: 80,
                                  spreadRadius: 20,
                                ),
                              ],
                            ),
                          ),

                          // Outer decorative ring with gradient border
                          Container(
                            width: 190,
                            height: 190,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  harvestGold.withOpacity(0.4),
                                  brandGreen.withOpacity(0.3),
                                ],
                              ),
                            ),
                          ),

                          // Middle ring
                          Container(
                            width: 182,
                            height: 182,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.1),
                              border: Border.all(
                                color: harvestGold.withOpacity(0.5),
                                width: 2,
                              ),
                            ),
                          ),

                          // Main gradient ring with enhanced shadow
                          Container(
                            width: 165,
                            height: 165,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFD4A574),
                                  Color(0xFFB8860B),
                                  Color(0xFF52B788),
                                  Color(0xFF40916C),
                                ],
                                stops: [0.0, 0.3, 0.7, 1.0],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: brandGreen.withOpacity(0.5),
                                  blurRadius: 35,
                                  offset: const Offset(0, 12),
                                  spreadRadius: 2,
                                ),
                                BoxShadow(
                                  color: harvestGold.withOpacity(0.3),
                                  blurRadius: 25,
                                  offset: const Offset(-5, -5),
                                ),
                              ],
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: deepGreen.withOpacity(0.1),
                                    blurRadius: 15,
                                    spreadRadius: -2,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Inner decorative circle
                          Container(
                            width: 145,
                            height: 145,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: brandGreen.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                          ),

                          // Icon with enhanced styling
                          ClipOval(
                            child: Container(
                              width: 130,
                              height: 130,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.0),
                                    brandGreen.withOpacity(0.05),
                                  ],
                                ),
                              ),
                              child: Image.asset(
                                'assets/icons/livestock.png',
                                color: const Color(0xFF40916C),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),

                          // Subtle inner highlight
                          Positioned(
                            top: 25,
                            left: 40,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.4),
                                    Colors.white.withOpacity(0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Handwriting Effect Text
            AnimatedBuilder(
              animation: _textAnimation,
              builder: (context, child) {
                return Column(
                  children: [
                    // Main text with writing effect
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
                          fontSize: 52,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.8,
                          color: darkGreen,
                          shadows: [
                            Shadow(
                              color: harvestGold.withOpacity(0.3),
                              offset: const Offset(2, 2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),

                    Opacity(
                      opacity: (_textAnimation.value > 0.7
                              ? (_textAnimation.value - 0.7) / 0.3
                              : 0.0)
                          .clamp(0.0, 1.0),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          "Livestock Marketplace",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 3.0,
                            color: harvestGold.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 50),

            // Enhanced Loading Indicator
            FadeTransition(
              opacity: _textAnimation,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: brandGreen.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(brandGreen),
                  backgroundColor: brandGreen.withOpacity(0.1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
