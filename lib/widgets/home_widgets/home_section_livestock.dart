import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Import your model
import '../../models/livestock_model.dart';

class SectionLivestock extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;
  final String selectedCategoryName;

  const SectionLivestock(
      {super.key, required this.docs, required this.selectedCategoryName});

  @override
  Widget build(BuildContext context) {
    const Color textDark = Color(0xFF1B4332);
    const Color brandGreen = Color(0xFF52B788);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Recent Listings",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textDark)),
            if (selectedCategoryName != 'All')
              Text(selectedCategoryName,
                  style: TextStyle(
                      color: brandGreen, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 15),

        // Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.72,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemBuilder: (context, index) {
            final doc = docs[index];

            // 👇 CRITICAL FIX: USING YOUR MODEL FACTORY CORRECTLY
            final item = Livestock.fromSnapshot(
                doc.id, doc.data() as Map<String, dynamic>);

            return _buildCard(item);
          },
        ),
      ],
    );
  }

  Widget _buildCard(Livestock item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF1B4332).withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: Container(
                width: double.infinity,
                color: const Color(0xFFF0F7F4),
                child: item.imagePath.isNotEmpty
                    ? Image.network(
                        item.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image, color: Colors.grey),
                      )
                    : const Icon(Icons.image, color: Colors.grey),
              ),
            ),
          ),
          // Details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1B4332)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('₱ ${item.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: Color(0xFF52B788),
                        fontWeight: FontWeight.w900,
                        fontSize: 16)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                        child: Text(item.location,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
