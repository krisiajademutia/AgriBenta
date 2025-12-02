// lib/models/livestock_model.dart

// We need the cloud_firestore import for the data types
import 'package:cloud_firestore/cloud_firestore.dart'; 

// IMPORTANT: Renamed to 'Livestock' to match the widget
class Livestock { 
  final String id;
  final String name;
  final String category; 
  final double price;
  final String location;
  final String imagePath;
  final String sellerId;
  final DateTime postedAt;
  
  // NOTE: I am adding age and weight back in, as they are used in your UI cards
  final String age; 
  final String weight;
  // I am also adding a colorValue for the card background (you can remove this if you use images only)
  final int colorValue; 

  const Livestock({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.location,
    required this.imagePath,
    required this.sellerId,
    required this.postedAt,
    required this.age,
    required this.weight,
    required this.colorValue,
  });

  // 🚨 CRITICAL FIX: The fromSnapshot Factory Method
  // This converts the Firebase document snapshot into your Dart model.
  factory Livestock.fromSnapshot(String id, Map<String, dynamic> data) {
    return Livestock(
      id: id,
      name: data['name'] ?? 'Unnamed Livestock',
      category: data['category'] ?? 'Uncategorized',
      
      // Convert data types from Firebase (often numbers) to the types you need
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      
      location: data['location'] ?? 'Unknown Location',
      imagePath: data['image_path'] ?? 'default_image.jpg',
      sellerId: data['seller_id'] ?? 'N/A',
      
      // Convert Firestore Timestamp to Dart DateTime
      postedAt: (data['posted_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      
      // Fields necessary for the UI card in SectionLivestock
      age: data['age'] ?? 'N/A', 
      weight: data['weight'] ?? 'N/A',
      colorValue: data['color_value'] ?? 0xFF9E9E9E, // Default Grey
    );
  }
}