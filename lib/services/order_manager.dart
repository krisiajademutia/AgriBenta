import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/cart_manager.dart';
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
      final String cleanAddress = deliveryAddress.toLowerCase().trim();

      // 1. FETCH BUYER NAME
      final userDoc = await _firestore.collection('users').doc(buyerId).get();
      final String buyerName = userDoc.data()?['name'] ?? 'AgriBenta User';

      // 2. Group items by Seller
      Map<String, List<CartItem>> itemsBySeller = {};
      for (var item in items) {
        final sellerId = item.livestock.sellerId;
        if (!itemsBySeller.containsKey(sellerId)) {
          itemsBySeller[sellerId] = [];
        }
        itemsBySeller[sellerId]!.add(item);
      }

      List<Map<String, dynamic>> pendingNotifications = [];

      // 3. Create Order per Seller
      for (var entry in itemsBySeller.entries) {
        final sellerId = entry.key;
        final sellerItems = entry.value;

        double sellerTotal = 0;
        for (var item in sellerItems) {
          sellerTotal += item.livestock.price * item.quantity;
        }

        final orderRef = _firestore.collection('orders').doc();
        final orderId = orderRef.id;

        final orderData = {
          'orderId': orderId,
          'buyerId': buyerId,
          'buyerName': buyerName,
          'sellerId': sellerId,
          'items': sellerItems.map((item) {
            // --- FIX IS HERE: Using the correct property names ---
            String? imageUrl = item.livestock.imagePath;

            // Fallback: If imagePath is empty, try the first item in imagePaths list
            if ((imageUrl == null || imageUrl.isEmpty) &&
                item.livestock.imagePaths.isNotEmpty) {
              imageUrl = item.livestock.imagePaths.first;
            }
            // ----------------------------------------------------

            return {
              'livestockId': item.livestock.id,
              'name': item.livestock.name,
              'price': item.livestock.price,
              'quantity': item.quantity,
              'image': imageUrl,
            };
          }).toList(),
          'totalAmount': sellerTotal,
          'deliveryAddress': deliveryAddress,
          'paymentMethod': paymentMethod,
          'isPickup': isPickup,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'searchKeywords': [
            ...cleanAddress.split(' '),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to place order: $e")),
        );
      }
      return false;
    }
  }
}
