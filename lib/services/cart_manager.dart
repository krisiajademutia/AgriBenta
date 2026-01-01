import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/livestock_model.dart';
import '../models/cart_model.dart'; // <--- IMPORT THE MODEL

class CartManager extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  bool isOwnListing(String sellerId) => currentUser?.uid == sellerId;

  // --- 1. UPDATED ADD TO CART ---
  Future<bool> addToCart(
    Livestock livestock,
    BuildContext context, {
    int quantity = 1,
    String variantWeight = '',
    double variantPrice = 0.0,
  }) async {
    if (!isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please log in to add to cart")));
      return false;
    }

    if (isOwnListing(livestock.sellerId)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("You cannot add your own listing to cart")));
      return false;
    }

    try {
      // LOGIC: Create a unique ID for this specific variant
      // Example: if item is "Feed" and weight is "50kg", ID becomes "FeedID_50kg"
      String cartDocId = livestock.id;
      if (variantWeight.isNotEmpty) {
        cartDocId = "${livestock.id}_${variantWeight.replaceAll(' ', '')}";
      }

      final cartRef = _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('cart')
          .doc(cartDocId); // <--- USE UNIQUE ID

      final doc = await cartRef.get();

      // Determine final values
      String finalWeight =
          variantWeight.isNotEmpty ? variantWeight : livestock.weight;
      double finalPrice = variantPrice > 0 ? variantPrice : livestock.price;

      if (doc.exists) {
        // If exact item + weight exists, just add to quantity
        await cartRef.update({
          'quantity': FieldValue.increment(quantity),
        });
      } else {
        // New Item entry
        await cartRef.set({
          'livestockId': livestock.id,
          'sellerId': livestock.sellerId,
          'quantity': quantity, // Correctly mapped to quantity
          'weight': finalWeight, // Correctly mapped to weight
          'price': finalPrice,
          'addedAt': FieldValue.serverTimestamp(),
          'name': livestock.name,
          'imagePath': livestock.imagePath,
          'category': livestock.category,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Added to cart!"),
        backgroundColor: Color(0xFF52B788),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ));
      return true;
    } catch (e) {
      debugPrint(
        "Add Cart Error: $e",
      );
      return false;
    }
  }

  // Remove item
  Future<void> removeItem(String itemId) async {
    if (!isLoggedIn) return;
    await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('cart')
        .doc(itemId)
        .delete();
    notifyListeners();
  }

  // Update quantity
  Future<void> updateQuantity(String itemId, int newQty) async {
    if (!isLoggedIn || newQty < 1) return;
    await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('cart')
        .doc(itemId)
        .update({'quantity': newQty});
    notifyListeners();
  }

// --- 2. UPDATED STREAM (To read the weight back) ---
  Stream<List<CartItem>> get cartStream {
    if (!isLoggedIn) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('cart')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<CartItem> items = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final String livestockId = data['livestockId']; // fetch original ID

        // Load Details
        double savedPrice = (data['price'] as num?)?.toDouble() ?? 0.0;
        String savedWeight = data['weight'] ?? '';
        int savedQty = (data['quantity'] as num?)?.toInt() ?? 1;

        // Fetch latest livestock details
        final livestockDoc =
            await _firestore.collection('livestock').doc(livestockId).get();

        Livestock livestock;
        if (livestockDoc.exists) {
          livestock = Livestock.fromSnapshot(livestockDoc);
        } else {
          // FIXED: Manually create the empty object since .empty() does not exist
          livestock = Livestock(
            id: livestockId,
            sellerId: data['sellerId'] ?? '',
            name: data['name'] ?? 'Unknown Item',
            category: data['category'] ?? 'General',
            price: savedPrice,
            shippingFee: 0.0,
            age: '',
            weight: savedWeight,
            location: '',
            description: 'This item is no longer available.',
            imagePath: data['imagePath'] ?? '',
            imagePaths: [],
            postedAt: Timestamp.now(),
            status: 'unavailable',
            quantity: 0,
            variants: [],
          );
        }

        items.add(CartItem(
          id: doc.id, // This is the cartDocId (e.g., ID_50kg)
          livestock: livestock,
          quantity: savedQty,
          selectedWeight: savedWeight, // Pass weight to UI
          selectedPrice: savedPrice > 0 ? savedPrice : livestock.price,
        ));
      }
      return items;
    });
  }

  // Simple stream for badge count
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
