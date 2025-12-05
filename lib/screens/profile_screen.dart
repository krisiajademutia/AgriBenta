// lib/screens/profile_screen.dart (Updated Content for Buyer Mode)

import 'package:agribenta/screens/edit_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/livestock_model.dart'; 
import '../widgets/profile_widgets/profile_header.dart';
import '../widgets/profile_widgets/profile_stats_row.dart';
import '../widgets/profile_widgets/profile_listings_tab.dart';
import 'add_livestock_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // State variable to manage the view mode. Default to false (Buyer Mode).
  bool _isSellerMode = false; 

  // Function to toggle the mode
  void _toggleSellerMode() {
    setState(() {
      _isSellerMode = !_isSellerMode;
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Function to fetch the current user's listings
  Stream<List<Livestock>> _fetchUserListings(String userId) {
    return FirebaseFirestore.instance
        .collection('livestock')
        .where('sellerId', isEqualTo: userId)
        .orderBy('postedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Livestock.fromSnapshot(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Helper widget for a buyer-focused item tile
  Widget _buildBuyerActionTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF0D4C2F), size: 30),
        title: Text(
          title, 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!authSnapshot.hasData || authSnapshot.data == null) {
          return const Center(child: Text("Please log in."));
        }

        final currentUser = authSnapshot.data!;

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .snapshots(),
          builder: (context, userSnapshot) {
            
            if (!userSnapshot.hasData || userSnapshot.data == null) {
                return const Center(child: CircularProgressIndicator());
            }

            final userModel = UserModel.fromSnapshot(userSnapshot.data!);
            
            return StreamBuilder<List<Livestock>>(
              stream: _fetchUserListings(currentUser.uid),
              builder: (context, listingsSnapshot) {
                
                final List<Livestock> userListings = listingsSnapshot.data ?? [];
                
                final int totalListings = userListings.length; 
                const int totalSales = 0; 
                const double totalEarnings = 0.0;

                return Scaffold(
                body: Container(
                  decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF0D4C2F),
                      Color(0xFF1E6A3F),
                      Color.fromARGB(255, 172, 172, 141),
                    ],
                  ),
                ),
                    child: SafeArea( 
                      child: NestedScrollView(
                        headerSliverBuilder: (context, innerBoxIsScrolled) => [
                          SliverToBoxAdapter(
                            child: ProfileHeader(
                              name: userModel.name,
                              location: userModel.location,
                              profileImageUrl: userModel.profileImageUrl,
                              onEditProfile: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                              ),
                              onPostListing: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AddLivestockScreen()),
                              ),
                              onLogout: () async {
                                await FirebaseAuth.instance.signOut();
                                if (mounted) Navigator.pushReplacementNamed(context, '/login');
                              },
                              onSettings: () => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Settings clicked")),
                              ),
                              isSellerMode: _isSellerMode,
                            ),
                          ),

                          // Mode Toggle Button (Visible in both modes)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                              child: OutlinedButton.icon(
                                onPressed: _toggleSellerMode,
                                icon: Icon(_isSellerMode ? Icons.shopping_basket_outlined : Icons.storefront, color: const Color(0xFF1E6A3F)),
                                label: Text(
                                  _isSellerMode ? 'Switch to Buyer Mode' : 'Start Selling',
                                  style: const TextStyle(color: Color(0xFF1E6A3F), fontWeight: FontWeight.bold),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFF1E6A3F), width: 1.5),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  backgroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          // CONDITIONAL: Show Stats Row and TabBar only in Seller Mode
                          if (_isSellerMode) ...[
                            SliverToBoxAdapter(
                              child: ProfileStatsRow(
                                totalListings: totalListings, 
                                totalSales: totalSales,       
                                totalEarnings: totalEarnings, 
                              ),
                            ),
                            SliverPersistentHeader(
                              delegate: _SliverAppBarDelegate(
                                TabBar(
                                  controller: _tabController,
                                  tabs: const [Tab(text: 'My Listings'), Tab(text: 'Reviews')],
                                  labelColor: const Color(0xFF0D4C2F),
                                  indicatorColor: const Color(0xFF1E6A3F),
                                ),
                              ),
                              pinned: true,
                            ),
                          ],
                        ],
                        
                        // CONDITIONAL: Show content based on mode
                        body: _isSellerMode 
                            ? TabBarView(
                                controller: _tabController,
                                children: [
                                  KeyedSubtree(
                                    key: const ValueKey('listings-tab'),
                                    child: ProfileListingsTab(
                                      listings: userListings,
                                      onAddListing: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const AddLivestockScreen()),
                                      ),
                                    ),
                                  ),
                                  KeyedSubtree(
                                    key: const ValueKey('reviews-tab'),
                                    child: const SizedBox.expand(
                                      child: Center(child: Text("Reviews coming soon...")),
                                    ),
                                  ),
                                ],
                              )
                            : Column( // Buyer Mode Content (My Orders, Saved Items)
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 20.0, bottom: 5.0, left: 20.0),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        "Buyer Actions",
                                        style: TextStyle(
                                          fontSize: 18, 
                                          fontWeight: FontWeight.bold, 
                                          color: Color(0xFF0D4C2F)
                                        ),
                                      ),
                                    ),
                                  ),
                                  _buildBuyerActionTile(
                                    title: 'My Orders',
                                    icon: Icons.receipt_long,
                                    onTap: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Navigating to My Orders')),
                                      );
                                    },
                                  ),
                                  _buildBuyerActionTile(
                                    title: 'Saved Items',
                                    icon: Icons.favorite_border,
                                    onTap: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Navigating to Saved Items')),
                                      );
                                    },
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color.fromARGB(255, 172, 172, 141),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}