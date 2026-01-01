import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/livestock_model.dart';
import '../widgets/livestock_card.dart';
import 'livestock_detail_screen.dart';

class SavedItemsScreen extends StatelessWidget {
  const SavedItemsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Professional Color Palette
    const Color bgCream = Color(0xFFF9F6F0);
    const Color brandGreen = Color(0xFF1B4332);
    const Color textDark = Color(0xFF2D3142);

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please log in to view saved items")),
      );
    }

    return Scaffold(
      backgroundColor: bgCream,
      appBar: AppBar(
        title: const Text(
          "Favorites",
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: bgCream,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: textDark),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey.withOpacity(0.1),
            height: 1.0,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('favorites')
            .orderBy('addedAt', descending: true)
            .snapshots(),
        builder: (context, favSnapshot) {
          // 1. Initial Loading State
          if (favSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: brandGreen),
            );
          }

          // 2. Empty State (Polished)
          if (!favSnapshot.hasData || favSnapshot.data!.docs.isEmpty) {
            return _buildEmptyState(context);
          }

          final favDocs = favSnapshot.data!.docs;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Small Header showing count
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  "${favDocs.length} items saved",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Grid
              Expanded(
                child: GridView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.70, // Optimized for LivestockCard
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: favDocs.length,
                  itemBuilder: (context, index) {
                    final favData =
                        favDocs[index].data() as Map<String, dynamic>;
                    final String livestockId =
                        favData['livestockId'] ?? favDocs[index].id;

                    // Fetch Real-time Data
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('livestock')
                          .doc(livestockId)
                          .get(),
                      builder: (context, itemSnapshot) {
                        // A. Loading Skeleton (Looks cleaner than a spinner)
                        if (itemSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return _buildLoadingSkeleton();
                        }

                        // B. Item Removed/Deleted State
                        if (!itemSnapshot.hasData ||
                            !itemSnapshot.data!.exists) {
                          return _buildUnavailableCard(livestockId, user.uid);
                        }

                        // C. Success State
                        try {
                          final doc = itemSnapshot.data!;

                          // --- FIX: Use fromSnapshot instead of fromJson ---
                          final livestock = Livestock.fromSnapshot(doc);
                          // -----------------------------------------------

                          return LivestockCard(
                            livestock: livestock,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LivestockDetailScreen(
                                      livestock: livestock),
                                ),
                              );
                            },
                          );
                        } catch (e) {
                          // Fallback if data is corrupt
                          return _buildUnavailableCard(livestockId, user.uid);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- WIDGETS ---

  // 1. Professional Empty State
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_border_rounded,
              size: 48,
              color: Color(0xFF52B788),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Favorites is empty",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Save items you want to track or buy later.",
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 32),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1B4332),
              side: const BorderSide(color: Color(0xFF1B4332)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25)),
            ),
            child: const Text("Explore Livestock"),
          ),
        ],
      ),
    );
  }

  // 2. Loading Skeleton (Cleaner than spinner)
  Widget _buildLoadingSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 14, width: 80, color: Colors.grey[200]),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 60, color: Colors.grey[100]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3. Unavailable Item Card (Polished)
  Widget _buildUnavailableCard(String livestockId, String userId) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.remove_circle_outline, color: Colors.grey, size: 32),
          const SizedBox(height: 12),
          const Text(
            "Item Unavailable",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Sold or removed",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('favorites')
                  .where('livestockId', isEqualTo: livestockId)
                  .get()
                  .then((snapshot) {
                for (var doc in snapshot.docs) {
                  doc.reference.delete();
                }
              });
            },
            icon: const Icon(Icons.delete_outline,
                size: 16, color: Colors.redAccent),
            label: const Text(
              "Remove",
              style: TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
