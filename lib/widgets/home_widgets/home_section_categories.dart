import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agribenta/models/category_model.dart';

typedef CategorySelectedCallback = void Function(String categoryName);

class SectionCategories extends StatelessWidget {
  final CategorySelectedCallback onCategorySelected;
  final String selectedCategoryName;

  const SectionCategories({
    super.key,
    required this.onCategorySelected,
    required this.selectedCategoryName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            "Categories",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B4332), // Dark Green
            ),
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 90,
          child: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance.collection('categories').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF52B788)));
              }

              // 1. Convert Firestore Data to your Category Objects
              final categories = snapshot.data?.docs.map((doc) {
                    // Using YOUR factory method signature: (id, data)
                    return Category.fromSnapshot(
                        doc.id, doc.data() as Map<String, dynamic>);
                  }).toList() ??
                  [];

              // 2. Add "All" manually (Using 'other' to get the grid icon)
              final allCats = [
                Category(id: '0', name: 'All', iconKey: 'other'),
                ...categories
              ];

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: allCats.length,
                itemBuilder: (context, index) {
                  final cat = allCats[index];
                  final isSelected = cat.name == selectedCategoryName;

                  return GestureDetector(
                    onTap: () => onCategorySelected(cat.name),
                    child: Container(
                      width: 75,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? const Color(0xFF52B788) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          if (!isSelected)
                            BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 👇 USES YOUR HELPER METHOD DIRECTLY
                          Icon(
                            cat.getIcon(),
                            size: 28,
                            color: isSelected ? Colors.white : Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cat.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF1B4332),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
