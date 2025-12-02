// lib/screens/edit_profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  final picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _locationController;

  String? _imageUrl;
  File? _imageFile;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _locationController = TextEditingController();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data()!;
    _nameController.text = data['name'] ?? '';
    _locationController.text = data['location'] ?? 'Not set';
    setState(() {
      _imageUrl = data['profileImageUrl'];
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;
    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_pictures')
        .child('${user.uid}.jpg');

    setState(() => _isUploading = true);
    await ref.putFile(_imageFile!);
    final url = await ref.getDownloadURL();
    setState(() => _isUploading = false);
    return url;
  }

  Future<void> _saveProfile() async {
    setState(() => _isUploading = true);

    String? newImageUrl = _imageUrl;
    if (_imageFile != null) {
      newImageUrl = await _uploadImage();
    }

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'name': _nameController.text.trim(),
      'location': _locationController.text.trim(),
      if (newImageUrl != null) 'profileImageUrl': newImageUrl,
    });

    setState(() => _isUploading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile updated successfully!"), backgroundColor: Colors.green),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D4C2F),
        foregroundColor: Colors.white,
        title: const Text("Edit Profile"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : (_imageUrl?.isNotEmpty == true
                            ? NetworkImage(_imageUrl!) as ImageProvider
                            : const AssetImage('assets/default_avatar.png')),
                    child: _imageFile == null && (_imageUrl?.isEmpty ?? true)
                        ? const Icon(Icons.person, size: 70, color: Colors.white)
                        : null,
                  ),
                  if (_isUploading)
                    const Positioned.fill(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  else
                    const Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Color(0xFF0D4C2F),
                        child: Icon(Icons.camera_alt, size: 18, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Full Name",
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: "Location",
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D4C2F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isUploading ? null : _saveProfile,
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save Changes", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}