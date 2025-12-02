// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  String? _userId;
  bool _isSeller = false;

  //Getters
  String? get userId => _userId;
  bool get isSeller => _isSeller;

  // Login function (mock muna – pwede na for demo)
  Future<bool> login(String email, String password) async {
    // Fake delay para feel ng real login
    await Future.delayed(const Duration(seconds: 1));

    if (email.isEmpty || password.isEmpty) {
      return false;
    }

    // Simple rule: kapag may "seller" sa email → seller
    _userId = email.trim();
    _isSeller = email.toLowerCase().contains("seller");

    notifyListeners(); // Importanteng line – sinasabi sa app na may nagbago
    return true;
  }

  // Logout function
  void logout() {
    _userId = null;
    _isSeller = false;
    notifyListeners();
  }
}