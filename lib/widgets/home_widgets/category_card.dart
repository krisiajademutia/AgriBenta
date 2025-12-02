// lib/widgets/home/category_card.dart
/*import 'package:flutter/material.dart';
import 'package:agribenta/models/category_model.dart';
import 'package:agribenta/screens/category_item_screen.dart'; // ← NAA NA NI!

class CategoryCard extends StatelessWidget {
  final CategoryModel category;

  const CategoryCard({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryItemsScreen(category: category),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 110,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Container(
                height: 90,
                width: double.infinity,
                color: Colors.white.withOpacity(0.2),
                child: Image.asset(category.imagePath, fit: BoxFit.cover),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                category.name,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}*/