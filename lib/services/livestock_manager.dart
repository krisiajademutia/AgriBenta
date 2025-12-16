// lib/services/livestock_manager.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:agribenta/services/img_bb.dart';

class LivestockManager extends ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  // Removed: final _storage = FirebaseStorage.instance;

  // --- Listing State Variables ---
  String? _name;
  String? _category;
  double? _price;
  String? _location;

  // Age State
  String? _ageYears;
  String? _ageMonths;
  String? _weight;

  // NEW: Description State
  String? _description;

  // Image and Loading State
  List<File> _tempImageFiles = [];
  bool _isSaving = false;
  bool _isLoadingLocation = false;

  // --- Dynamic Categories State ---
  List<String> _availableCategories = [];
  bool _isLoadingCategories = false;

  LivestockManager() {
    fetchCategories();
  }

  // Public Getters
  String? get name => _name;
  String? get category => _category;
  double? get price => _price;
  String? get location => _location;
  String? get ageYears => _ageYears;
  String? get ageMonths => _ageMonths;
  String? get weight => _weight;
  String? get description => _description;
  List<File> get tempImageFiles => _tempImageFiles;
  bool get isSaving => _isSaving;
  bool get isLoadingLocation => _isLoadingLocation;
  List<String> get availableCategories => _availableCategories;
  bool get isLoadingCategories => _isLoadingCategories;

  // --- Setters ---
  void setName(String value) => _name = value;
  void setCategory(String value) {
    _category = value;
    notifyListeners();
  }

  void setPrice(String value) {
    _price = value.isNotEmpty ? double.tryParse(value) : null;
  }

  void setLocation(String value) => _location = value;
  void setWeight(String value) => _weight = value;
  void setDescription(String value) => _description = value;
  void setAgeYears(String value) => _ageYears = value;
  void setAgeMonths(String value) => _ageMonths = value;

  void addImageFile(File file) {
    _tempImageFiles.add(file);
    notifyListeners();
  }

  void removeImageFile(File file) {
    _tempImageFiles.remove(file);
    notifyListeners();
  }

  // --- Dynamic Category Fetching (UNCHANGED) ---
  Future<void> fetchCategories() async {
    _isLoadingCategories = true;
    notifyListeners();

    try {
      final snapshot = await _firestore.collection('categories').get();
      _availableCategories = snapshot.docs.map((doc) {
        final data = doc.data();
        return data['name'] as String? ??
            data['categoryName'] as String? ??
            data['title'] as String? ??
            'Unknown Category';
      }).toList();

      _availableCategories
          .removeWhere((name) => name == 'Unknown Category' || name.isEmpty);
    } catch (e) {
      debugPrint("Error fetching categories: $e");
      _availableCategories = ['Cattle', 'Goat', 'Pig', 'Chicken'];
    }

    _isLoadingCategories = false;
    notifyListeners();
  }

  // --- Location Logic (UNCHANGED) ---
  Future<String> _getAddressFromCoordinates(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return [place.subLocality, place.locality, place.country]
            .where((s) => s != null && s.isNotEmpty)
            .join(', ');
      }
      return 'Location Found, Address Unavailable';
    } catch (e) {
      debugPrint("Error in Reverse Geocoding: $e");
      return 'Failed to convert coordinates to address';
    }
  }

  Future<void> getCurrentLocation() async {
    if (_isLoadingLocation) return;
    _isLoadingLocation = true;
    _location = 'Fetching location...';
    notifyListeners();

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
    } catch (e) {
      debugPrint("Error getting location: $e");
      _location = 'Location Error';
    } finally {
      _isLoadingLocation = false;
      notifyListeners();
    }
  }

  // --- Post Listing Function (Now uses Cloudinary) ---
  Future<bool> postListing() async {
    if (_auth.currentUser == null || _isSaving) return false;

    // Validation
    final isYearsEntered = (_ageYears != null && _ageYears!.isNotEmpty);
    final isMonthsEntered = (_ageMonths != null && _ageMonths!.isNotEmpty);
    final isAgeValid = isYearsEntered || isMonthsEntered;

    if (_name == null ||
        _name!.trim().isEmpty ||
        _price == null ||
        _location == null ||
        _category == null ||
        _tempImageFiles.isEmpty ||
        !isAgeValid ||
        _weight == null ||
        _description == null ||
        _description!.trim().isEmpty) {
      return false;
    }

    _isSaving = true;
    notifyListeners();

    try {
      // 1. Upload images to Cloudinary
      List<String> imageUrls =
          await ImgBBService.uploadLivestockImages(_tempImageFiles) ?? [];

      if (imageUrls.isEmpty) {
        debugPrint("Cloudinary upload failed or returned empty URLs");
        return false;
      }

      // 2. Create document
      final newDocRef = _firestore.collection('livestock').doc();

      // Format Age
      final years = isYearsEntered
          ? '${_ageYears} year${_ageYears == '1' ? '' : 's'}'
          : '';
      final months = isMonthsEntered
          ? '${_ageMonths} month${_ageMonths == '1' ? '' : 's'}'
          : '';
      String ageString = '';
      if (years.isNotEmpty && months.isNotEmpty) {
        ageString = '$years $months';
      } else {
        ageString = years.isNotEmpty ? years : months;
      }

      final mainImagePath = imageUrls.first;

      final listingData = {
        'id': newDocRef.id,
        'name': _name!.trim(),
        'category': _category,
        'price': _price,
        'location': _location,
        'age': ageString,
        'weight': _weight,
        'description': _description!.trim(),
        'colorValue': 0xFF2E8B57,
        'imagePath': mainImagePath,
        'imagePaths': imageUrls,
        'sellerId': _auth.currentUser!.uid,
        'postedAt': FieldValue.serverTimestamp(),
      };

      // 3. Save to Firestore
      await newDocRef.set(listingData);

      // 4. Cleanup
      _resetState();
      return true;
    } catch (e) {
      debugPrint("Error posting listing: $e");
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void _resetState() {
    _name = null;
    _category = null;
    _price = null;
    _location = null;
    _ageYears = null;
    _ageMonths = null;
    _weight = null;
    _description = null;
    _tempImageFiles = [];
  }
}
