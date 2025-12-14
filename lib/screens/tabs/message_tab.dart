import 'package:flutter/material.dart';

class MessageTab extends StatelessWidget {
  const MessageTab({super.key});

  @override
  Widget build(BuildContext context) {
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
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text("No messages yet", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
