// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  String? _userId;
  bool _isSeller = false;

  //Getters
  String? get userId => _userId;
  bool get isSeller => _isSeller;

  // Login function
  Future<bool> login(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    if (email.isEmpty || password.isEmpty) {
      return false;
    }

    _userId = email.trim();
    _isSeller = email.toLowerCase().contains("seller");

    notifyListeners();
    return true;
  }

  // Logout function
  void logout() {
    _userId = null;
    _isSeller = false;
    notifyListeners();
  }
}
