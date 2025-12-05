// lib/screens/login_screen.dart (SECURE VERSION)
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; 
import 'dart:math';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  
  bool _isLoading = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 35))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  // --- 🧠 THE BRAIN: FIXED SECURE LOGIN LOGIC ---
  Future<void> _login() async {
    // 1. Basic Check: Did they type anything?
    if (_emailController.text.isEmpty || _passController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email and password"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. USE FIREBASE AUTHENTICATION TO SIGN THE USER IN (Creates the session!)
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passController.text.trim(),
      );

      if (!mounted) return;

      // 3. SUCCESS! A session is created. The ProfileScreen stream will now update.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Login Successful! Welcome back."), backgroundColor: Colors.green),
      );
      
      // 4. Navigate to Home Screen
      Navigator.pushReplacementNamed(context, '/home');

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      
      String message = "An error occurred during login.";
      
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = "❌ Invalid email or password. Please check your credentials.";
      } else if (e.code == 'invalid-email') {
        message = "❌ The email address is not valid.";
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  // -------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2C2218),   
              Color(0xFF2E4F2A),   
              Color(0xFF1A3A1F),
              Color(0xFF2E4F2A),
              Color(0xFFE9D7C4),   
            ],
            stops: [0.0, 0.3, 0.6, 0.85, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animation Background
            AnimatedBuilder(
              animation: _controller,
              builder: (_, __) => CustomPaint(
                painter: FloatingLivestockPainter(_controller.value),
                size: MediaQuery.of(context).size,
              ),
            ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  child: Column(
                    children: [
                      // Logo
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF2E4F2A).withOpacity(0.95),
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(color: Colors.black54, blurRadius: 25, offset: const Offset(0, 10)),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(30),
                          child: Image.asset('assets/icons/livestock.png', color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 30),

                      const Text("AgriBenta", style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
                      const Text("Login to your account", style: TextStyle(fontSize: 16, color: Colors.white70)),

                      const SizedBox(height: 50),

                      // Email Field
                      TextField(
                        controller: _emailController, 
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Email", hintStyle: const TextStyle(color: Colors.white60),
                          filled: true, fillColor: Colors.white.withOpacity(0.2),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                          prefixIcon: const Icon(Icons.email_outlined, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Password Field
                      TextField(
                        controller: _passController, 
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Password", hintStyle: const TextStyle(color: Colors.white60),
                          filled: true, fillColor: Colors.white.withOpacity(0.2),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                          prefixIcon: const Icon(Icons.lock_outline, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // LOGIN BUTTON
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
                          onPressed: _isLoading ? null : _login,
                          child: _isLoading 
                            ? const CircularProgressIndicator(color: Color(0xFF2E4F2A))
                            : const Text("LOGIN", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Link to Register
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/register');
                        },
                        child: const Text("Don't have an account? Sign Up", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Keeping your painter code here for completeness
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