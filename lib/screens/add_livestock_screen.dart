import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agribenta/services/img_bb.dart';

class AddLivestockScreen extends StatefulWidget {
  const AddLivestockScreen({super.key});

  @override
  State<AddLivestockScreen> createState() => _AddLivestockScreenState();
}

class _AddLivestockScreenState extends State<AddLivestockScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  // Data
  String _selectedCategory = ''; // Will be set after fetching
  final List<File> _selectedImages = [];
  final int _maxImages = 10;

  final Map<String, IconData> _iconRegistry = {
    'cow': Icons.catching_pokemon,
    'carabao': Icons.agriculture,
    'goat': Icons.grass,
    'pig': Icons.savings,
    'chicken': Icons.egg,
    'duck': Icons.water,
    'other': Icons.grid_view,
  };

  IconData _getIconFromKey(String key) {
    return _iconRegistry[key] ?? Icons.help_outline; // Default if not found
  }

  // Theme Colors
  final Color bgCream = const Color(0xFFF9F6F0);
  final Color textDark = const Color(0xFF1B4332);
  final Color brandGreen = const Color(0xFF52B788);

  // 1. PICK IMAGE LOGIC
  Future<void> _pickImages() async {
    if (_selectedImages.length >= _maxImages) return;
    final List<XFile> pickedFiles =
        await ImagePicker().pickMultiImage(imageQuality: 70);
    if (pickedFiles.isNotEmpty) {
      setState(() {
        int remaining = _maxImages - _selectedImages.length;
        _selectedImages
            .addAll(pickedFiles.take(remaining).map((x) => File(x.path)));
      });
    }
  }

  void _removeImage(int index) =>
      setState(() => _selectedImages.removeAt(index));

  // 2. SUBMIT LOGIC (Same as before)
  Future<void> _submitListing() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Add a photo.")));
      return;
    }
    if (_selectedCategory.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Select a category.")));
      return;
    }
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      List<String>? downloadUrls =
          await ImgBBService.uploadLivestockImages(_selectedImages);

      if (downloadUrls == null || downloadUrls.isEmpty) {
        // Handle the case where the upload failed (e.g., 503 error, rate limit)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Image upload failed. Please try again.")));
        setState(() => _isLoading = false);
        return; // Stop the function here
      }

      await FirebaseFirestore.instance.collection('livestock').add({
        'sellerId': user.uid,
        'name': _nameController.text.trim(),
        'category': _selectedCategory, // Uses the fetched category name
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'age': _ageController.text.trim(),
        'weight': _weightController.text.trim(),
        'location': _locationController.text.trim(),
        'description': _descController.text.trim(),
        'imagePath': downloadUrls.first,
        'imagePaths': downloadUrls,
        'postedAt': FieldValue.serverTimestamp(),
        'status': 'active',
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Success!"), backgroundColor: brandGreen));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: bgCream,
        elevation: 0,
        leading: IconButton(
            icon: Icon(Icons.close, color: textDark),
            onPressed: () => Navigator.pop(context)),
        title: Text("Sell Livestock",
            style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submitListing,
          style: ElevatedButton.styleFrom(
            backgroundColor: brandGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            elevation: 6,
            shadowColor: brandGreen.withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isLoading
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                    SizedBox(width: 16),
                    Text(
                      "Posting...",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              : const Text(
                  "Post Listing",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20, // Left
          10, // Top
          20, // Right
          MediaQuery.of(context).viewPadding.bottom + 100,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PHOTO GALLERY (Same UI as before)
              _buildSectionTitle("Photos"),
              const SizedBox(height: 10),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: brandGreen.withOpacity(0.3), width: 1.5),
                          ),
                          child: Icon(Icons.add_a_photo_rounded,
                              size: 30, color: brandGreen),
                        ),
                      );
                    }
                    return Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                            image: FileImage(_selectedImages[index - 1]),
                            fit: BoxFit.cover),
                      ),
                      child: Align(
                        alignment: Alignment.topRight,
                        child: GestureDetector(
                          onTap: () => _removeImage(index - 1),
                          child: Container(
                            margin: const EdgeInsets.all(5),
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                                color: Colors.white, shape: BoxShape.circle),
                            child: const Icon(Icons.close,
                                size: 14, color: Colors.red),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // --- DYNAMIC CATEGORIES FROM FIRESTORE ---
              _buildSectionTitle("Category"),
              const SizedBox(height: 10),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('categories')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());

                  final categoriesDocs = snapshot.data!.docs;

                  // Sort alphabetically
                  categoriesDocs.sort((a, b) => a['name'].compareTo(b['name']));

                  return SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categoriesDocs.length,
                      itemBuilder: (context, index) {
                        final data = categoriesDocs[index].data()
                            as Map<String, dynamic>;
                        final String catName = data['name'] ?? 'Unknown';
                        final String iconKey = data['icon_key'] ?? 'other';

                        final bool isSelected = _selectedCategory == catName;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = catName;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? brandGreen : Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                  color: isSelected
                                      ? brandGreen
                                      : Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                // LOOKUP ICON FROM REGISTRY
                                Icon(_getIconFromKey(iconKey),
                                    size: 18,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey[600]),
                                const SizedBox(width: 8),
                                Text(
                                  catName,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              _buildSectionTitle("Item Details"),
              const SizedBox(height: 10),
              _buildInputCard(
                  child: TextFormField(
                      controller: _nameController,
                      decoration: _inputDeco("Title", "e.g. Brahman Bull"))),
              const SizedBox(height: 12),
              _buildInputCard(
                  child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDeco("Price", "0.00", prefix: "₱ "))),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: _buildInputCard(
                        child: TextFormField(
                            controller: _weightController,
                            decoration: _inputDeco("Weight", "kg")))),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildInputCard(
                        child: TextFormField(
                            controller: _ageController,
                            decoration: _inputDeco("Age", "months")))),
              ]),
              const SizedBox(height: 12),
              _buildInputCard(
                  child: TextFormField(
                      controller: _locationController,
                      decoration: _inputDeco("Location", "City, Province",
                          icon: Icons.location_on_outlined))),
              const SizedBox(height: 24),
              _buildSectionTitle("Description"),
              const SizedBox(height: 10),
              _buildInputCard(
                  child: TextFormField(
                      controller: _descController,
                      maxLines: 5,
                      decoration:
                          _inputDeco("Describe...", "", isMultiLine: true))),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Helpers
  Widget _buildSectionTitle(String t) => Text(t,
      style: TextStyle(
          fontSize: 16, fontWeight: FontWeight.bold, color: textDark));
  Widget _buildInputCard({required Widget child}) => Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: textDark.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ]),
      child: child);
  InputDecoration _inputDeco(String l, String h,
          {String? prefix, IconData? icon, bool isMultiLine = false}) =>
      InputDecoration(
          labelText: isMultiLine ? null : l,
          hintText: h,
          prefixText: prefix,
          prefixIcon: icon != null ? Icon(icon) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16));
}
