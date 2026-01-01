import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/livestock_model.dart';
import '../../screens/livestock_detail_screen.dart';
import '../livestock_card.dart'; // Ensure this points to your shared LivestockCard

class SectionLivestock extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;
  final String selectedCategoryName;

  const SectionLivestock({
    super.key,
    required this.docs,
    required this.selectedCategoryName,
  });

  @override
  Widget build(BuildContext context) {
    const Color textDark = Color(0xFF1B4332);
    const Color brandGreen = Color(0xFF52B788);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Header ---
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 20), // Header padding stays 20 for alignment
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Available Livestock",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              if (selectedCategoryName != 'All')
                Text(
                  selectedCategoryName,
                  style: const TextStyle(
                    color: brandGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 15),

        // --- Grid View ---
        GridView.builder(
          // UPDATED: Padding changed from 20 to 16 to match Seller Store width
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12, // UPDATED: Changed from 15 to 12
            mainAxisSpacing: 12, // UPDATED: Changed from 15 to 12
            childAspectRatio: 0.75, // Matches Seller Store Ratio
          ),
          itemBuilder: (context, index) {
            final item = Livestock.fromSnapshot(docs[index]);

            return LivestockCard(
              livestock: item,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        LivestockDetailScreen(livestock: item),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
