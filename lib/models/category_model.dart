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

  //HELPER: The "Translator" (Text -> Emoji String)
  // Changed return type from IconData to String
  String getEmoji() {
    switch (iconKey) {
      // Requested Livestock
      case 'cow':
        return '🐄';
      case 'pig':
        return '🐖';
      case 'goat':
        return '🐐';
      case 'chicken':
        return '🐓';
      case 'duck':
        return '🦆';
      case 'carabao':
        return '🐃';

      // Specials
      case 'other':
        return '📦';
      case 'all':
        return '🏠';

      // Products (kept from your original code just in case)
      case 'dairy':
        return '🥛';
      case 'fresh_egg':
        return '🥚';

      // Fallback
      default:
        return '🐾';
    }
  }
}
