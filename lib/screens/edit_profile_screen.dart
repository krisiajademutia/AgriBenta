// lib/screens/edit_profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:agribenta/services/profile_manager.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. DEFINE THEME COLORS
    const Color bgCream = Color(0xFFF9F6F0);
    const Color textDark = Color(0xFF1B4332);
    const Color brandGreen = Color(0xFF52B788);

    final manager = Provider.of<ProfileManager>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      manager.loadUserData();
    });

    return Scaffold(
      backgroundColor: bgCream, // <--- Cream Background
      appBar: AppBar(
        backgroundColor: bgCream,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Edit Profile",
          style: TextStyle(
              fontWeight: FontWeight.bold, color: textDark), // Dark Text
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // --- PROFILE PICTURE ---
            Consumer<ProfileManager>(
              builder: (context, mgr, child) {
                final isDisabled = mgr.isUploading || mgr.isLoadingLocation;
                return GestureDetector(
                  onTap: isDisabled
                      ? null
                      : () async {
                          final pickedFile = await ImagePicker().pickImage(
                              source: ImageSource.gallery, imageQuality: 80);
                          if (pickedFile != null) {
                            mgr.setTempImageFile(File(pickedFile.path));
                          }
                        },
                  child: Stack(
                    children: [
                      // Container for Shadow & Border
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: textDark.withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            )
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 70,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: mgr.tempImageFile != null
                              ? FileImage(mgr.tempImageFile!)
                              : (mgr.imageUrl?.isNotEmpty == true
                                  ? NetworkImage(mgr.imageUrl!) as ImageProvider
                                  : const AssetImage(
                                          'assets/default_avatar.png')
                                      as ImageProvider),
                          child: (mgr.tempImageFile == null &&
                                  (mgr.imageUrl == null ||
                                      mgr.imageUrl!.isEmpty))
                              ? Icon(Icons.person,
                                  size: 70, color: Colors.grey[400])
                              : null,
                        ),
                      ),

                      // Loading Indicator
                      if (mgr.isUploading)
                        const Positioned.fill(
                          child: Center(
                              child: CircularProgressIndicator(
                                  color: brandGreen, strokeWidth: 3)),
                        )
                      // Camera Icon
                      else
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: textDark, // Dark Green Badge
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt,
                                size: 18, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 30),

            // --- FULL NAME (Read Only) ---
            Consumer<ProfileManager>(
              builder: (context, mgr, child) {
                return Column(
                  children: [
                    Text(
                      mgr.name ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: textDark, // Dark Text
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                );
              },
            ),

            // --- PHONE NUMBER INPUT ---
            Consumer<ProfileManager>(
              builder: (context, mgr, child) {
                return _buildInputWrapper(
                  child: TextField(
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(
                        color: textDark, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: "Phone Number",
                      labelStyle: TextStyle(color: Colors.grey[600]),
                      hintText: "e.g. 09306284213",
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: const Icon(Icons.phone, color: brandGreen),
                      border: InputBorder.none, // Clean look
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                    ),
                    controller: TextEditingController(text: mgr.phone ?? '')
                      ..selection = TextSelection.fromPosition(
                        TextPosition(offset: (mgr.phone ?? '').length),
                      ),
                    onChanged: (value) => mgr.setPhone(value),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // --- LOCATION INPUT ---
            Consumer<ProfileManager>(
              builder: (context, mgr, child) {
                return _buildInputWrapper(
                  child: TextField(
                    readOnly: mgr.isLoadingLocation,
                    style: const TextStyle(
                        color: textDark, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: "Location",
                      labelStyle: TextStyle(color: Colors.grey[600]),
                      prefixIcon:
                          const Icon(Icons.location_on, color: brandGreen),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      suffixIcon: IconButton(
                        icon: mgr.isLoadingLocation
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: brandGreen))
                            : const Icon(Icons.my_location, color: textDark),
                        onPressed: mgr.isLoadingLocation
                            ? null
                            : () async {
                                final success = await mgr.getCurrentLocation();
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Location updated successfully!'),
                                      backgroundColor: brandGreen,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Failed to get location.'),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                              },
                      ),
                    ),
                    controller: TextEditingController(text: mgr.location ?? '')
                      ..selection = TextSelection.fromPosition(
                        TextPosition(offset: (mgr.location ?? '').length),
                      ),
                    onChanged: (value) => mgr.setLocation(value),
                  ),
                );
              },
            ),
            const SizedBox(height: 50),

            // --- SAVE BUTTON (With Spinner & Toast) ---
            Consumer<ProfileManager>(
              builder: (context, mgr, child) {
                final isDisabled = mgr.isUploading || mgr.isLoadingLocation;

                return SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandGreen,
                      foregroundColor: Colors.white,
                      elevation: 6,
                      shadowColor: brandGreen.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: isDisabled
                        ? null
                        : () async {
                            final success = await mgr.saveProfile();

                            if (success) {
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  SnackBar(
                                    content: const Row(
                                      children: [
                                        Icon(Icons.check_circle,
                                            color: Colors.white),
                                        SizedBox(width: 12),
                                        Text(
                                          "Profile updated successfully!",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: Colors.green[700],
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              Navigator.pop(context); // Go back after success
                            } else {
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  SnackBar(
                                    content: const Row(
                                      children: [
                                        Icon(Icons.error, color: Colors.white),
                                        SizedBox(width: 12),
                                        Text(
                                            "Failed to save profile. Try again."),
                                      ],
                                    ),
                                    backgroundColor: Colors.redAccent,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                            }
                          },
                    child: mgr.isUploading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                "Saving...",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : const Text(
                            "Save Changes",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to give TextFields that "Card" look
  Widget _buildInputWrapper({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                const Color(0xFF1B4332).withOpacity(0.05), // Soft Dark Shadow
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: child,
    );
  }
}
