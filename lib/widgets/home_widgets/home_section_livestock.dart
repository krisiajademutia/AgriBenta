// lib/widgets/home_widgets/home_section_livestock.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/livestock_model.dart';
import '../../screens/livestock_detail_screen.dart';

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

    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = (screenWidth / 180).floor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header (Unchanged)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Recent Listings",
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

        // Grid View
        GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 0.75,
          ),
          itemBuilder: (context, index) {
            // ⭐️ FIX: Use the new single-argument factory ⭐️
            final item = Livestock.fromSnapshot(docs[index]);
            // ⭐️ END FIX ⭐️

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        LivestockDetailScreen(livestock: item),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image (Now Expanded)
                    Expanded(
                      flex: 4,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                        child: Image.network(
                          item.imagePath,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[200],
                              alignment: Alignment.center,
                              child: const CircularProgressIndicator(
                                color: brandGreen,
                                strokeWidth: 2,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.error_outline,
                                color: Colors.red),
                          ),
                        ),
                      ),
                    ),

                    // Details (Now Expanded with Flexible text)
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Name/Title
                            Flexible(
                              child: Text(
                                item.name,
                                style: const TextStyle(
                                  color: textDark,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                                maxLines: 2, // Constrained lines
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Price
                            Text(
                              '₱ ${item.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: brandGreen,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Location
                            Row(
                              children: [
                                Icon(Icons.location_on,
                                    size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    item.location,
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[600]),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
