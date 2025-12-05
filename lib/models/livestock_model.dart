// lib/models/livestock_model.dart

import 'package:cloud_firestore/cloud_firestore.dart'; 

class Livestock { 
  final String id;
  final String name;
  final String category; 
  final double price;
  final String location;
  
  final String imagePath; 
  final List<String> imagePaths; // NEW: List of all image paths
  
  final String sellerId;
  final DateTime postedAt;
  
  final String age; 
  final String weight;
  final String description; // NEW: Description
  final int colorValue; 

  const Livestock({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.location,
    required this.imagePath,
    required this.imagePaths, 
    required this.sellerId,
    required this.postedAt,
    required this.age,
    required this.weight,
    required this.description, 
    required this.colorValue,
  });

  // The fromSnapshot Factory Method
  factory Livestock.fromSnapshot(String id, Map<String, dynamic> data) {
    // Helper to safely cast dynamic lists from Firebase to List<String>
    List<String> getImagePaths(dynamic list) {
      if (list is List) {
        return list.map((e) => e.toString()).toList();
      }
      return [];
    }

    return Livestock(
      id: id,
      name: data['name'] ?? 'Unnamed Livestock',
      category: data['category'] ?? 'Uncategorized',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      location: data['location'] ?? 'Unknown Location',
      
      // Note: Assumes single image path field is 'imagePath'
      imagePath: data['imagePath'] ?? 'default_image.jpg',
      
      // CRITICAL: Read the array of image paths
      imagePaths: getImagePaths(data['imagePaths']), 
      
      sellerId: data['sellerId'] ?? 'N/A',
      
      postedAt: (data['postedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      
      age: data['age'] ?? 'N/A',
      weight: data['weight'] ?? 'N/A',
      description: data['description'] ?? 'No description provided.', // Read the description
      colorValue: data['colorValue'] ?? 0xFF2E8B57, 
    );
  }
}