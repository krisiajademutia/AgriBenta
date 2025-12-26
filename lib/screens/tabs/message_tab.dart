import 'package:agribenta/screens/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MessageTab extends StatelessWidget {
  const MessageTab({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Please login")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      appBar: AppBar(
        title: const Text("Messages",
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFF1B4332))),
        backgroundColor: const Color(0xFFF9F6F0),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUser.uid)
            .orderBy('lastMessageTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // --- 1. HANDLE ERRORS (Likely Index Error) ---
          if (snapshot.hasError) {
            // If you see this error, check debug console for the Index Link!
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF52B788)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text("No messages yet",
                      style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            );
          }

          // --- 2. DISPLAY LIST OF CONVERSATIONS ---
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              // Find the OTHER user's ID
              final List<dynamic> participants = data['participants'];
              final String otherUserId = participants.firstWhere(
                (id) => id != currentUser.uid,
                orElse: () => "Unknown",
              );

              return _ChatTile(
                chatId: doc.id,
                otherUserId: otherUserId,
                lastMessage: data['lastMessage'] ?? '',
                time: data['lastMessageTime'] as Timestamp?,
              );
            },
          );
        },
      ),
    );
  }
}

// --- HELPER WIDGET TO FETCH USER DETAILS ---
class _ChatTile extends StatelessWidget {
  final String chatId;
  final String otherUserId;
  final String lastMessage;
  final Timestamp? time;

  const _ChatTile(
      {required this.chatId,
      required this.otherUserId,
      required this.lastMessage,
      required this.time});

  @override
  Widget build(BuildContext context) {
    // Fetch the other user's name/photo from 'users' collection
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
      builder: (context, snapshot) {
        String name = "Loading...";
        String? photoUrl;

        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          name = userData['name'] ?? "User";
          photoUrl = userData['profileImageUrl'];
        }

        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: CircleAvatar(
            radius: 25,
            backgroundColor: Colors.grey[200],
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null
                ? Icon(Icons.person, color: Colors.grey[400])
                : null,
          ),
          title: Text(
            name,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFF1B4332)),
          ),
          subtitle: Text(
            lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey[600]),
          ),
          trailing: time != null
              ? Text(
                  DateFormat('h:mm a').format(time!.toDate()),
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                )
              : null,
          onTap: () {
            // Navigate to the Chat Screen we just created
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  chatId: chatId,
                  otherUserId: otherUserId,
                  otherUserName: name,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
