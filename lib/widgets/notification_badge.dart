import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/notification_screen.dart'; // Make sure this matches your file name

class NotificationBadge extends StatelessWidget {
  const NotificationBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    const Color textDark = Color(0xFF1B4332);

    return StreamBuilder<QuerySnapshot>(
      // Listen to unread notifications for the current user
      stream: user != null
          ? FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('notifications')
              .where('isRead', isEqualTo: false)
              .snapshots()
          : const Stream.empty(),
      builder: (context, snapshot) {
        int unreadCount = 0;
        if (snapshot.hasData) {
          unreadCount = snapshot.data!.docs.length;
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const NotificationScreen()),
                );
              },
              icon: const Icon(Icons.notifications_outlined,
                  color: textDark, size: 26),
            ),

            // THE RED DOT
            if (unreadCount > 0)
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
