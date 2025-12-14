import 'package:flutter/material.dart';
import '../../models/livestock_model.dart';

class ProfileListingsTab extends StatelessWidget {
  final List<Livestock> listings;
  final VoidCallback onAddListing;

  const ProfileListingsTab(
      {super.key, required this.listings, required this.onAddListing});

  @override
  Widget build(BuildContext context) {
    const Color brandGreen = Color(0xFF52B788);
    const Color textDark = Color(0xFF1B4332);

    if (listings.isEmpty) {
      // Empty State
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No listings yet',
                style: TextStyle(fontSize: 16, color: Colors.grey[500])),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onAddListing,
              icon: const Icon(Icons.add),
              label: const Text('List New Livestock'),
              style: ElevatedButton.styleFrom(
                backgroundColor: brandGreen, // <--- New Brand Color
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        ),
      );
    }

    // List View
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8.0),
      itemCount: listings.length,
      itemBuilder: (context, index) {
        final listing = listings[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: textDark.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(10),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Container(
                width: 60,
                height: 60,
                color: const Color(0xFFF0F7F4),
                child: Image.network(
                  listing.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.image_not_supported,
                      size: 30,
                      color: Colors.grey),
                ),
              ),
            ),
            title: Text(
              listing.name,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, color: textDark),
            ),
            subtitle: Text(
              '₱${listing.price.toStringAsFixed(0)} • ${listing.age}',
              style: const TextStyle(
                  color: brandGreen, fontWeight: FontWeight.w600),
            ),
            trailing: Icon(Icons.arrow_forward_ios,
                size: 14, color: Colors.grey[300]),
            onTap: () {
              // TODO: Navigate to detail screen
            },
          ),
        );
      },
    );
  }
}
