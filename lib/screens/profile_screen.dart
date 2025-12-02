import 'package:agribenta/screens/edit_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../widgets/profile_widgets/profile_header.dart';
import '../widgets/profile_widgets/profile_stats_row.dart';
import '../widgets/profile_widgets/profile_bottom_bar.dart';
import '../widgets/profile_widgets/profile_listings_tab.dart';
import 'add_livestock_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  @override
Widget build(BuildContext context) {
  return StreamBuilder<User?>(
    stream: FirebaseAuth.instance.authStateChanges(),
    builder: (context, authSnapshot) {
      // Still waiting for Firebase Auth to initialize
      if (authSnapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF0D4C2F))));
      }

      // Not logged in
      if (authSnapshot.data == null) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.login, size: 80, color: Colors.grey),
                SizedBox(height: 20),
                Text("You are not signed in", style: TextStyle(fontSize: 18)),
                ElevatedButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                  child: Text("Go to Login"),
                ),
              ],
            ),
          ),
        );
      }

      // USER IS LOGGED IN → Now load Firestore data
      final user = authSnapshot.data!;

      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF0D4C2F))));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Scaffold(body: Center(child: Text("Profile not found")));
          }

          final data = snapshot.data!.data()!;
          final String name = data['name'] ?? 'User';
          final String location = data['location'] ?? 'Location not set';
          final String profileImageUrl = data['profileImageUrl'] ?? '';

          return Scaffold(
            backgroundColor: const Color(0xFFF5F5DC),
            body: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: ProfileHeader(
                    name: name,
                    location: location,
                    profileImageUrl: profileImageUrl,
                    onEditProfile: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                      );
                    },
                    onPostListing: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddLivestockScreen()),
                    ),
                  ),
                ),
                // ... rest of your slivers (ProfileStatsRow, TabBar, etc.) stay exactly the same
                SliverToBoxAdapter(child: ProfileStatsRow(
                  totalListings: 12,
                  totalSales: 8,
                  totalEarnings: 125400.50,
                )),
                SliverToBoxAdapter(
                  child: TabBar(
                    controller: _tabController,
                    tabs: const [Tab(text: 'My Listings'), Tab(text: 'Reviews')],
                    labelColor: const Color(0xFF0D4C2F),
                    indicatorColor: const Color(0xFF1E6A3F),
                  ),
                ),
                SliverFillRemaining(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      ProfileListingsTab(onAddListing: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddLivestockScreen()),
                      )),
                      const Center(child: Text("Reviews coming soon...")),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: ProfileBottomBar(
              onLogout: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
              onSettings: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Settings clicked")),
              ),
            ),
          );
        },
      );
    },
  );
}
}