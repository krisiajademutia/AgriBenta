// lib/screens/get_started_screen.dart
import 'package:flutter/material.dart';
import 'dart:math';

class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({super.key});
  @override State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 35))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2C2218), // Deep Café Noir
              Color(0xFF2E4F2A), // Strong Kombu Green
              Color(0xFF1A3A1F),
              Color(0xFF2E4F2A),
              Color(0xFFE9D7C4), // Bone
            ],
            stops: [0.0, 0.3, 0.6, 0.85, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Floating background icons
            AnimatedBuilder(
              animation: _controller,
              builder: (_, __) => CustomPaint(
                painter: FloatingLivestockPainter(_controller.value),
                size: MediaQuery.of(context).size,
              ),
            ),

            // Main content — SCROLLABLE + RESPONSIVE
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 40), // top space

                    // Logo circle
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF2E4F2A).withOpacity(0.95),
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(color: Colors.black54, blurRadius: 25, offset: const Offset(0, 10)),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Image.asset('assets/icons/livestock.png', color: Colors.white),
                      ),
                    ),

                    const SizedBox(height: 30),

                    const Text("AgriBenta", style: TextStyle(fontSize: 50, color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5)),

                    /*const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      child: Text(
                        "Your one-stop shop for all your livestock needs.\nBuy and sell with ease!",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.5),
                      ),
                    ),*/

                    const SizedBox(height: 110), 

                    // Log In Button
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF2E4F2A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 15,
                        ),
                        onPressed: () => Navigator.pushNamed(context, '/login'),
                        child: const Text("Log In", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                    ),

                    const SizedBox(height: 16), 

                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white, width: 2.5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        onPressed: () => Navigator.pushNamed(context, '/register'),
                        child: const Text("Register", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                    ),

                    const SizedBox(height: 40), // safe bottom space
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FloatingLivestockPainter extends CustomPainter {
  final double animationValue;
  FloatingLivestockPainter(this.animationValue);

  final List<IconData> icons = [Icons.cruelty_free, Icons.pets, Icons.nature, Icons.eco, Icons.yard];
  final List<Offset> positions = [
    const Offset(0.1, 0.2), const Offset(0.8, 0.3),
    const Offset(0.3, 0.7), const Offset(0.7, 0.8),
    const Offset(0.5, 0.1),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < icons.length; i++) {
      final x = positions[i].dx * size.width + sin(animationValue * 2 * pi + i) * 60;
      final y = positions[i].dy * size.height + cos(animationValue * 2 * pi + i) * 60;

      final textPainter = TextPainter(textDirection: TextDirection.ltr);
      textPainter.text = TextSpan(
        text: String.fromCharCode(icons[i].codePoint),
        style: TextStyle(fontSize: 80, fontFamily: icons[i].fontFamily, color: Colors.white.withOpacity(0.07)),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - 40, y - 40));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}