// lib/services/realtime_service.dart
import 'package:firebase_database/firebase_database.dart';
import 'package:agribenta/models/livestock_model.dart';

class RealtimeService {
  static final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // GET ALL CATEGORIES
  static Future<List<String>> getCategories() async {
    final snapshot = await _db.child('categories').get();
    if (snapshot.exists) {
      return List<String>.from(snapshot.value as List);
    }
    return [];
  }

  // GET LIVESTOCK BY CATEGORY (REAL-TIME!)
  static Stream<List<LivestockModel>> getLivestockByCategory(String category) {
    return _db
        .child('livestock')
        .orderByChild('category')
        .equalTo(category)
        .onValue
        .map((event) {
      final Map<dynamic, dynamic>? data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data == null) return <LivestockModel>[];

      return data.values.map((item) {
        final map = item as Map<dynamic, dynamic>;
        return LivestockModel(
          id: map['id'] ?? '',
          name: map['name'] ?? 'Unknown',
          category: map['category'] ?? '',
          price: (map['price'] as num?)?.toDouble() ?? 0.0,
          location: map['location'] ?? '',
          imagePath: map['imagePath'] ?? '',
          sellerId: map['sellerId'] ?? '',
          postedAt: DateTime.now(),
        );
      }).toList();
    });
  }

  // ADD NEW LIVESTOCK (for Sell form later)
  static Future<void> addLivestock(LivestockModel item) async {
    await _db.child('livestock').push().set({
      'id': item.id,
      'name': item.name,
      'category': item.category,
      'price': item.price,
      'location': item.location,
      'imagePath': item.imagePath,
      'sellerId': item.sellerId,
      'postedAt': ServerValue.timestamp,
    });
  }
}