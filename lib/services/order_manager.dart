import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/cart_manager.dart';

class OrderManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  String _generateChatRoomId(String uid1, String uid2) {
    final List<String> ids = [uid1, uid2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Future<bool> placeOrder({
    required List<CartItem> items,
    required double totalAmount,
    required String deliveryAddress,
    required String paymentMethod,
    required bool isPickup, // <--- ADDED THIS PARAMETER
    required BuildContext context,
  }) async {
    if (currentUser == null) return false;

    try {
      final batch = _firestore.batch();
      final buyerId = currentUser!.uid;
      final String cleanAddress = deliveryAddress.toLowerCase().trim();

      // 1. Group items by Seller
      Map<String, List<CartItem>> itemsBySeller = {};
      for (var item in items) {
        final sellerId = item.livestock.sellerId;
        if (!itemsBySeller.containsKey(sellerId)) {
          itemsBySeller[sellerId] = [];
        }
        itemsBySeller[sellerId]!.add(item);
      }

      // 2. Create Order per Seller
      for (var sellerId in itemsBySeller.keys) {
        final sellerItems = itemsBySeller[sellerId]!;

        double orderSubtotal = 0.0;
        double orderShippingFee = 0.0;
        List<Map<String, dynamic>> orderItemsData = [];

        // Calculate Totals
        for (var item in sellerItems) {
          orderSubtotal += item.totalPrice;

          // --- SHIPPING LOGIC ---
          if (isPickup) {
            orderShippingFee += 0.0; // Free if pickup
          } else {
            // Distance Logic
            double baseFee = item.livestock.shippingFee;
            String sellerLoc = item.livestock.location.toLowerCase().trim();
            bool isSameCity = cleanAddress.contains(sellerLoc) ||
                sellerLoc.contains(cleanAddress);

            if (isSameCity) {
              orderShippingFee += baseFee;
            } else {
              orderShippingFee += (baseFee + 500.0); // Distance Surcharge
            }
          }

          orderItemsData.add({
            'livestockId': item.livestock.id,
            'name': item.livestock.name,
            'quantity': item.quantity,
            'price': item.livestock.price,
            'shippingFee': item.livestock.shippingFee,
            'imagePath': item.livestock.imagePath,
          });
        }

        double finalOrderTotal = orderSubtotal + orderShippingFee;

        final orderRef = _firestore.collection('orders').doc();
        final chatRoomId = _generateChatRoomId(buyerId, sellerId);

        batch.set(orderRef, {
          'orderId': orderRef.id,
          'buyerId': buyerId,
          'sellerId': sellerId,
          'items': orderItemsData,
          'itemSubtotal': orderSubtotal,
          'shippingFee': orderShippingFee,
          'totalAmount': finalOrderTotal,
          'status': 'pending',
          'deliveryAddress':
              isPickup ? "CUSTOMER PICKUP" : deliveryAddress, // Mark as pickup
          'paymentMethod': paymentMethod,
          'isPickup': isPickup, // Save the flag
          'chatRoomId': chatRoomId,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Update Livestock Status
        for (var item in sellerItems) {
          final livestockRef =
              _firestore.collection('livestock').doc(item.livestock.id);
          batch.update(livestockRef, {
            'status': 'pending',
            'pendingBuyerId': buyerId,
          });
        }

        // Create Chat Room
        final chatRef = _firestore.collection('chats').doc(chatRoomId);
        batch.set(
            chatRef,
            {
              'participants': [buyerId, sellerId],
              'lastMessage':
                  'New Order: ₱${finalOrderTotal.toStringAsFixed(0)}',
              'lastMessageTime': FieldValue.serverTimestamp(),
              'hasUnread': true,
            },
            SetOptions(merge: true));
      }

      await batch.commit();
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
