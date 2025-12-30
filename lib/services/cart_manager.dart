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

      final doc = await cartRef.get();

      if (doc.exists) {
        // Update quantity if already in cart
        final currentQty = doc.data()?['quantity'] ?? 0;
        await cartRef.update({'quantity': currentQty + quantity});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cart updated (+1)")),
        );
      } else {
        // Add new item
        await cartRef.set({
          'livestockId': livestock.id,
          'sellerId': livestock.sellerId,
          'name': livestock.name,
          'price': livestock.price,
          'imagePath': livestock.imagePath,
          'quantity': quantity,
          'shippingFee':
              livestock.shippingFee, // Store this for calculations later
          'addedAt': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Added to cart")),
        );
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Cart Error: $e");
      return false;
    }
  }

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

  Future<void> updateQuantity(String livestockId, int newQty) async {
    if (!isLoggedIn || newQty < 1) return;
    await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('cart')
        .doc(livestockId)
        .update({'quantity': newQty});
    notifyListeners();
  }

  Stream<List<CartItem>> get cartStream {
    if (!isLoggedIn) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('cart')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        // --- CONSTRUCT CART ITEM CORRECTLY ---
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
            quantity: 1,
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

// ---------------------------------------------------------
// UPDATED CART ITEM CLASS (This fixes your error)
// ---------------------------------------------------------
class CartItem {
  final String id; // Document ID in 'cart' collection
  final Livestock livestock;
  int quantity;

  CartItem({
    required this.id,
    required this.livestock,
    this.quantity = 1,
  });

  double get totalPrice => livestock.price * quantity;

  // --- THIS WAS MISSING ---
  Map<String, dynamic> toMap() {
    return {
      'livestockId': livestock.id,
      'name': livestock.name,
      'price': livestock.price,
      'quantity': quantity,
      'imagePath': livestock.imagePath,
      'sellerId': livestock.sellerId,
    };
  }
}
