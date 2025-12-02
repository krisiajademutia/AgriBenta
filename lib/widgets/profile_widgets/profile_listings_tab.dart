import 'package:flutter/material.dart';

class ProfileListingsTab extends StatelessWidget {
  final VoidCallback onAddListing;

  const ProfileListingsTab({super.key, required this.onAddListing});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('No listings yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onAddListing,
            icon: const Icon(Icons.add),
            label: const Text('List New Livestock'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E6A3F)),
          ),
        ],
      ),
    );
  }
}