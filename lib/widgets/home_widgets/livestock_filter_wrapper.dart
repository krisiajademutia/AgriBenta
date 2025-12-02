// lib/widgets/home_widgets/livestock_filter_wrapper.dart (CLEAN & FINAL)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
// Ensure this path is correct for your project
import 'home_section_livestock.dart'; 

class LivestockFilterWrapper extends StatelessWidget { // ⬅️ Correct type: StatelessWidget
  final String selectedCategoryName; 

  const LivestockFilterWrapper({
    super.key,
    required this.selectedCategoryName,
  });

  @override
  Widget build(BuildContext context) {
    
    // 1. QUERY SETUP
    Query query = FirebaseFirestore.instance.collection('livestock');
    if (selectedCategoryName != 'All') {
      query = query.where('category', isEqualTo: selectedCategoryName);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(), 
      
      builder: (context, snapshot) {

        // 1. WAITING
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        // 2. ERROR/NO DATA
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          final filterText = selectedCategoryName == 'All' ? '' : ' in $selectedCategoryName';
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                "No livestock for sale yet$filterText.", 
                style: const TextStyle(color: Colors.white70)
              ),
            ),
          );
        }

        final docs = snapshot.data!.docs;
        
        // 3. SUCCESS STATE: PASSING THE CORRECT VARIABLE
        return SectionLivestock(
            // ⬅️ THIS LINE IS THE FIX for your image_68c45c.png error.
            docs: docs, 
            selectedCategoryName: selectedCategoryName,
        );
      },
    );
  }
}