// lib/services/profile_manager.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:agribenta/services/img_bb.dart';

class ProfileManager extends ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  User? get user => _auth.currentUser;

  // --- State Variables ---
  String? _name;
  String? _phone;
  String? _location;
  String? _imageUrl;
  String? _loadedUserId;

  // UI State
  File? _tempImageFile;
  bool _isUploading = false;
  bool _isLoadingLocation = false;

  // Public Getters
  String? get name => _name;
  String? get phone => _phone;
  String? get location => _location;
  String? get imageUrl => _imageUrl;
  File? get tempImageFile => _tempImageFile;
  bool get isUploading => _isUploading;
  bool get isLoadingLocation => _isLoadingLocation;

  // --- Load User Data ---
  Future<void> loadUserData() async {
    if (user == null) return;

    if (_loadedUserId == user!.uid) return;

    _loadedUserId = user!.uid;
    _name = null;
    _phone = null;
    _location = null;
    _imageUrl = null;
    notifyListeners();

    try {
      final doc = await _firestore.collection('users').doc(user!.uid).get();
      final data = doc.data() ?? {};
      _name = data['name'] ?? '';
      _phone = data['phone'] ?? '';
      _location = data['location'] ?? 'Not set';
      _imageUrl = data['profileImageUrl'];
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading user data: $e");
    }
  }

  // --- Updaters ---
  void setName(String newName) => _name = newName;

  void setPhone(String newPhone) {
    _phone = newPhone;
    notifyListeners();
  }

  void setLocation(String newLocation) => _location = newLocation;

  void setTempImageFile(File? file) {
    _tempImageFile = file;
    notifyListeners();
  }

  // --- Location ---
  Future<String> _getAddressFromCoordinates(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return [place.street, place.subLocality, place.locality, place.country]
            .where((s) => s != null && s.isNotEmpty)
            .join(', ');
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
    notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services disabled.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          throw Exception('Location permission denied.');
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
      notifyListeners();
    }
  }

  // --- Save Profile (Now uses Cloudinary) ---
  Future<bool> saveProfile() async {
    if (user == null ||
        _name == null ||
        _name!.trim().isEmpty ||
        _location == null) {
      return false;
    }
    if (_isUploading || _isLoadingLocation) return false;

    _isUploading = true;
    notifyListeners();

    String? newImageUrl = _imageUrl;

    if (_tempImageFile != null) {
      // 1. Upload new profile image using ImgBBService
      newImageUrl = await ImgBBService.uploadProfileImage(_tempImageFile!);

      if (newImageUrl == null) {
        debugPrint("ImgBB profile upload failed"); // FIX: Corrected log message
        _isUploading = false;
        notifyListeners();
        return false;
      }
    }

    try {
      await _firestore.collection('users').doc(user!.uid).update({
        'phone': _phone?.trim() ?? '',
        'location': _location!.trim(),
        if (newImageUrl != null) 'profileImageUrl': newImageUrl,
      });

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
