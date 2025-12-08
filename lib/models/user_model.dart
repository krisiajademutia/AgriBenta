// lib/models/user_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final String location;
  final String profileImageUrl;
  final String phone;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.location,
    required this.profileImageUrl,
    required this.phone,
  });

  // Factory constructor to create a UserModel from a Firestore Document Snapshot
  factory UserModel.fromSnapshot(DocumentSnapshot doc) {
    // 1. Get the raw data, which is Object? (or Map<dynamic, dynamic>)
    final userData = doc.data();

    // 2. 🔥 THE CRITICAL FIX: Safely convert the dynamic map to Map<String, dynamic>.
    //    Map.from() creates a new map, enforcing the string key type.
    final Map<String, dynamic> data =
        userData != null ? Map<String, dynamic>.from(userData as Map) : {};

    // 3. Construct the model using the guaranteed Map<String, dynamic>
    return UserModel(
      id: doc.id,
      email: data['email'] ?? 'No Email Provided',
      name: data['name'] ?? 'User Name',
      location: data['location'] ?? 'Unknown Location',
      profileImageUrl: data['profileImageUrl'] ??
          'https://placehold.co/100x100/10B981/ffffff/png?text=P',
      phone: data['phone'] ?? 'N/A',
    );
  }

  // Fallback for an unauthenticated or missing user
  static UserModel get empty => const UserModel(
        id: 'guest',
        email: 'guest@example.com',
        name: 'Guest User',
        location: 'Not Signed In',
        profileImageUrl:
            'https://placehold.co/100x100/6B7280/ffffff/png?text=G',
        phone: 'N/A',
      );
}
