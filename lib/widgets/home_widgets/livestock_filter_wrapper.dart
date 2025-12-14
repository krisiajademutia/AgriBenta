import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_section_livestock.dart';

class LivestockFilterWrapper extends StatelessWidget {
  final String selectedCategoryName;
  final String searchQuery; // <--- Add this

  const LivestockFilterWrapper({
    super.key,
    required this.selectedCategoryName,
    required this.searchQuery, // <--- Require it
  });

  @override
  Widget build(BuildContext context) {
    // 1. QUERY SETUP (Keep Category Logic)
    Query query = FirebaseFirestore.instance.collection('livestock');

    if (selectedCategoryName != 'All') {
      query = query.where('category', isEqualTo: selectedCategoryName);
    }

    // Order by newest
    query = query.orderBy('postedAt', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        // LOADING
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF52B788)));
        }

        // ERROR
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        // EMPTY CHECK
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final allDocs = snapshot.data!.docs;

        // 2. SEARCH FILTERING (Client Side)
        // We filter the list in memory because Firestore can't do "Contains" search easily
        final filteredDocs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '').toString().toLowerCase();
          return name.contains(searchQuery.toLowerCase());
        }).toList();

        if (filteredDocs.isEmpty) {
          return _buildEmptyState();
        }

        // SUCCESS: Pass the filtered docs to your grid
        return SectionLivestock(
          docs: filteredDocs,
          selectedCategoryName: selectedCategoryName,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Icon(Icons.search_off, size: 50, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text(
              "No livestock found.",
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }
}
