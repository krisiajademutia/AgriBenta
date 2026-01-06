import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserRoleManager extends ChangeNotifier {
  String _userRole = 'buyer';
  bool _isSeller = false;
  bool _hasTappedStartSelling = false;

  String get userRole => _userRole;
  bool get isSeller => _isSeller;
  bool get hasTappedStartSelling => _hasTappedStartSelling;

  UserRoleManager() {
    // FIX: Listen to auth changes.
    // This ensures we fetch the role automatically whenever the app restarts or user logs in.
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        fetchUserRole();
      } else {
        // Reset state if logged out
        _userRole = 'buyer';
        _isSeller = false;
        _hasTappedStartSelling = false;
        notifyListeners();
      }
    });
  }

  Future<void> fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data() as Map<String, dynamic>;
          _userRole = data['role'] ?? 'buyer';

          // If backend says they are a seller, unlock the UI
          if (_userRole == 'seller') {
            _hasTappedStartSelling = true;
          }
        }
      } catch (e) {
        debugPrint("Error fetching user role: $e");
      }
      notifyListeners();
    }
  }

  void switchToBuyer() {
    _isSeller = false;
    notifyListeners();
  }

  void switchToSeller() {
    _isSeller = true;
    notifyListeners();
  }

  Future<void> startSelling() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'role': 'seller'});

      _userRole = 'seller';
      _hasTappedStartSelling = true;
      _isSeller = true;

      notifyListeners();
    } catch (e) {
      debugPrint("Error updating role: $e");
    }
  }
}
