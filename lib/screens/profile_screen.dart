import 'package:agribenta/screens/tabs/orders_tab.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'add_livestock_screen.dart';
import 'edit_profile_screen.dart';
import 'seller_orders_screen.dart';
import 'edit_livestock_screen.dart';

import '../models/user_model.dart';
import '../models/livestock_model.dart';
import '../services/user_role_manager.dart';

import '../widgets/profile_widgets/profile_header.dart';
import '../widgets/profile_widgets/profile_stats_row.dart';
import '../widgets/profile_widgets/profile_listings_tab.dart';
import 'package:agribenta/screens/saved_items_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Color bgCream = const Color(0xFFF9F6F0);
  final Color textDark = const Color(0xFF1B4332);
  final Color brandGreen = const Color(0xFF52B788);

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Please log in")));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: bgCream,
            body: Center(child: CircularProgressIndicator(color: brandGreen)),
          );
        }

        if (snapshot.data!.data() == null) {
          return const Scaffold(
              body: Center(child: Text("User data not found")));
        }

        final userModel = UserModel.fromSnapshot(snapshot.data!);

        return Consumer<UserRoleManager>(
          builder: (context, roleManager, child) {
            final bool hasUnlockedSellerMode =
                roleManager.hasTappedStartSelling;

            return Scaffold(
              backgroundColor: bgCream,
              body: SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 120),
                  child: Column(
                    children: [
                      ProfileHeader(
                        name: userModel.name,
                        location: userModel.location,
                        phone: userModel.phone,
                        profileImageUrl: userModel.profileImageUrl,
                        onEditProfile: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const EditProfileScreen())),
                        onPostListing: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AddLivestockScreen())),
                        onLogout: _logout,
                        isSellerMode: roleManager.isSeller,
                      ),
                      const SizedBox(height: 20),
                      if (!hasUnlockedSellerMode) ...[
                        _buildBuyerActions(context),
                        const SizedBox(height: 30),
                        _buildStartSellingCard(context, roleManager),
                      ] else ...[
                        _buildModeSwitcher(roleManager),
                        const SizedBox(height: 20),
                        if (roleManager.isSeller)
                          _buildSellerDashboard(context, user.uid)
                        else
                          _buildBuyerActions(context),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModeSwitcher(UserRoleManager roleManager) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          _modeTab("Buyer Mode", !roleManager.isSeller,
              () => roleManager.switchToBuyer()),
          _modeTab("Seller Mode", roleManager.isSeller,
              () => roleManager.switchToSeller()),
        ],
      ),
    );
  }

  Widget _buildBuyerActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Text("Buyer Actions",
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: textDark)),
          const SizedBox(height: 15),
          _buildActionTile("My Orders", Icons.receipt_long_outlined, () {
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => const OrdersTab()));
          }),
          _buildActionTile("Saved Items", Icons.favorite_border_outlined, () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SavedItemsScreen()));
          }),
        ],
      ),
    );
  }

  Widget _buildSellerDashboard(BuildContext context, String userId) {
    return Column(
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .where('sellerId', isEqualTo: userId)
              .where('status', isEqualTo: 'completed')
              .snapshots(),
          builder: (context, orderSnapshot) {
            int totalSales = 0;
            double totalEarnings = 0.0;

            if (orderSnapshot.hasData) {
              final docs = orderSnapshot.data!.docs;
              totalSales = docs.length;
              for (var doc in docs) {
                final data = doc.data() as Map<String, dynamic>;
                double amount =
                    (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
                totalEarnings += amount;
              }
            }

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('livestock')
                  .where('sellerId', isEqualTo: userId)
                  .snapshots(),
              builder: (context, listingSnapshot) {
                int totalListings = 0;
                if (listingSnapshot.hasData) {
                  totalListings = listingSnapshot.data!.docs.length;
                }

                return ProfileStatsRow(
                  totalListings: totalListings,
                  totalSales: totalSales,
                  totalEarnings: totalEarnings,
                );
              },
            );
          },
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: _buildActionTile(
            "My Sales Dashboard",
            Icons.storefront_outlined,
            () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SellerOrdersScreen()));
            },
            isHighlight: true,
          ),
        ),
        const SizedBox(height: 20),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('livestock')
              .where('sellerId', isEqualTo: userId)
              .orderBy('postedAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                  child: CircularProgressIndicator(color: brandGreen));
            }
            final List<Livestock> listings =
                snapshot.data?.docs.map<Livestock>((doc) {
                      return Livestock.fromSnapshot(doc);
                    }).toList() ??
                    [];

            return ProfileListingsTab(
                listings: listings,
                onAddListing: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AddLivestockScreen()));
                },
                onEditListing: (livestock) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              EditLivestockScreen(livestock: livestock)));
                });
          },
        ),
      ],
    );
  }

  Widget _buildStartSellingCard(
      BuildContext context, UserRoleManager roleManager) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: textDark.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.storefront, size: 50, color: brandGreen),
          const SizedBox(height: 16),
          Text(
            "Start Selling Today",
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: textDark),
          ),
          const SizedBox(height: 8),
          Text(
            "Join thousands of farmers selling their livestock on AgriBenta.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await roleManager.startSelling();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: const Text("Welcome to Seller Mode!"),
                        backgroundColor: brandGreen),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: brandGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text("Activate Seller Mode",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(String title, IconData icon, VoidCallback onTap,
      {bool isHighlight = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isHighlight ? Colors.orange.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isHighlight
            ? Border.all(color: Colors.orange.withOpacity(0.3))
            : null,
        boxShadow: [
          BoxShadow(
              color: textDark.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: isHighlight ? Colors.white : const Color(0xFFF0F7F4),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: isHighlight ? Colors.orange : brandGreen),
        ),
        title: Text(title,
            style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
        trailing: Icon(Icons.arrow_forward_ios,
            size: 16, color: Colors.grey.shade400),
        onTap: onTap,
      ),
    );
  }

  Widget _modeTab(String title, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? brandGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? Colors.white : Colors.grey.shade500,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
