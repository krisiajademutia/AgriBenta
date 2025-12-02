// lib/widgets/home_widgets/home_section_livestock.dart (Stateless Renderer)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
// CRITICAL: Ensure this path is correct for your Livestock model
import '../../models/livestock_model.dart'; 

class SectionLivestock extends StatelessWidget { // ⬅️ MUST BE StatelessWidget
  
  final List<QueryDocumentSnapshot> docs; 
  final String selectedCategoryName; 
  
  const SectionLivestock({
    super.key,
    required this.docs, 
    required this.selectedCategoryName, 
  });

  @override
  Widget build(BuildContext context) {
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // HEADER (Displaying Filtered Count)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            "Showing ${docs.length} livestock in $selectedCategoryName",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 15),

        // GRID
        GridView.builder(
          key: ValueKey('grid-$selectedCategoryName'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
          ),
          itemBuilder: (context, index) {
            final doc = docs[index];
            // CRITICAL: Ensure your Livestock.fromSnapshot factory method in livestock_model.dart 
            // is correct, or this line will cause a runtime error.
            final livestock = Livestock.fromSnapshot(doc.id, doc.data() as Map<String, dynamic>);
            
            // Calling the helper method here:
            return _buildLivestockCard(livestock); 
          },
        ),
      ],
    );
  }

  // --- Helper Method 1: The Livestock Card (Fixes your error) ---
  Widget _buildLivestockCard(Livestock item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TOP HALF: Image/Color
          Expanded(
            flex: 5,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                // Assuming colorValue is an integer representing a color
                color: Color(item.colorValue), 
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: item.imagePath.isNotEmpty && item.imagePath != 'default_image.jpg'
                    ? Image.network(
                        item.imagePath,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                        },
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Icon(Icons.broken_image, size: 40, color: Colors.white54),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.pets, size: 40, color: Colors.white54), // Default Placeholder
                      ),
              ),
            ),
          ),

          // BOTTOM HALF: Details
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Name
                  Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Age & Weight
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Calling the second helper method here:
                      _buildIconText(Icons.calendar_month, item.age),
                      _buildIconText(Icons.scale, item.weight),
                    ],
                  ),

                  // Price
                  Text(
                    '₱ ${item.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFF00B761),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Method 2: Icon and Text ---
  Widget _buildIconText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.grey),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}