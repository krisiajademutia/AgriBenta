// lib/services/cart_manager.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/livestock_model.dart';

class CartManager extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  bool isOwnListing(String sellerId) => currentUser?.uid == sellerId;

  // Add or update item with quantity
  Future<bool> addToCart(Livestock livestock, BuildContext context,
      {int quantity = 1}) async {
    if (!isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in to add to cart")),
      );
      Navigator.pushNamed(context, '/login');
      return false;
    }

    if (isOwnListing(livestock.sellerId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("You cannot add your own listing to cart")),
      );
      return false;
    }

    try {
      final cartRef = _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('cart')
          .doc(livestock.id);

      await cartRef.set({
        'livestockId': livestock.id,
        'name': livestock.name,
        'price': livestock.price,
        'shippingFee': livestock.shippingFee,
        'imagePath': livestock.imagePath,
        'sellerId': livestock.sellerId,
        'quantity':
            FieldValue.increment(quantity), // Increases quantity if exists
        'addedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(quantity > 1
              ? "Added $quantity more to cart!"
              : "Added to cart successfully! 🛒"),
          backgroundColor: Colors.green,
        ),
      );
      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add to cart: $e")),
      );
      return false;
    }
  }

  // Update quantity manually
  Future<void> updateQuantity(String livestockId, int newQuantity) async {
    if (!isLoggedIn || newQuantity <= 0) {
      await removeFromCart(livestockId);
      return;
    }

    await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('cart')
        .doc(livestockId)
        .update({'quantity': newQuantity});

    notifyListeners();
  }

  // Remove item
  Future<void> removeFromCart(String livestockId) async {
    if (!isLoggedIn) return;

    await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('cart')
        .doc(livestockId)
        .delete();

    notifyListeners();
  }

  // Clear cart
  Future<void> clearCart() async {
    if (!isLoggedIn) return;

    final batch = _firestore.batch();
    final snapshot = await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('cart')
        .get();

    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    notifyListeners();
  }

  // Stream of cart items with quantity
  Stream<List<CartItem>> get cartItemsStream {
    if (!isLoggedIn) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('cart')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return CartItem(
          id: doc.id,
          livestock: Livestock(
            id: data['livestockId'] ?? doc.id,
            sellerId: data['sellerId'] ?? '',
            name: data['name'] ?? 'Unknown',
            price: (data['price'] as num?)?.toDouble() ?? 0.0,
            shippingFee: (data['shippingFee'] as num?)?.toDouble() ?? 0.0,
            imagePath: data['imagePath'] ?? '',
            imagePaths: [data['imagePath'] ?? ''],
            category: 'Unknown',
            age: 'N/A',
            weight: 'N/A',
            location: 'N/A',
            description: '',
            postedAt: Timestamp.now(),
            status: 'active',
          ),
          quantity: (data['quantity'] as num?)?.toInt() ?? 1,
        );
      }).toList();
    });
  }

  Stream<int> get cartItemCountStream {
    if (!isLoggedIn) return Stream.value(0);

    return _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('cart')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}

// Simple model for cart items
class CartItem {
  final String id;
  final Livestock livestock;
  final int quantity;

  CartItem({required this.id, required this.livestock, required this.quantity});

  double get totalPrice => livestock.price * quantity;
}
