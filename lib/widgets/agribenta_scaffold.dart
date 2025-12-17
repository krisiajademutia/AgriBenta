import 'dart:math' as math;
import 'package:flutter/material.dart';

class AgriBentaScaffold extends StatefulWidget {
  final Widget child;
  final bool showOrganicShapes;

  const AgriBentaScaffold({
    super.key,
    required this.child,
    this.showOrganicShapes = true,
  });

  @override
  State<AgriBentaScaffold> createState() => _AgriBentaScaffoldState();
}

class _AgriBentaScaffoldState extends State<AgriBentaScaffold>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();

    // Slower, more gentle rotation
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 45),
    )..repeat();

    // Breathing pulse effect
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // Floating animation for orbs
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    const Color bgTopGreen = Color(0xFFE8F5E9);
    const Color bgBottomGreen = Color(0xFFC8E6C9);
    const Color harvestGold = Color(0xFFD4A574);
    const Color brandGreen = Color(0xFF52B788);
    const Color accentGreen = Color(0xFF40916C);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // --- ENHANCED GRADIENT BACKGROUND ---
          Container(
            width: size.width,
            height: size.height,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE8F5E9),
                  Color(0xFFD4E9D4),
                  Color(0xFFC8E6C9),
                  Color(0xFFB8DDB8),
                ],
                stops: [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),

          // --- ANIMATED SUN RAYS ---
          AnimatedBuilder(
            animation: _rotationController,
            builder: (_, __) => CustomPaint(
              painter: EnhancedSunRaysPainter(
                _rotationController.value,
                harvestGold,
              ),
              size: size,
            ),
          ),

          // --- DECORATIVE PATTERN OVERLAY ---
          CustomPaint(
            painter: PatternPainter(brandGreen),
            size: size,
          ),

          // --- ENHANCED ORGANIC SHAPES ---
          if (widget.showOrganicShapes) ...[
            // Top-right golden orb with float animation
            AnimatedBuilder(
              animation: _floatController,
              builder: (_, child) {
                return Positioned(
                  top: -120 + (_floatController.value * 20),
                  right: -120 + (_floatController.value * 15),
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (_, __) {
                      return Container(
                        width: 320,
                        height: 320,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              harvestGold.withOpacity(
                                0.15 + _pulseController.value * 0.05,
                              ),
                              harvestGold.withOpacity(
                                0.08 + _pulseController.value * 0.03,
                              ),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.6, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: harvestGold.withOpacity(0.2),
                              blurRadius: 80,
                              spreadRadius: 20,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            // Secondary top-right accent
            Positioned(
              top: -60,
              right: 40,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) {
                  return Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          accentGreen.withOpacity(
                            0.2 + _pulseController.value * 0.05,
                          ),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom-left green orb with float
            AnimatedBuilder(
              animation: _floatController,
              builder: (_, child) {
                return Positioned(
                  bottom: -60 - (_floatController.value * 15),
                  left: -80 - (_floatController.value * 10),
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (_, __) {
                      return Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              brandGreen.withOpacity(
                                0.25 + _pulseController.value * 0.08,
                              ),
                              brandGreen.withOpacity(
                                0.12 + _pulseController.value * 0.04,
                              ),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: brandGreen.withOpacity(0.3),
                              blurRadius: 70,
                              spreadRadius: 15,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            // Additional accent orb - bottom center
            Positioned(
              bottom: 80,
              right: -40,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) {
                  return Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          harvestGold.withOpacity(
                            0.15 + _pulseController.value * 0.05,
                          ),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Top-left accent orb
            Positioned(
              top: 100,
              left: -30,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) {
                  return Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          accentGreen.withOpacity(
                            0.18 + _pulseController.value * 0.06,
                          ),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          // --- CONTENT ---
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: SafeArea(
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Enhanced Sun Rays Painter with multiple layers
class EnhancedSunRaysPainter extends CustomPainter {
  final double animation;
  final Color color;

  EnhancedSunRaysPainter(this.animation, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.max(size.width, size.height);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(animation * 2 * math.pi);

    // Draw two layers of rays with different opacities and counts
    _drawRayLayer(canvas, radius, 16, color.withOpacity(0.08), 1.5);

    canvas.rotate(math.pi / 16); // Offset second layer
    _drawRayLayer(canvas, radius, 12, color.withOpacity(0.12), 2.0);

    canvas.restore();
  }

  void _drawRayLayer(
    Canvas canvas,
    double radius,
    int rayCount,
    Color rayColor,
    double strokeWidth,
  ) {
    final paint = Paint()
      ..color = rayColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double angleStep = (2 * math.pi) / rayCount;

    for (int i = 0; i < rayCount; i++) {
      final double angle = i * angleStep;
      final startRadius = 80.0;

      canvas.drawLine(
        Offset(math.cos(angle) * startRadius, math.sin(angle) * startRadius),
        Offset(math.cos(angle) * radius, math.sin(angle) * radius),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(EnhancedSunRaysPainter oldDelegate) => true;
}

// Decorative Pattern Painter for subtle agricultural motifs
class PatternPainter extends CustomPainter {
  final Color color;

  PatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.03)
      ..style = PaintingStyle.fill;

    // Draw subtle scattered dots pattern (like seeds)
    final random = math.Random(42); // Fixed seed for consistent pattern

    for (int i = 0; i < 40; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final dotSize = 2.0 + random.nextDouble() * 3.0;

      canvas.drawCircle(Offset(x, y), dotSize, paint);
    }

    // Draw subtle leaf-like shapes in corners
    final leafPaint = Paint()
      ..color = color.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    _drawLeafShape(canvas, const Offset(50, 50), 30, leafPaint);
    _drawLeafShape(canvas, Offset(size.width - 50, 80), 25, leafPaint);
    _drawLeafShape(canvas, Offset(80, size.height - 60), 28, leafPaint);
  }

  void _drawLeafShape(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy - size);
    path.quadraticBezierTo(
      center.dx + size * 0.6,
      center.dy - size * 0.5,
      center.dx + size * 0.4,
      center.dy + size * 0.3,
    );
    path.quadraticBezierTo(
      center.dx,
      center.dy + size * 0.8,
      center.dx - size * 0.4,
      center.dy + size * 0.3,
    );
    path.quadraticBezierTo(
      center.dx - size * 0.6,
      center.dy - size * 0.5,
      center.dx,
      center.dy - size,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(PatternPainter oldDelegate) => false;
}
