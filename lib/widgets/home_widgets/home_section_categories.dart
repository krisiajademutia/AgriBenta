import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agribenta/models/category_model.dart';

typedef CategorySelectedCallback = void Function(String categoryName);

class SectionCategories extends StatefulWidget {
  final CategorySelectedCallback onCategorySelected;
  final String selectedCategoryName;

  const SectionCategories({
    super.key,
    required this.onCategorySelected,
    required this.selectedCategoryName,
  });

  @override
  State<SectionCategories> createState() => _SectionCategoriesState();
}

class _SectionCategoriesState extends State<SectionCategories> {
  // 1. Keep the Stream active so it doesn't reload on tap
  late Stream<QuerySnapshot> _categoriesStream;

  // 2. Keep the Scroll Controller alive to remember position
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Initialize the stream only ONCE
    _categoriesStream =
        FirebaseFirestore.instance.collection('categories').snapshots();
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Clean up memory
    super.dispose();
  }

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
            stream: _categoriesStream, // Use the stored stream
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF52B788)));
              }

              if (snapshot.hasError) {
                return const Text("Error loading categories");
              }

              final docs = snapshot.data?.docs ?? [];

              // --- FIXED SECTION START ---
              // We map the docs carefully to match your Model's requirements
              List<Category> categories = docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>; // 1. Get Data
                return Category.fromSnapshot(
                    doc.id, data); // 2. Pass ID & Data separately
              }).toList();
              // --- FIXED SECTION END ---

              // Add "All" Category at the start
              categories.insert(
                0,
                Category(
                  id: 'all',
                  name: 'All',
                  iconKey: 'grid_view',
                ),
              );

              return ListView.separated(
                controller: _scrollController, // Attach controller
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                itemCount: categories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  // Compare names to check if selected
                  final isSelected = widget.selectedCategoryName == cat.name;

                  return GestureDetector(
                    onTap: () => widget.onCategorySelected(cat.name),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 75,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF52B788) // Brand Green
                            : Colors.white,
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
