import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserRoleManager extends ChangeNotifier {
  String _role = 'buyer'; // default
  bool _hasStartedSelling = false;

  String get role => _role;
  bool get isSeller => _role == 'seller';
  bool get hasTappedStartSelling => _hasStartedSelling;

  UserRoleManager() {
    _loadRole(); // ← CALL IN CONSTRUCTOR
  }

  Future<void> _loadRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data() ?? {};
      final savedRole = data['role'] as String?;

      if (savedRole == 'seller') {
        _role = 'seller';
        _hasStartedSelling = true;
      } else {
        _role = 'buyer';
        _hasStartedSelling = false;
      }
    } catch (e) {
      _role = 'buyer';
      _hasStartedSelling = false;
    }

    notifyListeners(); // ← THIS WAS MISSING BEFORE!
  }

  Future<void> startSelling() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({'role': 'seller'}, SetOptions(merge: true));

    _role = 'seller';
    _hasStartedSelling = true;
    notifyListeners();
  }

  Future<void> switchToBuyer() async {
    _role = 'buyer';
    notifyListeners();
  }

  Future<void> switchToSeller() async {
    _role = 'seller';
    notifyListeners();
  }
}
