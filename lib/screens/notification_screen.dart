// lib/screens/notification_screen.dart
import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  final List<Map<String, dynamic>> notifications = const [
    {
      "title": "Item Sold!",
      "message": "Your Sapi Limousin has been bought for ₱85,000,000",
      "time": "2 min ago",
      "icon": Icons.check_circle,
      "color": Colors.green,
    },
    {
      "title": "Purchase Successful!",
      "message": "You bought Kambing PE for ₱18,500,000",
      "time": "15 min ago",
      "icon": Icons.shopping_bag,
      "color": Colors.blue,
    },
    {
      "title": "Payment Received",
      "message": "You received ₱18,500,000 from Juan Dela Cruz",
      "time": "1 hour ago",
      "icon": Icons.account_balance_wallet,
      "color": Colors.amber,
    },
    {
      "title": "New Listing Nearby",
      "message": "3-year-old Carabao listed 10km from you",
      "time": "2 hours ago",
      "icon": Icons.location_on,
      "color": Colors.orange,
    },
    {
      "title": "Listing Expired",
      "message": "Your Ayam KUB listing has expired",
      "time": "Yesterday",
      "icon": Icons.timer_off,
      "color": Colors.red,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A3A1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E4F2A),
        title: const Text("Notifications", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: notifications.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 80, color: Colors.white54),
                  SizedBox(height: 16),
                  Text("No notifications yet", style: TextStyle(color: Colors.white70, fontSize: 18)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      radius: 26,
                      backgroundColor: notif["color"],
                      child: Icon(notif["icon"], color: Colors.white, size: 28),
                    ),
                    title: Text(notif["title"], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(notif["message"], style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 8),
                        Text(notif["time"], style: const TextStyle(color: Colors.white60, fontSize: 12)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}