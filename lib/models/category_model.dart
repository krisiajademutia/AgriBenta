import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final String iconKey;

  Category({
    required this.id,
    required this.name,
    required this.iconKey,
  });

  //Converts Firebase Data -> Dart Object
  factory Category.fromSnapshot(String id, Map<String, dynamic> data) {
    return Category(
      id: id,
      name: data['name'] ?? 'Unknown',
      iconKey: data['icon_key'] ?? 'default',
    );
  }

  //HELPER: The "Translator" (Text -> Icon)
  IconData getIcon() {
    switch (iconKey) {
      // Existing
      case 'cow':
        return Icons.catching_pokemon;
      case 'pig':
        return Icons.savings;
      case 'goat':
        return Icons.grass;
      case 'chicken':
        return Icons.egg;
      case 'dairy':
        return Icons.local_drink;

      // NEW ONES:
      case 'duck':
        return Icons.water; // Duck
      case 'carabao':
        return Icons.agriculture; // Carabao
      case 'fresh_egg':
        return Icons.egg_alt; // Egg
      case 'other':
        return Icons.grid_view; // Others

      // Fallback
      default:
        return Icons.pets;
    }
  }
}
