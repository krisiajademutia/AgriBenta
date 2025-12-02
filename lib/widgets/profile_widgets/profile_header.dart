// lib/widgets/profile_widgets/profile_header.dart
import 'package:flutter/material.dart';
import '../../screens/edit_profile_screen.dart'; // ADD THIS IMPORT
import '../../screens/add_livestock_screen.dart';   // if not already imported

class ProfileHeader extends StatelessWidget {
  final String name;
  final String location;
  final String profileImageUrl;
  final VoidCallback onEditProfile;
  final VoidCallback onPostListing;

  const ProfileHeader({
    super.key,
    required this.name,
    required this.location,
    required this.profileImageUrl,
    required this.onEditProfile,
    required this.onPostListing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20, top: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0D4C2F),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: const Color(0xFF1E6A3F),
                backgroundImage: profileImageUrl.isNotEmpty
                    ? NetworkImage(profileImageUrl)
                    : null,
                onBackgroundImageError: profileImageUrl.isNotEmpty ? (_, __) {} : null,
                child: profileImageUrl.isEmpty
                    ? const Icon(Icons.person, size: 40, color: Colors.white70)
                    : null,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white70, size: 16),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            location,
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
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
              Expanded(
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