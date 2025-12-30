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
  // --- STATE VARIABLES ---
  bool _isSelectionMode = false;
  final Set<String> _selectedChatIds = {};

  // 1. Define Stream and ScrollController variables
  late Stream<QuerySnapshot> _chatStream;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 2. Initialize the Stream ONCE here
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

  // --- ACTIONS ---
  void _enterSelectionMode(String initialId) {
    setState(() {
      _isSelectionMode = true;
      _selectedChatIds.add(initialId);
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedChatIds.contains(id)) {
        _selectedChatIds.remove(id);
        if (_selectedChatIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedChatIds.add(id);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedChatIds.clear();
    });
  }

  Future<void> _deleteSelectedChats() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Conversations?"),
        content: Text(
            "Are you sure you want to delete ${_selectedChatIds.length} conversation(s)? This cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      final batch = FirebaseFirestore.instance.batch();
      final collection = FirebaseFirestore.instance.collection('chats');

      for (var id in _selectedChatIds) {
        batch.delete(collection.doc(id));
      }

      await batch.commit();
      _exitSelectionMode();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Conversations deleted")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Please login")));
    }

    return WillPopScope(
      onWillPop: () async {
        if (_isSelectionMode) {
          _exitSelectionMode();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F6F0),
        appBar:
            _isSelectionMode ? _buildSelectionAppBar() : _buildNormalAppBar(),
        body: StreamBuilder<QuerySnapshot>(
          stream: _chatStream, // 3. Use the stable stream variable
          builder: (context, snapshot) {
            if (snapshot.hasError) {
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

            // --- 4. DISPLAY LIST ---
            return ListView.builder(
              controller: _scrollController, // Attach controller
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

                final isSelected = _selectedChatIds.contains(doc.id);

                // Use KeyedSubtree to help Flutter preserve state per item
                return KeyedSubtree(
                  key: ValueKey(doc.id),
                  child: _ChatTile(
                    chatId: doc.id,
                    otherUserId: otherUserId,
                    lastMessage: data['lastMessage'] ?? '',
                    time: data['lastMessageTime'] as Timestamp?,
                    isSelectionMode: _isSelectionMode,
                    isSelected: isSelected,
                    onLongPress: () => _enterSelectionMode(doc.id),
                    onTap: () {
                      if (_isSelectionMode) {
                        _toggleSelection(doc.id);
                      } else {
                        // Pass null for normal nav, handle inside _ChatTile or here?
                        // Better to handle nav here to avoid passing context issues if async
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              chatId: doc.id,
                              otherUserId: otherUserId,
                              otherUserName:
                                  "Loading...", // ChatScreen fetches name anyway usually
                            ),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildNormalAppBar() {
    return AppBar(
      title: const Text("Messages",
          style:
              TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B4332))),
      backgroundColor: const Color(0xFFF9F6F0),
      elevation: 0,
      automaticallyImplyLeading: false,
    );
  }

  PreferredSizeWidget _buildSelectionAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.black),
        onPressed: _exitSelectionMode,
      ),
      title: Text(
        "${_selectedChatIds.length} Selected",
        style: const TextStyle(
            color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
      ),
      actions: [
        if (_selectedChatIds.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _deleteSelectedChats,
          ),
      ],
    );
  }
}

// --- HELPER WIDGET TO FETCH USER DETAILS ---
class _ChatTile extends StatelessWidget {
  final String chatId;
  final String otherUserId;
  final String lastMessage;
  final Timestamp? time;

  // Selection Props
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onLongPress;
  final VoidCallback onTap;

  const _ChatTile({
    required this.chatId,
    required this.otherUserId,
    required this.lastMessage,
    required this.time,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onLongPress,
    required this.onTap,
  });

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

        return Container(
          color: isSelected ? const Color(0xFF52B788).withOpacity(0.1) : null,
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            // --- LEADING: Checkbox OR User Avatar ---
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelectionMode)
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
                  radius: 25,
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
            onLongPress: onLongPress,
            onTap: onTap,
          ),
        );
      },
    );
  }
}
