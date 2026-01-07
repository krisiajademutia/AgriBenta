import 'package:agribenta/screens/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MessageTab extends StatefulWidget {
  const MessageTab({super.key});

  @override
  State<MessageTab> createState() => _MessageTabState();
}

class _MessageTabState extends State<MessageTab> {
  bool _isSelectionMode = false;
  final Set<String> _selectedChatIds = {};
  late Stream<QuerySnapshot> _chatStream;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _chatStream = FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: currentUser.uid)
          .orderBy('lastMessageTime', descending: true)
          .snapshots();
    } else {
      _chatStream = const Stream.empty();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // --- SMART DATE FORMATTER FOR LIST ---
  String _formatListDate(Timestamp? timestamp) {
    if (timestamp == null) return "";
    final DateTime date = timestamp.toDate();
    final DateTime now = DateTime.now();

    // Check if it's today
    if (now.year == date.year &&
        now.month == date.month &&
        now.day == date.day) {
      return DateFormat('h:mm a').format(date); // 9:47 PM
    }

    // Check if it's yesterday
    final yesterday = now.subtract(const Duration(days: 1));
    if (yesterday.year == date.year &&
        yesterday.month == date.month &&
        yesterday.day == date.day) {
      return "Yesterday";
    }

    // Older
    return DateFormat('MM/dd/yy').format(date); // 10/24/24
  }

  Future<void> _deleteSelectedChats() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Chats"),
        content: Text("Delete ${_selectedChatIds.length} selected chats?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (shouldDelete == true) {
      for (var id in _selectedChatIds) {
        await FirebaseFirestore.instance.collection('chats').doc(id).delete();
      }
      setState(() {
        _selectedChatIds.clear();
        _isSelectionMode = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isSelectionMode ? "${_selectedChatIds.length} Selected" : "Messages",
          style: const TextStyle(
            color: Color(0xFF1B4332),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteSelectedChats,
            ),
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: () {
                setState(() {
                  _isSelectionMode = false;
                  _selectedChatIds.clear();
                });
              },
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _chatStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            controller: _scrollController,
            itemCount: docs.length,
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              data['chatId'] = doc.id;

              return _buildChatTile(data);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No messages yet",
            style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTile(Map<String, dynamic> data) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final participants = List<String>.from(data['participants'] ?? []);

    final otherUserId = participants.firstWhere(
      (id) => id != currentUser?.uid,
      orElse: () => 'Unknown',
    );

    final unreadCounts = data['unreadCounts'] as Map<String, dynamic>?;
    final int myUnreadCount = unreadCounts?[currentUser?.uid] ?? 0;
    final bool hasUnread = myUnreadCount > 0;

    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final name = userData?['name'] ?? 'Unknown User';
        final photoUrl = userData?['profileImageUrl'];

        final lastMessage = data['lastMessage'] ?? '';
        final Timestamp? time = data['lastMessageTime'];
        final chatId = data['chatId'] ?? 'unknown_chat';

        final isSelected = _selectedChatIds.contains(chatId);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            tileColor: hasUnread ? const Color(0xFFF0F7F4) : Colors.white,
            leading: Stack(
              children: [
                if (_isSelectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: Icon(
                      isSelected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isSelected ? const Color(0xFF52B788) : Colors.grey,
                    ),
                  ),
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey[200],
                  backgroundImage:
                      photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null
                      ? Icon(Icons.person, color: Colors.grey[400])
                      : null,
                ),
              ],
            ),
            title: Text(
              name,
              style: TextStyle(
                  fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                  color: const Color(0xFF1B4332)),
            ),
            subtitle: Text(
              lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: hasUnread ? const Color(0xFF1B4332) : Colors.grey[600],
                fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (time != null)
                  Text(
                    _formatListDate(time), // USE THE SMART FORMATTER
                    style: TextStyle(
                        fontSize: 12,
                        color: hasUnread
                            ? const Color(0xFF52B788)
                            : Colors.grey[400],
                        fontWeight:
                            hasUnread ? FontWeight.bold : FontWeight.normal),
                  ),
                if (hasUnread) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFD9534F),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      myUnreadCount > 9 ? '9+' : myUnreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ]
              ],
            ),
            onLongPress: () {
              setState(() {
                _isSelectionMode = true;
                _selectedChatIds.add(chatId);
              });
            },
            onTap: () {
              if (_isSelectionMode) {
                setState(() {
                  if (isSelected) {
                    _selectedChatIds.remove(chatId);
                    if (_selectedChatIds.isEmpty) _isSelectionMode = false;
                  } else {
                    _selectedChatIds.add(chatId);
                  }
                });
              } else {
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
              }
            },
          ),
        );
      },
    );
  }
}
