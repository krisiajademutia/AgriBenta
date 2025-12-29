import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final currentUser = FirebaseAuth.instance.currentUser!;

  // Define the stream variable here so it doesn't reload the UI every time
  late Stream<QuerySnapshot> _messagesStream;

  @override
  void initState() {
    super.initState();
    // Initialize the stream ONCE when the screen opens
    _messagesStream = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- SEND MESSAGE FUNCTION (Optimized: No Loading Spinner) ---
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text.trim();

    // Clear input immediately so it feels instant
    _messageController.clear();

    try {
      final batch = FirebaseFirestore.instance.batch();

      // 1. Prepare Message
      final messageRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .doc();

      batch.set(messageRef, {
        'senderId': currentUser.uid,
        'text': messageText,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // 2. Update Chat Room (Inbox)
      final chatRef =
          FirebaseFirestore.instance.collection('chats').doc(widget.chatId);

      batch.set(
          chatRef,
          {
            'lastMessage': messageText,
            'lastMessageTime': FieldValue.serverTimestamp(),
            'participants': [currentUser.uid, widget.otherUserId],
            'users':
                FieldValue.arrayUnion([currentUser.uid, widget.otherUserId])
          },
          SetOptions(merge: true));

      // 3. Send to Database (Background)
      await batch.commit();

      // 4. Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    } catch (e) {
      // Only show error if it actually fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Failed to send: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      appBar: AppBar(
        title: Text(widget.otherUserName,
            style: const TextStyle(color: Color(0xFF1B4332))),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF1B4332)),
      ),
      body: Column(
        children: [
          // --- MESSAGES LIST ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messagesStream, // Use the stable stream variable
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("Something went wrong"));
                }

                // Show loading only on FIRST load, not every message
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 8),
                        Text(
                          "Say hi to ${widget.otherUserName}!",
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final msg = snapshot.data!.docs[index];
                    final isMe = msg['senderId'] == currentUser.uid;
                    final time = (msg['createdAt'] as Timestamp?)?.toDate();

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFF52B788) : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft:
                                isMe ? const Radius.circular(12) : Radius.zero,
                            bottomRight:
                                isMe ? Radius.zero : const Radius.circular(12),
                          ),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              msg['text'],
                              style: TextStyle(
                                  color: isMe
                                      ? Colors.white
                                      : const Color(0xFF1B4332),
                                  fontSize: 16),
                            ),
                            if (time != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  DateFormat('h:mm a').format(time),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isMe
                                        ? Colors.white70
                                        : Colors.grey[400],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // --- INPUT FIELD ---
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        filled: true,
                        fillColor: const Color(0xFFF0F7F4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF52B788),
                    child: IconButton(
                      icon:
                          const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _sendMessage,
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
