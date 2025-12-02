// lib/screens/register_screen.dart (SECURE VERSION)
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; // <--- 1. NEW: FIREBASE AUTH IMPORT
import 'dart:math';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override 
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmController = TextEditingController();
  
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
    _nameController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // --- 🧠 THE BRAIN: FIXED SECURE REGISTER LOGIC ---
  Future<void> _register() async {
    // 1. Basic Validation
    if (_nameController.text.isEmpty || 
        _emailController.text.isEmpty || 
        _passController.text.isEmpty ||
        _passController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please check fields/passwords"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. CREATE USER SESSION WITH FIREBASE AUTH (Handles password securely!)
      final UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passController.text.trim(),
      );

      // 3. SAVE ADDITIONAL USER DATA TO FIRESTORE (Linked by the new user's UID)
      // NOTE: We no longer save the password here!
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid) // Use the secure UID as the document ID
          .set({
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'role': 'Farmer', 
            'created_at': Timestamp.now(), 
          });
      
      if (!mounted) return;

      // 4. Success & Navigation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Account Created Successfully!"), backgroundColor: Colors.green),
      );
      
      // Go to Home Screen
      Navigator.pushReplacementNamed(context, '/home');

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      // Handle Auth specific errors (weak password, email already in use)
      String message = "An error occurred during registration.";
      if (e.code == 'weak-password') {
        message = "❌ The password provided is too weak (must be 6+ characters).";
      } else if (e.code == 'email-already-in-use') {
        message = "❌ An account already exists for that email.";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );

    } catch (e) {
      if (!mounted) return;
      // Generic Error Handling
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: ${e.toString()}"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep your existing build method UI (it looks great!)
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2C2218),   // Deep Café Noir
              Color(0xFF2E4F2A),   // Strong Kombu Green
              Color(0xFF1A3A1F),
              Color(0xFF2E4F2A),
              Color(0xFFE9D7C4),   // Bone
            ],
            stops: [0.0, 0.3, 0.6, 0.85, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Floating background (Keep your design!)
            AnimatedBuilder(
              animation: _controller,
              builder: (_, __) => CustomPaint(
                painter: FloatingLivestockPainter(_controller.value),
                size: MediaQuery.of(context).size,
              ),
            ),

            // Register Form
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 60),

                    // Logo Container
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
                        padding: const EdgeInsets.all(30),
                        child: Image.asset('assets/icons/livestock.png', color: Colors.white),
                      ),
                    ),

                    const SizedBox(height: 30),

                    const Text("AgriBenta", style: TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                    const Text("Create your account", style: TextStyle(fontSize: 18, color: Colors.white70)),

                    const SizedBox(height: 50),

                    // Full Name
                    TextField(controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Full Name", hintStyle: const TextStyle(color: Colors.white60),
                        filled: true, fillColor: Colors.white.withOpacity(0.2),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                        prefixIcon: const Icon(Icons.person_outline, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Email
                    TextField(controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Email", hintStyle: const TextStyle(color: Colors.white60),
                        filled: true, fillColor: Colors.white.withOpacity(0.2),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                        prefixIcon: const Icon(Icons.email_outlined, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Password
                    TextField(controller: _passController, obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Password", hintStyle: const TextStyle(color: Colors.white60),
                        filled: true, fillColor: Colors.white.withOpacity(0.2),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                        prefixIcon: const Icon(Icons.lock_outline, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Confirm Password
                    TextField(controller: _confirmController, obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Confirm Password", hintStyle: const TextStyle(color: Colors.white60),
                        filled: true, fillColor: Colors.white.withOpacity(0.2),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                        prefixIcon: const Icon(Icons.lock_outline, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Register Button (Now Wired Up!)
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
                        onPressed: _isLoading ? null : _register, // <--- Triggers the secure logic
                        child: _isLoading 
                            ? const CircularProgressIndicator(color: Color(0xFF2E4F2A))
                            : const Text("Register", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Text("agribenta.hehe", style: TextStyle(color: Colors.white60, fontSize: 13)),
                    const SizedBox(height: 40),
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