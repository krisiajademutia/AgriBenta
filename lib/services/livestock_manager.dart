import 'dart:io';
import 'package:agribenta/models/livestock_model.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:agribenta/services/img_bb.dart';
import 'package:image_picker/image_picker.dart';

class LivestockManager extends ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // --- Listing State Variables ---
  String? _name;
  String? _category;
  double? _price;
  double? _shippingFee;
  String? _location;

  // Age State
  String? _ageYears;
  String? _ageMonths;
  String? _weight;

  // NEW: Description State
  String? _description;
  int _quantity = 1;

  // Image and Loading State
  //List<File> _tempImageFiles = [];
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
  //List<File> get tempImageFiles => _tempImageFiles;
  bool get isSaving => _isSaving;
  double? get shippingFee => _shippingFee;
  bool get isLoadingLocation => _isLoadingLocation;
  List<String> get availableCategories => _availableCategories;
  bool get isLoadingCategories => _isLoadingCategories;
  final int _maxImages = 10; // optional, you can reuse
  List<File> newImages = [];
  List<String> existingUrls = [];
  bool isLoading = false;
  final ImagePicker _picker = ImagePicker();
  int get quantity => _quantity;

  //String category = '';

  // --- Setters ---
  void setName(String value) {
    _name = value;
    notifyListeners();
  }

  void setCategory(String value) {
    _category = value;
    notifyListeners();
  }

  void setPrice(String value) {
    _price = value.isNotEmpty ? double.tryParse(value) : null;
    notifyListeners();
  }

  void setShippingFee(String value) {
    _shippingFee = value.isNotEmpty ? double.tryParse(value) : null;
    notifyListeners();
  }

  void setWeight(String value) {
    _weight = value;
    notifyListeners();
  }

  void setDescription(String value) {
    _description = value;
    notifyListeners();
  }

  void setLocation(String value) {
    _location = value;
    notifyListeners();
  }

  void setAgeYears(String value) {
    _ageYears = value;
    notifyListeners();
  }

  void setAgeMonths(String value) {
    _ageMonths = value;
    notifyListeners();
  }

  void setQuantity(String val) {
    if (val.isEmpty) {
      _quantity = 1;
    } else {
      _quantity = int.tryParse(val) ?? 1;
    }
    notifyListeners();
  }

  /*void addImageFile(File file) {
    _tempImageFiles.add(file);
    notifyListeners();
  }

  void removeImageFile(File file) {
    _tempImageFiles.remove(file);
    notifyListeners();
  }*/

  void initForEdit(Livestock livestock) {
    _name = livestock.name;
    _category = livestock.category;
    _price = livestock.price;
    _shippingFee = livestock.shippingFee;
    _location = livestock.location;
    _weight = livestock.weight;
    _description = livestock.description;
    _quantity = livestock.quantity;

    existingUrls = List.from(livestock.imagePaths);
    newImages.clear();

    notifyListeners();
  }

  void removeExisting(String url) {
    existingUrls.remove(url);
    notifyListeners();
  }

  void removeNew(int index) {
    newImages.removeAt(index);
    notifyListeners();
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _resetState() {
    _name = null;
    _category = null;
    _price = null;
    _shippingFee = null;
    _location = null;
    _ageYears = null;
    _ageMonths = null;
    _weight = null;
    _description = null;
    _quantity = 1;
    newImages.clear();
    existingUrls.clear();
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

  // --- Location Logic  ---
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

  Future<bool> postListing() async {
    if (_auth.currentUser == null || _isSaving) return false;

    // Validation
    final isYearsEntered = (_ageYears != null && _ageYears!.isNotEmpty);
    final isMonthsEntered = (_ageMonths != null && _ageMonths!.isNotEmpty);
    final isAgeValid = isYearsEntered || isMonthsEntered;

    if (_name == null ||
        _name!.trim().isEmpty ||
        _price == null ||
        _shippingFee == null ||
        _location == null ||
        _category == null ||
        newImages.isEmpty ||
        !isAgeValid ||
        _weight == null ||
        _description == null ||
        _description!.trim().isEmpty) {
      return false;
    }

    _isSaving = true;
    notifyListeners();

    try {
      // 1. Upload images to imgbb
      List<String> imageUrls =
          await ImgBBService.uploadLivestockImages(newImages) ?? [];

      if (imageUrls.isEmpty) {
        debugPrint("Upload failed or returned empty URLs");
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
        'shippingFee': _shippingFee,
        'location': _location,
        'age': ageString,
        'weight': _weight,
        'description': _description!.trim(),
        'quantity': _quantity,
        'colorValue': 0xFF2E8B57,
        'imagePath': mainImagePath,
        'imagePaths': imageUrls,
        'sellerId': _auth.currentUser!.uid,
        'postedAt': FieldValue.serverTimestamp(),
        'status': 'active', // Ensure status is set
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

  Future<void> pickImages() async {
    final List<XFile>? picked = await _picker.pickMultiImage();
    if (picked == null) return;

    if (newImages.length + picked.length > _maxImages) return;

    newImages.addAll(picked.map((x) => File(x.path)));
    notifyListeners();
  }

  Future<bool> saveEdit(
    Livestock livestock,
    BuildContext context,
  ) async {
    if (existingUrls.isEmpty && newImages.isEmpty) {
      _toast(context, "At least one photo is required");
      return false;
    }

    isLoading = true;
    notifyListeners();

    try {
      // ---------- AGE LOGIC ----------
      final bool isYearsEntered =
          _ageYears != null && _ageYears!.trim().isNotEmpty;
      final bool isMonthsEntered =
          _ageMonths != null && _ageMonths!.trim().isNotEmpty;

      String ageString = livestock.age;

      if (isYearsEntered || isMonthsEntered) {
        final String years = isYearsEntered
            ? '${_ageYears} year${_ageYears == '1' ? '' : 's'}'
            : '';
        final String months = isMonthsEntered
            ? '${_ageMonths} month${_ageMonths == '1' ? '' : 's'}'
            : '';

        ageString = years.isNotEmpty && months.isNotEmpty
            ? '$years $months'
            : (years.isNotEmpty ? years : months);
      }

      // ---------- IMAGE LOGIC ----------
      List<String> allUrls = List<String>.from(existingUrls);

      if (newImages.isNotEmpty) {
        final uploaded = await ImgBBService.uploadLivestockImages(newImages);

        if (uploaded == null || uploaded.isEmpty) {
          _toast(context, "Image upload failed");
          return false;
        }

        allUrls.addAll(uploaded);
      }

      // ---------- FIRESTORE UPDATE ----------
      await FirebaseFirestore.instance
          .collection('livestock')
          .doc(livestock.id)
          .update({
        'name': _name,
        'category': _category,
        'price': _price,
        'shippingFee': _shippingFee,
        'quantity': _quantity,
        'age': ageString,
        'weight': _weight,
        'location': _location,
        'description': _description,
        'imagePath': allUrls.first,
        'imagePaths': allUrls,
      });

      return true;
    } catch (e) {
      _toast(context, "Error: $e");
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
