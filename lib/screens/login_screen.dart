import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/agribenta_scaffold.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Welcome back!"), backgroundColor: Color(0xFF4CAF50)));
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message ?? "Failed"),
          backgroundColor: const Color(0xFFD84315)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;

    // Theme Colors
    const Color textDark = Color(0xFF1B4332);
    const Color harvestGold = Color(0xFFD4A574);
    const Color brandGreen = Color(0xFF52B788);

    return AgriBentaScaffold(
      // The content uses the exact structure of your original file
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: size.height),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.08,
                  vertical: isSmallScreen ? 16 : 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- MODIFIED LOGO SECTION (SPLASH STYLE) ---
                  Container(
                    height:
                        isSmallScreen ? 100 : 130, // Adjusted size for Login
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1B4332).withOpacity(0.2),
                          blurRadius: 40,
                          spreadRadius: 5,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/icons/livestock.png',
                      fit: BoxFit.contain,
                      color: Color(0xFF40916C),
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 20 : 24),

                  // APP NAME
                  ShaderMask(
                    shaderCallback: (_) => const LinearGradient(
                            colors: [Color(0xFF52B788), Color(0xFFD4A574)])
                        .createShader(const Rect.fromLTWH(0, 0, 300, 70)),
                    child: Text("AgriBenta",
                        style: TextStyle(
                            fontSize: isSmallScreen ? 28 : 34,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1.5)),
                  ),
                  const SizedBox(height: 4),
                  Text("LOG-IN",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: harvestGold)),

                  SizedBox(height: isSmallScreen ? 25 : 35),

                  // 2. FORM
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: EdgeInsets.all(isSmallScreen ? 22 : 28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFF1B4332).withOpacity(0.1),
                            blurRadius: 30,
                            offset: const Offset(0, 10))
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("EMAIL", isSmallScreen, textDark),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(color: textDark, fontSize: 14),
                            decoration: _buildInputDecoration(
                                "agribenta@example.com",
                                Icons.mail_outline_rounded,
                                textDark),
                            validator: (v) => v!.isEmpty || !v.contains('@')
                                ? "Please enter a valid email"
                                : null,
                          ),

                          SizedBox(height: isSmallScreen ? 16 : 20),

                          _buildLabel("PASSWORD", isSmallScreen, textDark),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passController,
                            obscureText: _obscurePassword,
                            style: TextStyle(color: textDark, fontSize: 14),
                            decoration: _buildInputDecoration(
                                    "Enter your password",
                                    Icons.lock_outline_rounded,
                                    textDark)
                                .copyWith(
                                    suffixIcon: IconButton(
                              icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: textDark.withOpacity(0.4),
                                  size: 20),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            )),
                            validator: (v) => v!.isEmpty
                                ? "Please enter your password"
                                : null,
                          ),

                          const SizedBox(height: 13),

                          // Button
                          Container(
                            width: double.infinity,
                            height: 52,
                            decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [
                                  Color(0xFF52B788),
                                  Color(0xFF40916C)
                                ]),
                                borderRadius: BorderRadius.circular(26),
                                boxShadow: [
                                  BoxShadow(
                                      color: brandGreen.withOpacity(0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8))
                                ]),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(26))),
                              onPressed: _isLoading ? null : _login,
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5))
                                  : const Text("Sign In",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 20 : 28),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account? ",
                          style: TextStyle(
                              color: textDark.withOpacity(0.6), fontSize: 13)),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/register'),
                        child: const Text("Sign Up",
                            style: TextStyle(
                                color: Color(0xFF52B788),
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, bool small, Color color) {
    return Text(text,
        style: TextStyle(
            color: color.withOpacity(0.7),
            fontSize: small ? 11 : 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2));
  }

  InputDecoration _buildInputDecoration(
      String hint, IconData icon, Color color) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: color.withOpacity(0.3), fontSize: 13),
      filled: true,
      fillColor: const Color(0xFFE8F5E9),
      prefixIcon: Icon(icon, color: const Color(0xFF52B788), size: 20),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF52B788), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
