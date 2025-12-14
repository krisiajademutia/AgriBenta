import 'package:flutter/material.dart';

// Imports
import 'tabs/marketplace_tab.dart';
import 'tabs/message_tab.dart';
import 'tabs/transaction_tab.dart';
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
    const TransactionTab(),
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

      // 👇 REMOVED THE FLOATING ACTION BUTTON (ADD BUTTON) HERE

      // UPDATED BOTTOM NAV
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 20,
        shadowColor: Colors.black.withOpacity(0.1),
        height: 70,
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceAround, // Evenly spaces the 4 icons
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

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? iconOn : iconOff,
              color: isSelected ? brandGreen : Colors.grey.shade400,
              size: 26,
            ),
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
