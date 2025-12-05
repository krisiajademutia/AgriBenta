// lib/widgets/profile_widgets/profile_header.dart

import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final String name;
  final String location;
  final String profileImageUrl;
  final VoidCallback onEditProfile;
  final VoidCallback onPostListing;
  // NEW: Added Logout and Settings callbacks
  final VoidCallback onLogout;
  final VoidCallback onSettings;
  // NEW: Flag to control button visibility
  final bool isSellerMode; 

  const ProfileHeader({
    super.key,
    required this.name,
    required this.location,
    required this.profileImageUrl,
    required this.onEditProfile,
    required this.onPostListing,
    required this.onLogout, // Required
    required this.onSettings, // Required
    required this.isSellerMode, // Required
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: 10, right: 10, top: 20),
      padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20, top: 20), // Adjusted top padding for SafeArea
      decoration: BoxDecoration(
        //color: Color(0xFF0D4C2F),
        color:  Color.fromARGB(255, 172, 172, 141),
        borderRadius: BorderRadius.circular(30.0)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Align content to start
        children: [
          // Row for Profile Avatar and Info
          Row(
            children: [
              CircleAvatar(
                radius: 25, // Reduced size for better fit
                backgroundColor: const Color(0xFF1E6A3F),
                backgroundImage: profileImageUrl.isNotEmpty
                    ? NetworkImage(profileImageUrl) as ImageProvider
                    : null,
                onBackgroundImageError: profileImageUrl.isNotEmpty ? (_, __) {} : null,
                child: profileImageUrl.isEmpty
                    ? const Icon(Icons.person, size: 25, color: Color(0xFF0D4C2F))
                    : null,
              ),
              const SizedBox(width: 10),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row to hold Name and Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D4C2F),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        // settings and logout button (Kept beside username)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.settings, color: Colors.black),
                              onPressed: onSettings,
                              tooltip: 'Settings',
                            ),
                            IconButton(
                              icon: const Icon(Icons.logout, color: Colors.redAccent),
                              onPressed: onLogout,
                              tooltip: 'Logout',
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Location Row
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Color(0xFF0D4C2F), size: 16),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            location,
                            style: const TextStyle(color: Color(0xFF0D4C2F), fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Edit Profile / Post Listing Buttons
          Row(
            children: [
              Expanded(
                child: _buildButton(
                  icon: Icons.edit_note,
                  label: 'Edit Profile',
                  onTap: onEditProfile,
                  bgColor: const Color(0xFFF5F5DC),
                  textColor: const Color(0xFF0D4C2F),
                ),
              ),
              const SizedBox(width: 10),
              
              // CONDITIONAL: Only show Post Listing in Seller Mode
              if (isSellerMode) Expanded(
                child: _buildButton(
                  icon: Icons.add_business,
                  label: 'Post Listing',
                  onTap: onPostListing,
                  bgColor: const Color(0xFF1E6A3F),
                  textColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color bgColor,
    required Color textColor,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20, color: textColor),
      label: Text(
        label,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
    );
  }
}