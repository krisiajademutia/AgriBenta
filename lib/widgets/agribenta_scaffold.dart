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

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Get keyboard height manually since we disabled auto-resize
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    const Color bgTopGreen = Color(0xFFE8F5E9);
    const Color bgBottomGreen = Color(0xFFC8E6C9);
    const Color harvestGold = Color(0xFFD4A574);
    const Color brandGreen = Color(0xFF52B788);

    return Scaffold(
      // 1. Keep false so background orbs don't jump when keyboard opens
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // --- BACKGROUND (Full Screen) ---
          Container(
            width: size.width,
            height: size.height,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [bgTopGreen, bgBottomGreen],
              ),
            ),
            child: AnimatedBuilder(
              animation: _rotationController,
              builder: (_, __) => CustomPaint(
                painter: SunRaysPainter(_rotationController.value, harvestGold),
                size: size,
              ),
            ),
          ),

          // --- ORBS (Fixed Position) ---
          if (widget.showOrganicShapes) ...[
            Positioned(
              top: -100,
              right: -100,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) => Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: harvestGold
                        .withOpacity(0.08 + _pulseController.value * 0.02),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -50,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) => Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: brandGreen
                        .withOpacity(0.15 + _pulseController.value * 0.05),
                  ),
                ),
              ),
            ),
          ],

          // --- CONTENT (Resizes for Keyboard) ---
          // This fills the screen but adds padding at the bottom when keyboard opens
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

class SunRaysPainter extends CustomPainter {
  final double animation;
  final Color color;
  SunRaysPainter(this.animation, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.12)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.max(size.width, size.height);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(animation * 2 * math.pi);

    final int rayCount = 12;
    final double angleStep = (2 * math.pi) / rayCount;

    for (int i = 0; i < rayCount; i++) {
      final double angle = i * angleStep;
      canvas.drawLine(
        Offset(math.cos(angle) * 50, math.sin(angle) * 50),
        Offset(math.cos(angle) * radius, math.sin(angle) * radius),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_) => true;
}
