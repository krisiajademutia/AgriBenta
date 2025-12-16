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
    // Theme Colors
    const Color textDark = Color(0xFF1B4332);
    const Color brandGreen = Color(0xFF52B788);
    const Color textGrey = Color(0xFF8D99AE);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Column(
        children: [
          // 1. TOP ROW: Avatar + Info + Logout
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AVATAR (Left Side)
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: textDark.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: profileImageUrl != null &&
                              profileImageUrl!.isNotEmpty
                          ? NetworkImage(profileImageUrl!)
                          : const NetworkImage(
                                  'https://via.placeholder.com/150?text=User')
                              as ImageProvider,
                    ),
                  ),
                  // Edit Icon (Mini floating badge)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: onEditProfile,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: textDark,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.edit,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 20),

              // INFO (Middle)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10), // Adjusted top spacing

                    // Name (Now allows wrapping)
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                        letterSpacing: -0.5,
                        height: 1.2, // Better line height for multi-line names
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Details Row
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 14, color: textGrey), // Slightly larger icon
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13, color: textGrey),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 14, color: textGrey),
                        const SizedBox(width: 4),
                        Text(
                          phone,
                          style: TextStyle(fontSize: 13, color: textGrey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // LOGOUT ICON
              IconButton(
                onPressed: onLogout,
                icon: Icon(Icons.logout_rounded,
                    color: Colors.grey.shade400, size: 24),
                tooltip: "Logout",
              ),
            ],
          ),

          const SizedBox(height: 25),

          // 2. SELLER ACTION BAR (If Seller)
          if (isSellerMode)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPostListing,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 4,
                  shadowColor: brandGreen.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline_rounded),
                    SizedBox(width: 8),
                    Text(
                      "Post New Listing",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
