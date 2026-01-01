import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <--- Added
import 'package:firebase_auth/firebase_auth.dart'; // <--- Added
import 'tabs/marketplace_tab.dart';
import 'tabs/message_tab.dart';
import 'tabs/orders_tab.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const MarketplaceTab(),
    const MessageTab(),
    const OrdersTab(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    const Color bgCream = Color(0xFFF9F6F0);

    return Scaffold(
      backgroundColor: bgCream,
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 20,
        shadowColor: Colors.black.withOpacity(0.1),
        height: 70,
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
                0, Icons.storefront_outlined, Icons.storefront_rounded, "Home"),
            _buildNavItem(1, Icons.chat_bubble_outline_rounded,
                Icons.chat_bubble_rounded, "Message"),
            _buildNavItem(2, Icons.receipt_long_outlined,
                Icons.receipt_long_rounded, "Orders"),
            _buildNavItem(3, Icons.person_outline_rounded, Icons.person_rounded,
                "Profile"),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
      int index, IconData iconOff, IconData iconOn, String label) {
    final isSelected = _currentIndex == index;
    const Color brandGreen = Color(0xFF52B788);

    // --- 1. BADGE LOGIC ---
    // We only want to show the badge for the "Message" tab (index 1)
    Widget iconWidget = Icon(
      isSelected ? iconOn : iconOff,
      color: isSelected ? brandGreen : Colors.grey.shade400,
      size: 26,
    );

    if (index == 1) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Wrap the icon in a StreamBuilder to listen for unread messages
        iconWidget = StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chats')
              .where('participants', arrayContains: currentUser.uid)
              .snapshots(),
          builder: (context, snapshot) {
            int unreadTotal = 0;

            if (snapshot.hasData) {
              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final unreadCounts =
                    data['unreadCounts'] as Map<String, dynamic>?;
                // Add up the user's unread count from each chat
                unreadTotal += (unreadCounts?[currentUser.uid] ?? 0) as int;
              }
            }

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? iconOn : iconOff,
                  color: isSelected ? brandGreen : Colors.grey.shade400,
                  size: 26,
                ),
                if (unreadTotal > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.red, // Badge Color
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        unreadTotal > 9 ? '9+' : '$unreadTotal',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9, // Small font for the badge
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

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- 2. USE THE MODIFIED ICON WIDGET ---
            iconWidget,
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? brandGreen : Colors.grey.shade400,
              ),
            )
          ],
        ),
      ),
    );
  }
}
