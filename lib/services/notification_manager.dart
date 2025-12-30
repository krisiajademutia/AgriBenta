import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationManager {
  static Future<void> sendNotification({
    required String receiverId,
    required String title,
    required String body,
    required String type, // 'order', 'message', 'system'
    String? referenceId, // <--- NEW: ID of the Order or Chat Room
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(receiverId)
          .collection('notifications')
          .add({
        'title': title,
        'body': body,
        'type': type,
        'referenceId': referenceId, // <--- Save it here
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error sending notification: $e");
    }
  }

  // --- NEW: Function to Mark All as Read ---
  static Future<void> markAllAsRead(String userId) async {
    final batch = FirebaseFirestore.instance.batch();

    // Get all unread notifications
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    if (snapshot.docs.isEmpty) return;

    // Add updates to batch
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    // Commit all changes at once (Cheaper & Faster)
    await batch.commit();
  }
}
