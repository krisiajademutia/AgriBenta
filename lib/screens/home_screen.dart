// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:agribenta/widgets/home_widgets/livestock_filter_wrapper.dart';
import 'package:agribenta/widgets/home_widgets/home_section_search.dart';
import 'package:agribenta/widgets/home_widgets/home_section_categories.dart';
import 'package:agribenta/screens/notification_screen.dart';
import 'package:agribenta/screens/cart_screen.dart';
import 'package:agribenta/screens/profile_screen.dart'; // ⬅️ NEW IMPORT

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int notificationCount = 5;

  // This controls the category filter, only used on the Home tab (index 0)
  String _selectedCategoryName = 'All';

  void _updateSelectedCategory(String newCategoryName) {
    setState(() {
      _selectedCategoryName = newCategoryName;
    });
  }

  late final List<Widget> _widgetOptions = <Widget>[
    _HomeContent(
      selectedCategoryName: _selectedCategoryName,
      updateSelectedCategory: _updateSelectedCategory,
    ),
    // Placeholder screens for other tabs
    const Center(child: Text("Message Screen Content", style: TextStyle(color: Colors.white, fontSize: 20))), 
    const Center(child: Text("Transactions Screen Content", style: TextStyle(color: Colors.white, fontSize: 20))), 
    const ProfileScreen(), // ⬅️ The new Profile screen
  ];

  @override
  Widget build(BuildContext context) {
    final isHomeTab = _selectedIndex == 0;  
    return Scaffold(
      backgroundColor: isHomeTab ? const Color(0xFF0D4C2F) : const Color(0xFFF5F5DC),

      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: isHomeTab ? Colors.transparent : const Color(0xFF0D4C2F),
        foregroundColor: isHomeTab ? Colors.yellow : Colors.white,
        title: Text(
          isHomeTab ? "AgriBenta" : _getAppBarTitle(_selectedIndex),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isHomeTab ? Colors.yellow : Colors.white,
            fontSize: 24,
            letterSpacing: 1,
          ),
        ),
        actions: [
          // Notifications are still visible on all screens
          _buildNotificationIcon(context),
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
            icon: Icon(Icons.shopping_cart_outlined, color: isHomeTab ? Colors.yellow : Colors.white, size: 28),
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        backgroundColor: const Color(0xFF0D4C2F), 
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: "Message"),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: "Transactions"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
        ],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 1: return "Messages";
      case 2: return "Transactions";
      case 3: return "My Profile";
      default: return "AgriBenta";
    }
  }

  Widget _buildNotificationIcon(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
          },
          icon: const Icon(Icons.notifications_outlined, color: Colors.yellow, size: 28),
        ),
        if (notificationCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: const Border.symmetric(
                  horizontal: BorderSide(color: Colors.white, width: 1.5),
                  vertical: BorderSide(color: Colors.white, width: 1.5),
                ),
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Center(
                child: Text(
                  notificationCount > 99 ? "99+" : notificationCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HomeContent extends StatelessWidget {
  final String selectedCategoryName;
  final Function(String) updateSelectedCategory;

  const _HomeContent({
    required this.selectedCategoryName,
    required this.updateSelectedCategory,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final statusBarHeight = mediaQuery.padding.top;
    final appBarHeight = AppBar().preferredSize.height;
    const bottomBarHeight = kBottomNavigationBarHeight;

    final minContentHeight = screenHeight - appBarHeight - statusBarHeight - bottomBarHeight;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0D4C2F),
            Color(0xFF1E6A3F),
            Color(0xFFF5F5DC),
          ],
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minContentHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20.0,
            20.0,
            20.0,
            kBottomNavigationBarHeight + 20.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionSearch(),
              const SizedBox(height: 24),
              SectionCategories(
                onCategorySelected: updateSelectedCategory,
                selectedCategoryName: selectedCategoryName,
              ),
              const SizedBox(height: 32),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: LivestockFilterWrapper(
                  // The key forces the widget to be replaced when the category changes.
                  key: ValueKey('livestock-wrapper-$selectedCategoryName'), 
                  selectedCategoryName: selectedCategoryName,
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}