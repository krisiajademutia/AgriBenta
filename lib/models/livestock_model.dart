import 'package:cloud_firestore/cloud_firestore.dart';

class LivestockVariant {
  final String weight;
  final double price;
  final int quantity;

  LivestockVariant({
    required this.weight,
    required this.price,
    required this.quantity,
  });

  factory LivestockVariant.fromJson(Map<String, dynamic> json) {
    return LivestockVariant(
      weight: json['weight'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'weight': weight,
        'price': price,
        'quantity': quantity,
      };

  // --- ADDED THIS METHOD TO FIX THE ERROR ---
  Map<String, dynamic> toMap() {
    return {
      'weight': weight,
      'price': price,
      'quantity': quantity,
    };
  }

  // Added helper alias for consistency
  factory LivestockVariant.fromMap(Map<String, dynamic> map) =>
      LivestockVariant.fromJson(map);
}

class Livestock {
  final String id;
  final String sellerId;
  final String name;
  final String category;
  final double price;
  final double shippingFee;
  final String age;
  final String weight;
  final String location;
  final String description;
  final String imagePath;
  final List<String> imagePaths;
  final Timestamp postedAt;
  final String status;
  final int quantity;
  final List<LivestockVariant> variants;

  Livestock({
    required this.id,
    required this.sellerId,
    required this.name,
    required this.category,
    required this.price,
    required this.shippingFee,
    required this.age,
    required this.weight,
    required this.location,
    required this.description,
    required this.imagePath,
    required this.imagePaths,
    required this.postedAt,
    required this.status,
    required this.quantity,
    required this.variants,
  });

  // Factory constructor to create a Livestock object from Firestore
  factory Livestock.fromSnapshot(DocumentSnapshot doc) {
    Map<String, dynamic> json = doc.data() as Map<String, dynamic>;

    // Helper to safely parse image paths
    List<String> parseImagePaths(dynamic paths) {
      if (paths is List) {
        return paths.map((item) => item.toString()).toList();
      }
      return [];
    }

    // Helper to parse variants
    List<LivestockVariant> parsedVariants = [];
    if (json['variants'] != null && json['variants'] is List) {
      parsedVariants = (json['variants'] as List)
          .map((v) => LivestockVariant.fromJson(v))
          .toList();
    }

    return Livestock(
      id: doc.id, // Use doc.id from the snapshot
      sellerId: json['sellerId'] ?? '',
      name: json['name'] ?? 'Untitled Livestock',
      category: json['category'] ?? 'Other',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      shippingFee: (json['shippingFee'] as num?)?.toDouble() ?? 0.0,
      age: json['age'] ?? 'N/A',
      weight: json['weight'] ?? 'N/A',
      location: json['location'] ?? 'Unknown Location',
      description: json['description'] ?? 'No description provided.',
      imagePath: json['imagePath'] ?? '',
      imagePaths: parseImagePaths(json['imagePaths']),
      postedAt: json['postedAt'] ?? Timestamp.now(),
      status: json['status'] ?? 'active',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      variants: parsedVariants,
    );
  }
}
