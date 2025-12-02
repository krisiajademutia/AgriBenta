import 'package:flutter/material.dart';

class ProfileBottomBar extends StatelessWidget {
  final VoidCallback onLogout;
  final VoidCallback onSettings;

  const ProfileBottomBar({
    super.key,
    required this.onLogout,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
          TextButton.icon(
            onPressed: onSettings,
            icon: const Icon(Icons.settings, color: Color(0xFF0D4C2F)),
            label: const Text('Settings', style: TextStyle(color: Color(0xFF0D4C2F), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
