import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/livestock_model.dart';
import '../../screens/livestock_detail_screen.dart';
import '../livestock_card.dart';

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
          padding:
              const EdgeInsets.symmetric(horizontal: 4.0), // Align with search
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    "Available",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (selectedCategoryName != 'All')
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: brandGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        selectedCategoryName,
                        style: const TextStyle(
                          color: brandGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),

        // --- Grid View ---
        GridView.builder(
          padding: const EdgeInsets.symmetric(
              horizontal: 4, vertical: 4), // Add padding for shadows
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16, // Increased spacing
            mainAxisSpacing: 16,
            childAspectRatio: 0.72, // Taller cards for better image display
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
