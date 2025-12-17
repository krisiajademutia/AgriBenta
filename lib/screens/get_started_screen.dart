// lib/screens/get_started_screen.dart
import 'package:flutter/material.dart';
import '../widgets/agribenta_scaffold.dart';

class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({super.key});

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..forward();
    _slideController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;

    return AgriBentaScaffold(
      child: SafeArea(
        child: Padding(
          padding:
              EdgeInsets.symmetric(horizontal: size.width * 0.08, vertical: 20),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                const Spacer(flex: 2),
                FadeTransition(
                  opacity: _fadeController,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                        CurvedAnimation(
                            parent: _slideController,
                            curve: Curves.easeOutBack)),
                    child: Stack(alignment: Alignment.center, children: [
                      Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color:
                                      const Color(0xFFD4A574).withOpacity(0.3),
                                  width: 2),
                              color: const Color(0xFFD4A574).withOpacity(0.1))),
                      Container(
                          width: 136,
                          height: 136,
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(colors: [
                                Color(0xFFD4A574),
                                Color(0xFF52B788)
                              ])),
                          child: Container(
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white))),
                      ClipOval(
                          child: Container(
                              width: 108,
                              height: 108,
                              padding: const EdgeInsets.all(18),
                              child: Image.asset('assets/icons/livestock.png',
                                  color: const Color(0xFF40916C),
                                  fit: BoxFit.contain))),
                    ]),
                  ),
                ),
                const Spacer(flex: 1),
                SlideTransition(
                  position: Tween<Offset>(
                          begin: const Offset(0, 0.2), end: Offset.zero)
                      .animate(CurvedAnimation(
                          parent: _slideController, curve: Curves.easeOut)),
                  child: FadeTransition(
                    opacity: _fadeController,
                    child: Column(
                      children: const [
                        Text("AgriBenta",
                            style: TextStyle(
                                fontSize: 52,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1B4332),
                                letterSpacing: 1.5)),
                        SizedBox(height: 8),
                        Text("Livestock Marketplace",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2.0,
                                color: Color(0xFFD4A574))),
                        SizedBox(height: 32),
                        Text(
                            "The easiest way to buy quality products\nand sell to a wider market.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF40755C),
                                height: 1.5,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                FadeTransition(
                  opacity: _fadeController,
                  child: Container(
                    width: 240,
                    height: 60,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: const LinearGradient(
                            colors: [Color(0xFF52B788), Color(0xFF40916C)]),
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFF52B788).withOpacity(0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 8))
                        ]),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30))),
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text("Get Started",
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded,
                                color: Colors.white)
                          ]),
                    ),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 30 : 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
