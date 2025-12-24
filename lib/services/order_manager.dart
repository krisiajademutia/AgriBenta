// lib/services/order_manager.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/livestock_model.dart';

class OrderManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  // Generate consistent chat room ID (sorted to avoid duplicates)
  String _generateChatRoomId(String uid1, String uid2) {
    final List<String> ids = [uid1, uid2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Future<bool> createDirectOrder(
      Livestock livestock, BuildContext context) async {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in to buy")),
      );
      Navigator.pushNamed(context, '/login');
      return false;
    }

    if (currentUser!.uid == livestock.sellerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You cannot buy your own listing")),
      );
      return false;
    }

    try {
      final batch = _firestore.batch();

      // 1. Create order document
      final orderRef = _firestore.collection('orders').doc();
      final chatRoomId =
          _generateChatRoomId(currentUser!.uid, livestock.sellerId);

      batch.set(orderRef, {
        'orderId': orderRef.id,
        'buyerId': currentUser!.uid,
        'sellerId': livestock.sellerId,
        'livestockId': livestock.id,
        'livestockName': livestock.name,
        'price': livestock.price,
        'imagePath': livestock.imagePath,
        'status': 'pending', // pending → confirmed → completed
        'chatRoomId': chatRoomId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Update livestock status to prevent double-selling
      final livestockRef = _firestore.collection('livestock').doc(livestock.id);
      batch.update(livestockRef, {
        'status': 'pending',
        'pendingBuyerId': currentUser!.uid,
      });

      // 3. Optional: Create initial chat room if not exists
      final chatRef = _firestore.collection('chats').doc(chatRoomId);
      batch.set(
          chatRef,
          {
            'participants': [currentUser!.uid, livestock.sellerId],
            'lastMessage': 'Buyer expressed interest via Buy Now',
            'lastMessageTime': FieldValue.serverTimestamp(),
            'livestockId': livestock.id,
          },
          SetOptions(merge: true));

      await batch.commit();

      if (!context.mounted) return true;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Purchase initiated! Opening chat with seller..."),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Navigate to chat (you can create ChatScreen later)
      /* Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatRoomId: chatRoomId,
            sellerId: livestock.sellerId,
            livestockName: livestock.name,
            livestockImage: livestock.imagePath,
          ),
        ),
      );*/

      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to buy: $e")),
        );
      }
      return false;
    }
  }
}
