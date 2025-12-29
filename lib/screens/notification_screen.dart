import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Please login")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style:
              TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B4332)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          // Optional: "Mark all as read" button could go here
          IconButton(
            icon: const Icon(Icons.done_all, color: Color(0xFF52B788)),
            onPressed: () {
              // Logic to update all 'isRead' to true
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .limit(50) // Keep it efficient
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF52B788)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none,
                      size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text("No notifications yet",
                      style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final date = (data['createdAt'] as Timestamp?)?.toDate();
              final isRead = data['isRead'] ?? false;

              // Determine Icon based on type
              IconData icon = Icons.info;
              Color iconColor = Colors.blue;

              if (data['type'] == 'order') {
                icon = Icons.shopping_bag;
                iconColor = const Color(0xFF52B788);
              } else if (data['type'] == 'message') {
                icon = Icons.chat;
                iconColor = Colors.orange;
              }

              return Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  doc.reference.delete();
                },
                child: Container(
                  color: isRead ? const Color(0xFFF9F6F0) : Colors.white,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: iconColor.withOpacity(0.1),
                      child: Icon(icon, color: iconColor, size: 20),
                    ),
                    title: Text(
                      data['title'] ?? 'Notification',
                      style: TextStyle(
                        fontWeight:
                            isRead ? FontWeight.normal : FontWeight.bold,
                        color: const Color(0xFF1B4332),
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          data['body'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (date != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Text(
                              _formatTime(date),
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey[400]),
                            ),
                          ),
                      ],
                    ),
                    onTap: () {
                      // 1. Mark as read immediately
                      doc.reference.update({'isRead': true});

                      // 2. Navigate based on 'type' (Optional future step)
                      // if (data['type'] == 'order') Navigator.push(...)
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return "${diff.inMinutes}m ago";
    } else if (diff.inHours < 24) {
      return "${diff.inHours}h ago";
    } else {
      return DateFormat('MMM d').format(date);
    }
  }
}
