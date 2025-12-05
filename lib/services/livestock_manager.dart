// lib/services/livestock_manager.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart'; 
import 'package:geocoding/geocoding.dart'; 

class LivestockManager extends ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;
  
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
  String? get description => _description; // NEW Getter
  List<File> get tempImageFiles => _tempImageFiles; 
  bool get isSaving => _isSaving;
  bool get isLoadingLocation => _isLoadingLocation;
  List<String> get availableCategories => _availableCategories;
  bool get isLoadingCategories => _isLoadingCategories;

  // --- Setters (Update state from UI) ---
  void setName(String value) { _name = value; }
  void setCategory(String value) { _category = value; notifyListeners(); }
  void setPrice(String value) { _price = value.isNotEmpty ? double.tryParse(value) : null; }
  void setLocation(String value) { _location = value; }
  void setWeight(String value) { _weight = value; }
  void setDescription(String value) { _description = value; } // NEW Setter
  
  void setAgeYears(String value) { _ageYears = value; } 
  void setAgeMonths(String value) { _ageMonths = value; } 

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
        return doc.data()['name'] as String; 
      }).toList();
      _availableCategories.removeWhere((name) => name.isEmpty);
    } catch (e) {
      debugPrint("Error fetching categories: $e");
    } finally {
      _isLoadingCategories = false;
      notifyListeners();
    }
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

  
  // --- Multiple Image Upload Logic (Firebase Storage) ---
  Future<List<String>?> _uploadListingImages(List<File> imageFiles) async {
    if (imageFiles.isEmpty) return null;
    
    List<String> imageUrls = [];
    final uid = _auth.currentUser!.uid;

    for (var i = 0; i < imageFiles.length; i++) {
      final fileName = '${uid}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      final ref = _storage.ref().child('listings/$fileName'); 

      try {
        await ref.putFile(imageFiles[i]);
        final url = await ref.getDownloadURL();
        imageUrls.add(url);
      } on FirebaseException catch (e) {
        debugPrint("Image upload failed for file $i: ${e.code}");
        return null; 
      }
    }
    return imageUrls;
  }

  // --- Post Listing Function (Saves to 'livestock' collection) ---
  Future<bool> postListing() async {
    if (_auth.currentUser == null || _isSaving) return false;

    // 1. Validation 
    final isYearsEntered = (_ageYears != null && _ageYears!.isNotEmpty);
    final isMonthsEntered = (_ageMonths != null && _ageMonths!.isNotEmpty);
    final isAgeValid = isYearsEntered || isMonthsEntered;

    if (_name == null || _name!.trim().isEmpty || _price == null || 
        _location == null || _category == null || _tempImageFiles.isEmpty || 
        !isAgeValid || _weight == null || _description == null || _description!.trim().isEmpty) { 
      return false; 
    }
    
    _isSaving = true;
    notifyListeners();

    List<String>? imageUrls;
    
    try {
      // 2. Upload Images to Firebase Storage
      imageUrls = await _uploadListingImages(_tempImageFiles);

      if (imageUrls == null || imageUrls.isEmpty) return false; 

      // 3. Create Livestock Data
      final newDocRef = _firestore.collection('livestock').doc();
      
      // Format Age String
      final years = isYearsEntered ? '${_ageYears} year${_ageYears == '1' ? '' : 's'}' : '';
      final months = isMonthsEntered ? '${_ageMonths} month${_ageMonths == '1' ? '' : 's'}' : '';
      
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
        'description': _description!.trim(), // Description saved
        'colorValue': 0xFF2E8B57, 
        'imagePath': mainImagePath, 
        'imagePaths': imageUrls, // Multiple image paths saved
        'sellerId': _auth.currentUser!.uid,
        'postedAt': FieldValue.serverTimestamp(), 
      };

      // 4. Save data to Firebase Firestore
      await newDocRef.set(listingData);

      // 5. Success cleanup
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