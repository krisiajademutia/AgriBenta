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
    final manager = Provider.of<ProfileManager>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      manager.loadUserData();
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text("Edit Profile",
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
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
        padding:
            const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 24),
        child: SafeArea(
          top: true,
          bottom: false,
          child: Column(
            children: [
              // Profile Picture
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
                        CircleAvatar(
                          radius: 70,
                          backgroundColor: Colors.grey[300],
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
                              ? const Icon(Icons.person,
                                  size: 70, color: Colors.white)
                              : null,
                        ),
                        if (mgr.isUploading)
                          const Positioned.fill(
                            child: Center(
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 3)),
                          )
                        else
                          const Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Color(0xFF0D4C2F),
                              child: Icon(Icons.camera_alt,
                                  size: 18, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),

              // Full Name — displayed (not editable)
              Consumer<ProfileManager>(
                builder: (context, mgr, child) {
                  return Column(
                    children: [
                      Text(
                        mgr.name ?? '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                },
              ),

              // Phone Number — EDITABLE
              Consumer<ProfileManager>(
                builder: (context, mgr, child) {
                  return TextField(
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: "Phone Number",
                      hintText: "e.g. 09306284213",
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    controller: TextEditingController(text: mgr.phone ?? '')
                      ..selection = TextSelection.fromPosition(
                        TextPosition(offset: (mgr.phone ?? '').length),
                      ),
                    onChanged: (value) => mgr.setPhone(value),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Location — EDITABLE
              Consumer<ProfileManager>(
                builder: (context, mgr, child) {
                  return TextField(
                    readOnly: mgr.isLoadingLocation,
                    decoration: InputDecoration(
                      labelText: "Location",
                      prefixIcon: const Icon(Icons.location_on),
                      suffixIcon: IconButton(
                        icon: mgr.isLoadingLocation
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Color(0xFF0D4C2F)))
                            : const Icon(Icons.my_location,
                                color: Color(0xFF0D4C2F)),
                        onPressed: mgr.isLoadingLocation
                            ? null
                            : () async {
                                final success = await mgr.getCurrentLocation();
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Location updated successfully!')),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Failed to get location.')),
                                  );
                                }
                              },
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    controller: TextEditingController(text: mgr.location ?? '')
                      ..selection = TextSelection.fromPosition(
                        TextPosition(offset: (mgr.location ?? '').length),
                      ),
                    onChanged: (value) => mgr.setLocation(value),
                  );
                },
              ),
              const SizedBox(height: 40),

              // Save Button
              Consumer<ProfileManager>(
                builder: (context, mgr, child) {
                  final isDisabled = mgr.isUploading || mgr.isLoadingLocation;
                  return SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D4C2F),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: isDisabled
                          ? null
                          : () async {
                              final success = await mgr.saveProfile();
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text("Profile updated successfully!"),
                                      backgroundColor: Color(0xFF0D4C2F)),
                                );
                                Navigator.pop(context);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("Failed to save profile.")),
                                );
                              }
                            },
                      child: isDisabled
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Save Changes",
                              style: TextStyle(fontSize: 18)),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
