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

  // --- IMGBB CONFIGURATION ---
  final String imgbbApiKey = '7153706809c25e5afba9521b8a500079';
  final Dio _dio = Dio();

  late Stream<QuerySnapshot> _messagesStream;
  bool _isUploading = false;

  // New variable to hold the dynamic name
  String _displayUserName = "";

  @override
  void initState() {
    super.initState();
    // 1. Initialize with the passed name
    _displayUserName = widget.otherUserName;

    // 2. If the passed name is placeholder, fetch the real one
    if (_displayUserName == "Loading..." || _displayUserName.isEmpty) {
      _fetchUserName();
    }

    _messagesStream = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // --- NEW: FETCH NAME IF MISSING ---
  Future<void> _fetchUserName() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.otherUserId)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          final data = doc.data() as Map<String, dynamic>;
          _displayUserName = data['name'] ?? "User";
        });
      }
    } catch (e) {
      debugPrint("Error fetching user name: $e");
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- IMAGE PICKER & UPLOAD ---
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file =
          await _picker.pickImage(source: source, imageQuality: 50);
      if (file != null) {
        await _uploadToImgBB(File(file.path));
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<void> _uploadToImgBB(File file) async {
    setState(() => _isUploading = true);
    try {
      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        "key": imgbbApiKey,
        "image": await MultipartFile.fromFile(file.path, filename: fileName),
      });

      Response response = await _dio.post(
        "https://api.imgbb.com/1/upload",
        data: formData,
      );

      if (response.statusCode == 200 && response.data != null) {
        String imageUrl = response.data['data']['url'];
        await _sendMessage(fileUrl: imageUrl, type: 'image');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // --- SEND MESSAGE ---
  Future<void> _sendMessage(
      {String? text, String? fileUrl, String type = 'text'}) async {
    if ((text == null || text.trim().isEmpty) && fileUrl == null) return;

    final String content = text?.trim() ?? '';
    _messageController.clear();

    try {
      final batch = FirebaseFirestore.instance.batch();
      final messageRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .doc();

      final messageData = {
        'senderId': currentUser.uid,
        'text': content,
        'fileUrl': fileUrl,
        'type': type,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      };

      batch.set(messageRef, messageData);

      final chatRef =
          FirebaseFirestore.instance.collection('chats').doc(widget.chatId);
      String previewText = content;
      if (type == 'image') previewText = "📷 Sent a photo";

      batch.set(
          chatRef,
          {
            'lastMessage': previewText,
            'lastMessageTime': FieldValue.serverTimestamp(),
            'participants': [currentUser.uid, widget.otherUserId],
            'users':
                FieldValue.arrayUnion([currentUser.uid, widget.otherUserId])
          },
          SetOptions(merge: true));

      await batch.commit();

      if (_scrollController.hasClients) {
        _scrollController.animateTo(0,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    } catch (e) {
      debugPrint("Send error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      appBar: AppBar(
        // Use the local state variable _displayUserName instead of widget.otherUserName
        title: Text(_displayUserName,
            style: const TextStyle(color: Color(0xFF1B4332))),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF1B4332)),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return const Center(child: Text("Error loading chats"));
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
                        Text("Say hi!",
                            style: TextStyle(color: Colors.grey[400])),
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
                    return _buildMessageBubble(msg);
                  },
                );
              },
            ),
          ),
          if (_isUploading)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.black12,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 8),
                  Text("Uploading image...", style: TextStyle(fontSize: 12))
                ],
              ),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final isMe = data['senderId'] == currentUser.uid;
    final time = (data['createdAt'] as Timestamp?)?.toDate();
    final type = data['type'] ?? 'text';
    final fileUrl = data['fileUrl'];
    final text = data['text'] ?? '';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF52B788) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(12),
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
            if (type == 'image' && fileUrl != null)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  fileUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 150,
                      width: 200,
                      color: Colors.black12,
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (ctx, _, __) => const Padding(
                      padding: EdgeInsets.all(20),
                      child: Icon(Icons.broken_image, color: Colors.grey)),
                ),
              )
            else if (text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 10),
                child: Text(
                  text,
                  style: TextStyle(
                      color: isMe ? Colors.white : const Color(0xFF1B4332),
                      fontSize: 16),
                ),
              ),
            if (time != null)
              Padding(
                padding:
                    const EdgeInsets.only(right: 8, bottom: 4, top: 4, left: 8),
                child: Text(
                  DateFormat('h:mm a').format(time),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white70 : Colors.grey[400],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
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
