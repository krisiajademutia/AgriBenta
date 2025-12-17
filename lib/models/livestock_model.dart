import 'package:cloud_firestore/cloud_firestore.dart';

class Livestock {
  final String id;
  final String sellerId;
  final String name;
  final String category;
  final double price;
  final String age;
  final String weight;
  final String location;
  final String description;
  final String imagePath; // The primary image URL
  final List<String> imagePaths; // All image URLs
  final Timestamp postedAt;
  final String status;

  Livestock({
    required this.id,
    required this.sellerId,
    required this.name,
    required this.category,
    required this.price,
    required this.age,
    required this.weight,
    required this.location,
    required this.description,
    required this.imagePath,
    required this.imagePaths,
    required this.postedAt,
    required this.status,
  });

  // Factory to create model from a Map (used by fromSnapshot)
  factory Livestock.fromJson(Map<String, dynamic> json) {
    // Helper to safely handle missing or null lists
    List<String> parseImagePaths(dynamic paths) {
      if (paths is List) {
        return paths.map((item) => item.toString()).toList();
      }
      return [];
    }

    return Livestock(
      // Ensure 'id' is extracted from the snapshot and passed in the map if needed
      id: json['id'] ?? '',
      sellerId: json['sellerId'] ?? '',
      name: json['name'] ?? 'Untitled Livestock',
      category: json['category'] ?? 'Other',
      // Cast the 'num' from Firestore to a double
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      age: json['age'] ?? 'N/A',
      weight: json['weight'] ?? 'N/A',
      location: json['location'] ?? 'Unknown Location',
      description: json['description'] ?? 'No description provided.',
      imagePath: json['imagePath'] ?? '',
      imagePaths: parseImagePaths(json['imagePaths']),
      postedAt: json['postedAt'] ?? Timestamp.now(),
      status: json['status'] ?? 'active',
    );
  }

  factory Livestock.fromSnapshot(QueryDocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    // Pass the document ID into the data map so the fromJson constructor can use it
    data['id'] = snapshot.id;
    return Livestock.fromJson(data);
  }
}
