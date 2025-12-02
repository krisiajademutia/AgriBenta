import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import '../../models/category_model.dart'; 

// 🚨 STEP 1: Define the callback type
typedef CategorySelectedCallback = void Function(String categoryName);

// ----------------------------------------------------
// 1. STATELSS WIDGET: Fetches data & passes controls
// ----------------------------------------------------
class SectionCategories extends StatelessWidget {
  // 🚨 ADD REQUIRED PARAMETERS
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
        // TITLE HEADER
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            "Category",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 15),

        // STREAM BUILDER
        SizedBox(
          height: 90,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('categories').snapshots(),
            
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text("No categories", style: TextStyle(color: Colors.white));
              }

              // Pass the documents, the current selection, and the callback
              final docs = snapshot.data!.docs;
              return CategoryListView(
                docs: docs,
                // 🚨 PASS CONTROLS DOWN
                onCategorySelected: onCategorySelected,
                selectedCategoryName: selectedCategoryName,
              ); 
            },
          ),
        ),
      ],
    );
  }
}

class CategoryListView extends StatefulWidget {

  final List<QueryDocumentSnapshot> docs;
  final CategorySelectedCallback onCategorySelected;
  final String selectedCategoryName;
  
  const CategoryListView({
    super.key, 
    required this.docs,
    required this.onCategorySelected,
    required this.selectedCategoryName,
  });

  @override
  State<CategoryListView> createState() => _CategoryListViewState();
}

class _CategoryListViewState extends State<CategoryListView> {
      bool _isAnimating = false;

  @override
  Widget build(BuildContext context) {
    final docs = widget.docs;

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      // We will add the 'All' category at index 0 manually
      itemCount: docs.length + 1, 
      clipBehavior: Clip.none,
      itemBuilder: (context, index) {
        
        String name;
        IconData icon;
        String uniqueKey;
        // bool isSelected; // We calculate this below

        if (index == 0) {
          // --- 'All' Category (index 0) ---
          name = "All";
          icon = Icons.pets;
          uniqueKey = 'All'; // Use the name as the key
        } else {
          // --- Firestore Categories (index 1+) ---
          final doc = docs[index - 1];
          final data = doc.data() as Map<String, dynamic>;
          Category category = Category.fromSnapshot(doc.id, data);
          
          name = category.name;
          icon = category.getIcon();
          uniqueKey = category.id; 
        }

        // 🚨 GET SELECTION STATE from HomeScreen via the widget
        final isSelected = widget.selectedCategoryName == name;

        return GestureDetector(
          key: ValueKey(uniqueKey),
          
          onTap: () {
             if (_isAnimating) return;  // Ignore if already animating
              setState(() => _isAnimating = true);
              widget.onCategorySelected(name);
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) setState(() => _isAnimating = false);
              }); 
            
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 80,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              // Use the isSelected state for color
              color: isSelected ? const Color(0xFF00B761) : Colors.white, 
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                if (!isSelected)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 28,
                  color: isSelected ? Colors.white : Colors.grey,
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}