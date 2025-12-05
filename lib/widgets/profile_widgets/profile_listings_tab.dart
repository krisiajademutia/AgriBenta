// lib/widgets/profile_widgets/profile_listings_tab.dart

import 'package:flutter/material.dart';
import '../../models/livestock_model.dart'; // NEW IMPORT

class ProfileListingsTab extends StatelessWidget {
  final List<Livestock> listings; // NEW: The list of fetched listings
  final VoidCallback onAddListing;

  const ProfileListingsTab({
    super.key,
    required this.listings, // NEW required parameter
    required this.onAddListing
  });

  @override
  Widget build(BuildContext context) {
    if (listings.isEmpty) {
      // Show the "No listings yet" message if the list is empty
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E6A3F),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
    
    // Otherwise, show the list of listings
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8.0),
      itemCount: listings.length,
      itemBuilder: (context, index) {
        final listing = listings[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(10),
              // Leading image from the first image path
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  listing.imagePath,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.pets, size: 40, color: Colors.grey),
                ),
              ),
              title: Text(
                listing.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '₱${listing.price.toStringAsFixed(2)} | Age: ${listing.age}',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              onTap: () {
                // TODO: Navigate to the full listing detail screen
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Tapped on ${listing.name}')),
                );
              },
            ),
          ),
        );
      },
    );
  }
}