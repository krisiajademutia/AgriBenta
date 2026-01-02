import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/category_model.dart';

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
  late Stream<QuerySnapshot> _categoriesStream;

  @override
  void initState() {
    super.initState();
    _categoriesStream =
        FirebaseFirestore.instance.collection('categories').snapshots();
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
              fontWeight: FontWeight.w800,
              color: Color(0xFF1B4332),
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 12), // Reduced spacing slightly

        // [1] REDUCED OVERALL HEIGHT (120 -> 95)
        SizedBox(
          height: 95,
          child: StreamBuilder<QuerySnapshot>(
            stream: _categoriesStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: SizedBox());
              }

              final docs = snapshot.hasData ? snapshot.data!.docs : [];

              final allCategories = [
                Category(id: 'all', name: 'All', iconKey: 'all'),
                ...docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Category.fromSnapshot(doc.id, data);
                }),
              ];

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: allCategories.length,
                itemBuilder: (context, index) {
                  final cat = allCategories[index];
                  final isSelected = widget.selectedCategoryName == cat.name;

                  return GestureDetector(
                    onTap: () => widget.onCategorySelected(cat.name),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin:
                          const EdgeInsets.only(right: 12, bottom: 5, top: 5),

                      // [2] REDUCED CARD WIDTH (80 -> 68)
                      width: 68,

                      decoration: BoxDecoration(
                        color:
                            isSelected ? const Color(0xFF52B788) : Colors.white,
                        borderRadius: BorderRadius.circular(
                            20), // Slightly smaller radius
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                                color: const Color(0xFF52B788).withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4))
                          else
                            BoxShadow(
                                color:
                                    const Color(0xFF1B4332).withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 3)),
                        ],
                        border: isSelected
                            ? Border.all(color: Colors.transparent)
                            : Border.all(color: Colors.grey.shade100),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // [3] REDUCED EMOJI CIRCLE SIZE (50 -> 40)
                          Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withOpacity(0.2)
                                  : const Color(0xFFF9F6F0),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              cat.getEmoji(),
                              // [4] REDUCED FONT SIZE (26 -> 20)
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                          const SizedBox(height: 6), // Reduced spacing

                          // Name Text
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Text(
                              cat.name,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10, // Smaller font
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF1B4332),
                              ),
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
