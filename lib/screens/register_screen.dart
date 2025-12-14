// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/agribenta_scaffold.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _confirmController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your phone number';
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length != 11)
      return 'Phone number must be exactly 11 digits';
    if (!digitsOnly.startsWith('09')) return 'Must start with 09';
    return null;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Passwords do not match"),
          backgroundColor: Color(0xFFD84315)));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'location': 'Unknown Location',
        'role': 'Buyer',
        'created_at': Timestamp.now(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Account created successfully!"),
          backgroundColor: Color(0xFF4CAF50)));
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message ?? "Error"),
          backgroundColor: const Color(0xFFD84315)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;

    const Color textDark = Color(0xFF1B4332);
    const Color harvestGold = Color(0xFFD4A574);

    return AgriBentaScaffold(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: size.height),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.08, vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1. LOGO
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: harvestGold.withOpacity(0.3),
                                  width: 2),
                              color: harvestGold.withOpacity(0.1))),
                      Container(
                          width: 115,
                          height: 115,
                          padding: const EdgeInsets.all(6),
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
                              width: 95,
                              height: 95,
                              padding: const EdgeInsets.all(14),
                              child: Image.asset('assets/icons/livestock.png',
                                  color: const Color(0xFF40916C),
                                  fit: BoxFit.contain))),
                    ],
                  ),

                  SizedBox(height: isSmallScreen ? 18 : 24),

                  // 2. TEXT
                  ShaderMask(
                    shaderCallback: (_) => const LinearGradient(
                            colors: [Color(0xFF52B788), Color(0xFFD4A574)])
                        .createShader(const Rect.fromLTWH(0, 0, 300, 70)),
                    child: Text("AgriBenta",
                        style: TextStyle(
                            fontSize: isSmallScreen ? 26 : 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.5)),
                  ),
                  const SizedBox(height: 8),
                  Text("CREATE ACCOUNT",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: harvestGold)),

                  SizedBox(height: isSmallScreen ? 20 : 28),

                  // 3. FORM CARD
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(26),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFF1B4332).withOpacity(0.1),
                              blurRadius: 30,
                              offset: const Offset(0, 15))
                        ]),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildField(
                              _nameController,
                              "FULL NAME",
                              "Enter your full name",
                              Icons.person_outline_rounded,
                              textDark),
                          const SizedBox(height: 16),
                          _buildField(
                              _emailController,
                              "EMAIL",
                              "agribenta@example.com",
                              Icons.mail_outline_rounded,
                              textDark,
                              type: TextInputType.emailAddress),
                          const SizedBox(height: 16),
                          _buildField(_phoneController, "PHONE NUMBER",
                              "09123456789", Icons.phone_outlined, textDark,
                              type: TextInputType.phone,
                              validator: _validatePhoneNumber,
                              formatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ]),
                          const SizedBox(height: 16),
                          _buildField(
                              _passController,
                              "PASSWORD",
                              "Create a password",
                              Icons.lock_outline_rounded,
                              textDark,
                              obscure: _obscurePassword,
                              isPass: true,
                              togglePass: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                              validator: (v) =>
                                  v!.length < 6 ? 'Password too short' : null),
                          const SizedBox(height: 16),
                          _buildField(
                              _confirmController,
                              "CONFIRM PASSWORD",
                              "Re-enter password",
                              Icons.lock_outline_rounded,
                              textDark,
                              obscure: _obscureConfirm,
                              isPass: true,
                              togglePass: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                              validator: (v) =>
                                  v!.isEmpty ? 'Confirm password' : null),
                          const SizedBox(height: 24),
                          Container(
                            width: double.infinity,
                            height: 52,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: const LinearGradient(colors: [
                                  Color(0xFF52B788),
                                  Color(0xFF40916C)
                                ]),
                                boxShadow: [
                                  BoxShadow(
                                      color: const Color(0xFF52B788)
                                          .withOpacity(0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8))
                                ]),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14))),
                              onPressed: _isLoading ? null : _register,
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5))
                                  : const Text("Create Account",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1)),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text("Already have an account? ",
                        style: TextStyle(
                            color: textDark.withOpacity(0.6), fontSize: 13)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text("Sign In",
                          style: TextStyle(
                              color: Color(0xFF52B788),
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                    )
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, String hint,
      IconData icon, Color color,
      {bool obscure = false,
      TextInputType? type,
      String? Function(String?)? validator,
      List<TextInputFormatter>? formatters,
      bool isPass = false,
      VoidCallback? togglePass}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: color.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2)),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          keyboardType: type,
          obscureText: obscure,
          inputFormatters: formatters,
          style: TextStyle(color: color, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: color.withOpacity(0.3), fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFE8F5E9),
            prefixIcon: Icon(icon, color: const Color(0xFF52B788), size: 20),
            suffixIcon: isPass
                ? IconButton(
                    icon: Icon(
                        obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: color.withOpacity(0.4),
                        size: 20),
                    onPressed: togglePass)
                : null,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: Color(0xFF52B788), width: 2)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: validator ?? (v) => v!.isEmpty ? "Required" : null,
        ),
      ],
    );
  }
}
