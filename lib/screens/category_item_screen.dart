// lib/screens/category_items_screen.dart
/*import 'package:agribenta/widgets/home_widgets/livestock_card.dart';
import 'package:flutter/material.dart';
import 'package:agribenta/models/category_model.dart';
import 'package:agribenta/data/livestock_data.dart';

class CategoryItemsScreen extends StatelessWidget {
  final CategoryModel category;

  const CategoryItemsScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    // ← SAFE FILTER (case-insensitive + null-safe)
    final filteredItems = allLivestock.where((item) {
      if (item.category.isEmpty || category.name.isEmpty) return false;
      return item.category.toLowerCase() == category.name.toLowerCase();
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E4F2A),
        title: Text(
          category.name,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: filteredItems.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category_outlined, size: 80, color: Colors.white54),
                  SizedBox(height: 16),
                  Text(
                    "No items in this category yet",
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                return LivestockCard(item: filteredItems[index]);
              },
            ),
    );
  }
}*/