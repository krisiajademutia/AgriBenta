import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/livestock_model.dart';
import '../models/user_model.dart';
import 'livestock_detail_screen.dart';
import 'chat_screen.dart';
import '../widgets/livestock_card.dart';

class SellerStoreScreen extends StatelessWidget {
  final UserModel seller;

  const SellerStoreScreen({
    super.key,
    required this.seller,
  });

  @override
  Widget build(BuildContext context) {
    const Color brandGreen = Color(0xFF52B788);

    final String sellerName =
        seller.name.isNotEmpty ? seller.name : "AgriBenta User";
    final String initial =
        sellerName.isNotEmpty ? sellerName[0].toUpperCase() : "S";
    final String image = seller.profileImageUrl;

    // Helper to handle Message Logic
    void onMessageTap() {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please log in to message the seller")),
        );
        Navigator.pushNamed(context, '/login');
        return;
      }

      if (currentUser.uid == seller.id) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You cannot message yourself")),
        );
        return;
      }
      List<String> ids = [currentUser.uid, seller.id];
      ids.sort();
      String chatId = ids.join("_");

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: chatId, // Generated ID
            otherUserId: seller.id, // The Seller's ID
            otherUserName: sellerName, // The Seller's Name
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      appBar: AppBar(
        title: Text(sellerName),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1B4332),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- SELLER HEADER ---
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: brandGreen,
                    backgroundImage:
                        (image.isNotEmpty && !image.contains('placehold.co'))
                            ? NetworkImage(image)
                            : null,
                    child: (image.isEmpty || image.contains('placehold.co'))
                        ? Text(initial,
                            style: const TextStyle(
                                fontSize: 32,
                                color: Colors.white,
                                fontWeight: FontWeight.bold))
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    sellerName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B4332),
                    ),
                  ),
                  Text(
                    seller.email,
                    style: TextStyle(color: Colors.grey[600]),
                  ),

                  const SizedBox(height: 12),

                  // Trusted Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: brandGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, size: 16, color: brandGreen),
                        SizedBox(width: 4),
                        Text(
                          "Trusted Merchant",
                          style: TextStyle(
                              color: brandGreen, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- MESSAGE BUTTON ---
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton.icon(
                      onPressed: onMessageTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline, size: 20),
                      label: const Text(
                        "Message Seller",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- SELLER'S PRODUCTS HEADER ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "All Products",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // --- GRID VIEW USING NEW CARD ---
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('livestock')
                  .where('sellerId', isEqualTo: seller.id)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 48, color: Colors.grey),
                          SizedBox(height: 10),
                          Text("No listings found for this seller."),
                        ],
                      ),
                    ),
                  );
                }

                final livestockList = snapshot.data!.docs
                    .map((doc) => Livestock.fromSnapshot(doc))
                    .toList();

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75, // Keeps card shape nice
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: livestockList.length,
                  itemBuilder: (context, index) {
                    final item = livestockList[index];

                    // --- REPLACED MANUAL CODE WITH THIS: ---
                    return LivestockCard(
                      livestock: item,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                LivestockDetailScreen(livestock: item),
                          ),
                        );
                      },
                    );
                    // --------------------------------------
                  },
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
