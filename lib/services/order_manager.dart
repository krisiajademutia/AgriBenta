import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/cart_model.dart';
import 'notification_manager.dart';

class OrderManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Future<bool> placeOrder({
    required List<CartItem> items,
    required double totalAmount,
    required String deliveryAddress,
    required String paymentMethod,
    required bool isPickup,
    required BuildContext context,
  }) async {
    if (currentUser == null) return false;

    try {
      final batch = _firestore.batch();
      final buyerId = currentUser!.uid;

      // 1. FETCH BUYER DATA
      final userDoc = await _firestore.collection('users').doc(buyerId).get();
      final userData = userDoc.data() ?? {};
      final String buyerName = userData['name'] ?? 'AgriBenta User';

      String buyerCity = '';
      if (!isPickup) {
        final parts = deliveryAddress.split(',');
        if (parts.length >= 3) {
          buyerCity = parts[parts.length - 3].trim();
        }
      }

      // 2. CHECK & DECREMENT STOCK (Crucial Step Added)
      for (var item in items) {
        final livestockRef =
            _firestore.collection('livestock').doc(item.livestock.id);
        final livestockDoc = await livestockRef.get();

        if (!livestockDoc.exists) {
          throw "One of the items no longer exists.";
        }

        final data = livestockDoc.data() as Map<String, dynamic>;

        // Handle Variants vs Main Quantity
        if (item.selectedWeight != null && data['variants'] != null) {
          // --- VARIANT LOGIC ---
          List<dynamic> variants = List.from(data['variants']);
          bool variantFound = false;

          for (var i = 0; i < variants.length; i++) {
            // Match variant by weight/name
            if (variants[i]['weight'] == item.selectedWeight) {
              int currentQty = variants[i]['quantity'] ?? 0;

              if (currentQty < item.quantity) {
                throw "Not enough stock for ${item.livestock.name} (${item.selectedWeight})";
              }

              // Decrement
              variants[i]['quantity'] = currentQty - item.quantity;
              variantFound = true;
              break;
            }
          }

          if (!variantFound) {
            // Fallback if variant structure changed or mismatch
            throw "Variant ${item.selectedWeight} not found.";
          }

          // Update the variants array in the database
          batch.update(livestockRef, {'variants': variants});
        } else {
          // --- SIMPLE PRODUCT LOGIC ---
          int currentQty = data['quantity'] ?? 0;
          if (currentQty < item.quantity) {
            throw "Not enough stock for ${item.livestock.name}";
          }

          int newQty = currentQty - item.quantity;

          // If stock hits 0, you can optionally mark as 'sold'
          // but usually quantity 0 is enough to disable the UI.
          Map<String, dynamic> updates = {'quantity': newQty};
          if (newQty <= 0) {
            updates['status'] = 'sold';
          }

          batch.update(livestockRef, updates);
        }
      }

      // 3. Group items by Seller for Order Creation
      Map<String, List<CartItem>> itemsBySeller = {};
      for (var item in items) {
        final sellerId = item.livestock.sellerId;
        if (!itemsBySeller.containsKey(sellerId)) {
          itemsBySeller[sellerId] = [];
        }
        itemsBySeller[sellerId]!.add(item);
      }

      List<Map<String, dynamic>> pendingNotifications = [];

      // 4. Create Order per Seller
      for (var entry in itemsBySeller.entries) {
        final sellerId = entry.key;
        final sellerItems = entry.value;

        double sellerItemTotal = 0.0;
        double sellerShippingTotal = 0.0;

        for (var item in sellerItems) {
          sellerItemTotal += item.selectedPrice * item.quantity;

          if (!isPickup) {
            double baseFee = item.livestock.shippingFee;
            String sellerCity = item.livestock.location.trim();
            bool isSameCity = buyerCity.isNotEmpty &&
                sellerCity.toLowerCase().contains(buyerCity.toLowerCase());

            if (isSameCity) {
              sellerShippingTotal += baseFee;
            } else {
              sellerShippingTotal += (baseFee + 500.0);
            }
          }
        }

        double finalOrderTotal = sellerItemTotal + sellerShippingTotal;
        final orderRef = _firestore.collection('orders').doc();
        final orderId = orderRef.id;

        final orderData = {
          'orderId': orderId,
          'buyerId': buyerId,
          'buyerName': buyerName,
          'sellerId': sellerId,
          'items': sellerItems
              .map((item) => {
                    'livestockId': item.livestock.id,
                    'name': item.livestock.name,
                    'quantity': item.quantity,
                    'price': item.selectedPrice,
                    'weight': item.selectedWeight,
                    'imagePath': item.livestock.imagePath,
                  })
              .toList(),
          'subtotal': sellerItemTotal,
          'shippingFee': sellerShippingTotal,
          'totalAmount': finalOrderTotal,
          'deliveryAddress': deliveryAddress,
          'paymentMethod': paymentMethod,
          'isPickup': isPickup,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'searchKeywords': [
            ...deliveryAddress.toLowerCase().split(' '),
            'pending',
            buyerId,
            sellerId
          ],
        };

        batch.set(orderRef, orderData);

        // Notification Setup
        final firstItemName = sellerItems.first.livestock.name;
        final itemCount = sellerItems.length;
        final itemLabel = itemCount > 1
            ? "$firstItemName + ${itemCount - 1} others"
            : firstItemName;

        pendingNotifications.add({
          'receiverId': sellerId,
          'title': 'New Order Received! 📦',
          'body': 'You have a new order for $itemLabel from $buyerName.',
          'type': 'order',
          'referenceId': orderId,
        });
      }

      // 5. COMMIT EVERYTHING (Stock Updates + New Orders)
      await batch.commit();

      for (var note in pendingNotifications) {
        await NotificationManager.sendNotification(
          receiverId: note['receiverId']!,
          title: note['title']!,
          body: note['body']!,
          type: note['type']!,
          referenceId: note['referenceId'],
        );
      }

      return true;
    } catch (e) {
      debugPrint("Order Error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Failed to place order: $e")));
      }
      return false;
    }
  }
}
