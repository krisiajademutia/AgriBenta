import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationManager {
  // Call this function whenever you want to notify a user
  static Future<void> sendNotification({
    required String receiverId,
    required String title,
    required String body,
    required String type, // 'order', 'message', 'system'
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
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error sending notification: $e");
    }
  }
}
