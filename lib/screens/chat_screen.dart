import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
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
  final ImagePicker _picker = ImagePicker();
  final Dio _dio = Dio();
  final String imgbbApiKey = '7153706809c25e5afba9521b8a500079';

  late Stream<QuerySnapshot> _messagesStream;
  bool _isUploading = false;
  String _displayUserName = "";

  // --- NEW: AVATAR URLs ---
  String? _otherUserPhotoUrl;
  String? _myPhotoUrl;

  @override
  void initState() {
    super.initState();
    _displayUserName = widget.otherUserName;
    _fetchUserProfiles(); // Fetch photos
    _markAsRead();

    // Reverse order: Newest at bottom
    _messagesStream = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // --- 1. FETCH PHOTOS ---
  Future<void> _fetchUserProfiles() async {
    try {
      // Fetch Other User
      DocumentSnapshot otherDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.otherUserId)
          .get();

      // Fetch My Profile
      DocumentSnapshot myDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (mounted) {
        setState(() {
          if (otherDoc.exists) {
            final data = otherDoc.data() as Map<String, dynamic>;
            _displayUserName = data['name'] ?? widget.otherUserName;
            _otherUserPhotoUrl = data['profileImageUrl'];
          }
          if (myDoc.exists) {
            final myData = myDoc.data() as Map<String, dynamic>;
            _myPhotoUrl = myData['profileImageUrl'];
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching profiles: $e");
    }
  }

  // --- SMART DATE FORMATTER ---
  String _formatBubbleTime(Timestamp? timestamp) {
    if (timestamp == null) return "Sending...";
    final DateTime date = timestamp.toDate();
    final DateTime now = DateTime.now();

    if (now.year == date.year &&
        now.month == date.month &&
        now.day == date.day) {
      return DateFormat('h:mm a').format(date);
    }

    final yesterday = now.subtract(const Duration(days: 1));
    if (yesterday.year == date.year &&
        yesterday.month == date.month &&
        yesterday.day == date.day) {
      return "Yesterday, ${DateFormat('h:mm a').format(date)}";
    }

    return DateFormat('MMM d, h:mm a').format(date);
  }

  void _markAsRead() {
    FirebaseFirestore.instance.collection('chats').doc(widget.chatId).set({
      'unreadCounts': {
        currentUser.uid: 0,
      }
    }, SetOptions(merge: true));
  }

  void _sendMessage({String? text, String? imageUrl}) async {
    if ((text == null || text.trim().isEmpty) && imageUrl == null) return;

    final String messageText = text ?? "";
    _messageController.clear();

    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
        'senderId': currentUser.uid,
        'text': messageText,
        'imageUrl': imageUrl ?? "",
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .set({
        'lastMessage': imageUrl != null ? "Sent an image" : messageText,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'participants': [currentUser.uid, widget.otherUserId],
        'unreadCounts': {
          widget.otherUserId: FieldValue.increment(1),
          currentUser.uid: 0
        }
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error sending message: $e");
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 800,
      );
      if (pickedFile != null) {
        _uploadImageToImgBB(File(pickedFile.path));
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<void> _uploadImageToImgBB(File imageFile) async {
    setState(() => _isUploading = true);
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imageFile.path),
      });

      final response = await _dio.post(
        'https://api.imgbb.com/1/upload',
        data: formData,
        queryParameters: {'key': imgbbApiKey},
      );

      if (response.statusCode == 200 && response.data != null) {
        final String uploadedUrl = response.data['data']['url'];
        _sendMessage(imageUrl: uploadedUrl);
      }
    } catch (e) {
      debugPrint("ImgBB Upload Error: $e");
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _openFullScreenImage(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(url),
            ),
          ),
        ),
      ),
    );
  }

  // --- 2. BUILD AVATAR HELPER ---
  Widget _buildAvatar(String? url) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.grey[300],
      backgroundImage:
          (url != null && url.isNotEmpty) ? NetworkImage(url) : null,
      child: (url == null || url.isEmpty)
          ? const Icon(Icons.person, size: 20, color: Colors.grey)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      appBar: AppBar(
        title: Row(
          children: [
            // AppBar Avatar
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[200],
              backgroundImage: _otherUserPhotoUrl != null
                  ? NetworkImage(_otherUserPhotoUrl!)
                  : null,
              child: _otherUserPhotoUrl == null
                  ? const Icon(Icons.person, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _displayUserName,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF1B4332)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1B4332)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return const Center(child: Text("Error"));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final bool isMe = data['senderId'] == currentUser.uid;
                    final String text = data['text'] ?? "";
                    final String imageUrl = data['imageUrl'] ?? "";
                    final Timestamp? timestamp = data['createdAt'];

                    // --- 3. ROW LAYOUT FOR AVATARS ---
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        mainAxisAlignment: isMe
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        crossAxisAlignment:
                            CrossAxisAlignment.end, // Align avatar to bottom
                        children: [
                          // OTHER USER AVATAR (Left)
                          if (!isMe) ...[
                            _buildAvatar(_otherUserPhotoUrl),
                            const SizedBox(width: 8),
                          ],

                          // MESSAGE BUBBLE
                          Flexible(
                            child: Container(
                              padding: imageUrl.isNotEmpty
                                  ? const EdgeInsets.all(4)
                                  : const EdgeInsets.all(12),
                              constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.70),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? const Color(0xFF52B788)
                                    : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: isMe
                                      ? const Radius.circular(16)
                                      : const Radius.circular(4),
                                  bottomRight: isMe
                                      ? const Radius.circular(4)
                                      : const Radius.circular(16),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (imageUrl.isNotEmpty)
                                    GestureDetector(
                                      onTap: () =>
                                          _openFullScreenImage(imageUrl),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          imageUrl,
                                          loadingBuilder:
                                              (context, child, loading) {
                                            if (loading == null) return child;
                                            return Container(
                                              height: 200,
                                              width: 200,
                                              color: Colors.grey[200],
                                              child: const Center(
                                                  child:
                                                      CircularProgressIndicator()),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  if (text.isNotEmpty)
                                    Padding(
                                      padding: imageUrl.isNotEmpty
                                          ? const EdgeInsets.only(
                                              top: 8, left: 4, right: 4)
                                          : EdgeInsets.zero,
                                      child: Text(
                                        text,
                                        style: TextStyle(
                                          color: isMe
                                              ? Colors.white
                                              : const Color(0xFF1B4332),
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: Text(
                                      _formatBubbleTime(timestamp),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isMe
                                            ? Colors.white.withOpacity(0.7)
                                            : Colors.grey[500],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // MY AVATAR (Right)
                          if (isMe) ...[
                            const SizedBox(width: 8),
                            _buildAvatar(_myPhotoUrl),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_isUploading)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey[100],
              child: const Row(
                children: [
                  SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 10),
                  Text("Uploading image..."),
                ],
              ),
            ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.camera_alt, color: Colors.grey),
              onPressed: () => _pickImage(ImageSource.camera),
            ),
            IconButton(
              icon: const Icon(Icons.image, color: Colors.grey),
              onPressed: () => _pickImage(ImageSource.gallery),
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  filled: true,
                  fillColor: const Color(0xFFF0F7F4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: const Color(0xFF52B788),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: () => _sendMessage(text: _messageController.text),
              ),
            )
          ],
        ),
      ),
    );
  }
}
