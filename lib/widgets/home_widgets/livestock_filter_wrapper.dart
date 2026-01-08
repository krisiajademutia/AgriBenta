import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_section_livestock.dart';

class LivestockFilterWrapper extends StatelessWidget {
  final String selectedCategoryName;
  final String searchQuery;

  const LivestockFilterWrapper({
    super.key,
    required this.selectedCategoryName,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance.collection('livestock');

    // 1. FILTER BY CATEGORY (Server Side)
    if (selectedCategoryName != 'All') {
      query = query.where('category', isEqualTo: selectedCategoryName);
    }

    // 2. ORDER BY DATE (Server Side)
    query = query.orderBy('postedAt', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        // LOADING
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF52B788)));
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final allDocs = snapshot.data!.docs;

        // SEARCH FILTERING (Client Side - Name OR Location)
        final filteredDocs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;

          // Get the search query in lowercase
          final query = searchQuery.toLowerCase();

          // Get fields (Handle nulls safely)
          final name = (data['name'] ?? '').toString().toLowerCase();
          final location = (data['location'] ?? '').toString().toLowerCase();

          // CHECK: Does name match OR does location match?
          return name.contains(query) || location.contains(query);
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
