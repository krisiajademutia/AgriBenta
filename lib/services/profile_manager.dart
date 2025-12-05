// lib/services/profile_manager.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class ProfileManager extends ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _auth = FirebaseAuth.instance;

  // --- State Variables ---
  User? get user => _auth.currentUser;
  
  // Data State
  String? _name;
  String? _location;
  String? _imageUrl;
  
  // UI State
  File? _tempImageFile; // Used to hold the new image selected by the user
  bool _isUploading = false;
  bool _isLoadingLocation = false;
  
  // Public Getters for state (UI listens to these)
  String? get name => _name;
  String? get location => _location;
  String? get imageUrl => _imageUrl;
  File? get tempImageFile => _tempImageFile;
  bool get isUploading => _isUploading;
  bool get isLoadingLocation => _isLoadingLocation;

  // --- Initialization & Data Loading ---

  Future<void> loadUserData() async {
    if (user == null || _name != null) return; // Prevent re-loading on rebuild
    try {
      final doc = await _firestore.collection('users').doc(user!.uid).get();
      final data = doc.data() ?? {};
      _name = data['name'] ?? '';
      _location = data['location'] ?? 'Not set';
      _imageUrl = data['profileImageUrl'];
      notifyListeners(); 
    } catch (e) {
      debugPrint("Error loading user data: $e");
    }
  }
  
  // --- Profile Field Updaters ---

  void setName(String newName) {
    _name = newName;
  }

  void setLocation(String newLocation) {
    _location = newLocation;
  }
  
  // --- Image Handling ---

  void setTempImageFile(File? file) {
    _tempImageFile = file;
    notifyListeners();
  }

  Future<String?> _uploadImage(File imageFile) async {
    if (user == null) return null;
    
    final ref = _storage.ref().child('users/${user!.uid}/profile.jpg'); 

    try {
      await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final url = await ref.getDownloadURL();
      return url;
    } on FirebaseException catch (e) {
      debugPrint("Firebase Storage Error: ${e.code} - ${e.message}");
      return null;
    }
  }
  
  Future<void> _deleteOldImage(String? oldUrl) async {
    if (oldUrl == null || oldUrl.isEmpty) return;
    
    // Only attempt to delete images NOT using the new 'profile.jpg' fixed path
    if (!oldUrl.contains('/profile.jpg')) {
      try {
        await _storage.refFromURL(oldUrl).delete();
      } on FirebaseException catch (e) {
        if (e.code != 'object-not-found') {
          debugPrint("Error deleting old image: ${e.code}");
        }
      }
    }
  }

  // --- Location Logic ---

  Future<String> _getAddressFromCoordinates(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return [
          place.street,
          place.subLocality,
          place.locality,
          place.country
        ].where((s) => s != null && s.isNotEmpty).join(', ');
      }
      return 'Location Found, Address Unavailable';

    } catch (e) {
      debugPrint("Error in Reverse Geocoding: $e");
      return 'Failed to convert coordinates to address';
    }
  }

  Future<bool> getCurrentLocation() async {
    if (_isLoadingLocation) return false;
    _isLoadingLocation = true;
    _location = 'Fetching location...';
    notifyListeners(); // Update UI with 'Fetching...' message

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services are disabled.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          throw Exception('Location permission permanently denied.');
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      
      String address = await _getAddressFromCoordinates(position);
      _location = address;
      return true;
        
    } catch (e) {
      debugPrint("Error getting location: $e");
      _location = 'Location Error';
      return false;
    } finally {
      _isLoadingLocation = false;
      notifyListeners(); // Update UI with final result
    }
  }

  // --- Final Save Function ---
  
  Future<bool> saveProfile() async {
    if (user == null || _name == null || _name!.trim().isEmpty || _location == null) {
      return false; 
    }
    if (_isUploading || _isLoadingLocation) return false;

    _isUploading = true;
    notifyListeners();

    String? newImageUrl = _imageUrl;
    String? oldImageUrl = _imageUrl; 

    if (_tempImageFile != null) {
      // 1. Upload the new image.
      newImageUrl = await _uploadImage(_tempImageFile!);
      
      if (newImageUrl == null) {
        _isUploading = false;
        notifyListeners();
        return false;
      }
      
      // 2. Delete the old image only after successful new upload.
      if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
        await _deleteOldImage(oldImageUrl); 
      }
    }

    // 3. Update Firestore
    try {
      await _firestore.collection('users').doc(user!.uid).update({
        'name': _name!.trim(),
        'location': _location!.trim(),
        if (newImageUrl != null) 'profileImageUrl': newImageUrl,
      });
      
      // Update state for next time the screen loads
      _imageUrl = newImageUrl;
      _tempImageFile = null;

      return true;
    } catch (e) {
      debugPrint("Error saving profile: $e");
      return false;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }
}