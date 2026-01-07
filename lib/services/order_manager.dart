import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/cart_model.dart';
import 'notification_manager.dart';
import 'package:agribenta/services/shipping_calculator.dart';

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
      String buyerProvince = '';
      String buyerRegion = '';

      if (!isPickup) {
        // We assume format: "Region, Province, City, Brgy, Street"
        // (Matching how you save it in CheckoutScreen)
        List<String> addressParts = deliveryAddress
            .split(',')
            .map((e) => e.trim().toLowerCase())
            .toList();

        if (addressParts.isNotEmpty) {
          // The last item is the Region
          buyerRegion = addressParts.last;
        }
        if (addressParts.length >= 2) {
          // Second to last is Province
          buyerProvince = addressParts[addressParts.length - 2];
        }
        if (addressParts.length >= 3) {
          // Third to last is City
          buyerCity = addressParts[addressParts.length - 3];
        }
      }

      // CHECK & DECREMENT STOCK
      // 1. Loop through every item the user is buying
      for (var item in items) {
        // 2. Get the latest data from the database (Fresh Fetch)
        final livestockRef =
            _firestore.collection('livestock').doc(item.livestock.id);
        final livestockDoc = await livestockRef.get();
        if (!livestockDoc.exists) {
          throw "One of the items no longer exists.";
        }
        final data = livestockDoc.data() as Map<String, dynamic>;

        // 3. Handling VARIANTS (e.g. "Small 50kg")
        if (item.selectedWeight != null && data['variants'] != null) {
          // --- VARIANT LOGIC ---
          List<dynamic> variants = List.from(data['variants']);
          bool variantFound = false;

          // Loop to find the specific variant (e.g. Find "50kg")
          for (var i = 0; i < variants.length; i++) {
            if (variants[i]['weight'] == item.selectedWeight) {
              // Match variant by weight/name
              int currentQty = variants[i]['quantity'] ?? 0;
              if (currentQty < item.quantity) {
                throw "Not enough stock for ${item.livestock.name} (${item.selectedWeight})"; //check for availability
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
          // 1. Recalculate TOTAL stock from ALL variants
          int newTotalStock = 0;
          for (var v in variants) {
            newTotalStock += (v['quantity'] as num).toInt();
          }
          // If total stock is 0, status becomes 'sold'. Otherwise, it stays 'active'.
          String newStatus =
              newTotalStock <= 0 ? 'sold' : (data['status'] ?? 'active');
          // Update EVERYTHING (Variants + Total Quantity + Status)
          batch.update(livestockRef, {
            'variants': variants,
            'quantity': newTotalStock,
            'status': newStatus,
          });
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

      // Group items by Seller for Order Creation
      Map<String, List<CartItem>> itemsBySeller = {};
      for (var item in items) {
        final sellerId = item.livestock.sellerId;
        if (!itemsBySeller.containsKey(sellerId)) {
          itemsBySeller[sellerId] = [];
        }
        itemsBySeller[sellerId]!.add(item);
      }

      List<Map<String, dynamic>> pendingNotifications = [];

      // Create Order per Seller
      for (var entry in itemsBySeller.entries) {
        final sellerId = entry.key;
        final sellerItems = entry.value;

        double sellerItemTotal = 0.0;
        double sellerShippingTotal = 0.0;

        for (var item in sellerItems) {
          sellerItemTotal += item.selectedPrice * item.quantity;

          if (!isPickup) {
            //get seller input shipping fee
            double baseFee = item.livestock.shippingFee;
            // --- CALL THE NEW HELPER --- 📞
            double surcharge = ShippingCalculator.calculateSurcharge(
              buyerCity: buyerCity,
              buyerProvince: buyerProvince,
              buyerRegion: buyerRegion,
              sellerLocationString: item.livestock.location,
            );
            // final shipping for THIS item
            sellerShippingTotal += (baseFee + surcharge);
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
