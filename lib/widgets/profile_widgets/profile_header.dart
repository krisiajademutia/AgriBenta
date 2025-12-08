import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final String name;
  final String location;
  final String phone;
  final String? profileImageUrl;
  final VoidCallback onEditProfile;
  final VoidCallback onPostListing;
  final VoidCallback onLogout;
  final bool isSellerMode;

  const ProfileHeader({
    super.key,
    required this.name,
    required this.location,
    required this.phone,
    this.profileImageUrl,
    required this.onEditProfile,
    required this.onPostListing,
    required this.onLogout,
    required this.isSellerMode,
  });

  @override
  Widget build(BuildContext context) {
    // The Stack is used here to position the Logout button independently
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. All central content in a Column
          Column(
            children: [
              // Profile Picture (now centered without the logout button)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 70,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        backgroundImage: profileImageUrl != null &&
                                profileImageUrl!.isNotEmpty
                            ? NetworkImage(profileImageUrl!)
                            : const AssetImage('assets/default_avatar.png')
                                as ImageProvider,
                        child:
                            profileImageUrl == null || profileImageUrl!.isEmpty
                                ? const Icon(Icons.person,
                                    size: 80, color: Colors.white70)
                                : null,
                      ),
                      // Edit Button
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: onEditProfile,
                          child: const CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.edit,
                                color: Color(0xFF0D4C2F), size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Name
              Text(
                name,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Location
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on,
                      size: 18, color: Colors.white70),
                  const SizedBox(width: 6),
                  Text(
                    location.isEmpty || location == 'Unknown Location'
                        ? 'Set your location'
                        : location,
                    style: const TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                ],
              ),

              // Phone Number
              if (phone.isNotEmpty && phone != 'N/A' && phone.trim() != '')
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.phone, size: 18, color: Colors.white70),
                      const SizedBox(width: 6),
                      Text(
                        phone,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 15),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // Action Buttons (Post Listing)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSellerMode)
                    ElevatedButton.icon(
                      onPressed: onPostListing,
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text("Post Listing"),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0D4C2F)),
                    ),
                ],
              ),
            ],
          ),

          // 2. Logout button positioned in the top-right
          Positioned(
            top: 0, // Positioned at the top of the Container
            right: 0, // Positioned at the right of the Container
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onLogout,
                borderRadius: BorderRadius.circular(24),
                child: const CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.logout, color: Colors.red, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
