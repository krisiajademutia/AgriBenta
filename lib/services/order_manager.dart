import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/cart_manager.dart';
// IMPORT THIS (Adjust path if needed)
import 'notification_manager.dart';

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
    required bool isPickup,
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

      // --- LIST TO STORE NOTIFICATIONS TO SEND LATER ---
      List<Map<String, String>> pendingNotifications = [];

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
            orderShippingFee += 0.0;
          } else {
            double baseFee = item.livestock.shippingFee;
            String sellerLoc = item.livestock.location.toLowerCase().trim();
            bool isSameCity = cleanAddress.contains(sellerLoc) ||
                sellerLoc.contains(cleanAddress);

            if (isSameCity) {
              orderShippingFee += baseFee;
            } else {
              orderShippingFee += (baseFee + 500.0);
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
          'deliveryAddress': isPickup ? "CUSTOMER PICKUP" : deliveryAddress,
          'paymentMethod': paymentMethod,
          'isPickup': isPickup,
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

        // --- PREPARE NOTIFICATION DATA ---
        // We prepare it here but send it AFTER the batch commits successfully
        final firstItemName = sellerItems.first.livestock.name;
        final itemCount = sellerItems.length;
        final itemLabel = itemCount > 1
            ? "$firstItemName + ${itemCount - 1} others"
            : firstItemName;

        pendingNotifications.add({
          'receiverId': sellerId,
          'title': 'New Order Received! 📦',
          'body':
              'You have a new order for $itemLabel. Total: ₱${finalOrderTotal.toStringAsFixed(0)}',
          'type': 'order'
        });
      }

      // 3. COMMIT THE DATABASE CHANGES
      await batch.commit();

      // 4. SEND NOTIFICATIONS (Now that we know the order is saved)
      for (var note in pendingNotifications) {
        await NotificationManager.sendNotification(
          receiverId: note['receiverId']!,
          title: note['title']!,
          body: note['body']!,
          type: note['type']!,
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
