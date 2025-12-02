// lib/screens/add_livestock_screen.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; 
import 'dart:io';
import 'package:flutter/foundation.dart'; 


class AddLivestockScreen extends StatefulWidget {
  const AddLivestockScreen({super.key});

  @override
  State<AddLivestockScreen> createState() => _AddLivestockScreenState();
}

class _AddLivestockScreenState extends State<AddLivestockScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Using the platform-agnostic type XFile for the selected image
  XFile? _selectedImage; 
  String? _selectedCategory;

  // Placeholder list of categories
  final List<String> _categories = [
    'Cattle',
    'Swine',
    'Poultry',
    'Goats',
    'Sheep',
    'Others'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // --- Image Picking Function ---
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery); 

    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile;
      });
    }
  }

  // --- Submission Logic (Placeholder) ---
  Future<void> _submitListing() async {
    if (_formKey.currentState!.validate() && _selectedImage != null && _selectedCategory != null) {
      // Form is valid and image is selected

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Processing listing...')),
      );

      await Future.delayed(const Duration(seconds: 2));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Livestock listed successfully!'),
          backgroundColor: Color(0xFF00B761),
        ),
      );

    } else if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image for your listing.')),
      );
    } else if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('List Livestock'),
        backgroundColor: const Color(0xFF0D4C2F),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Product Photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      // Red border if no image is selected, green if it is
                      color: _selectedImage == null ? Colors.red : Colors.green,
                      width: _selectedImage == null ? 1 : 2,
                    ),
                  ),
                child: _selectedImage != null
    ? ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: kIsWeb
            ? Image.network(
                _selectedImage!.path, // On web, path is a URL (blob)
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
              )
            : Image.file(
                File(_selectedImage!.path),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(child: Icon(Icons.error, color: Colors.red));
                },
              ),
      )
    : Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt, size: 50, color: Colors.grey[600]),
          const SizedBox(height: 8),
          const Text('Tap to select image', style: TextStyle(color: Colors.grey)),
        ],
      ),
                ),
              ),
              const SizedBox(height: 30),

              // --- 2. Product Details ---
              _buildSectionTitle('Basic Details'),
              const SizedBox(height: 15),
              _buildTextField(
                controller: _nameController,
                labelText: 'Name / Breed',
                hintText: 'e.g., Brahman Bull, Rhode Island Red Hen',
                validator: (value) => value!.isEmpty ? 'Please enter a name.' : null,
              ),
              const SizedBox(height: 20),
              _buildPriceField(),
              const SizedBox(height: 20),
              
              // --- 3. Category Dropdown ---
              _buildDropdownField(
                'Category',
                _categories,
                _selectedCategory,
                (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
              ),
              const SizedBox(height: 30),


              // --- 4. Specifications ---
              _buildSectionTitle('Specifications'),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _ageController,
                      labelText: 'Age',
                      hintText: 'e.g., 6 months, 2 years',
                      validator: (value) => value!.isEmpty ? 'Enter age.' : null,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildTextField(
                      controller: _weightController,
                      labelText: 'Weight',
                      hintText: 'e.g., 200kg, 1.5kg',
                      validator: (value) => value!.isEmpty ? 'Enter weight.' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _locationController,
                labelText: 'Location',
                hintText: 'e.g., Tagum City, Davao del Norte',
                icon: Icons.location_on_outlined,
                validator: (value) => value!.isEmpty ? 'Please enter the location.' : null,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _descriptionController,
                labelText: 'Description',
                hintText: 'Describe the health, disposition, and key features of the animal.',
                maxLines: 4,
                validator: (value) => value!.isEmpty ? 'Please enter a description.' : null,
              ),
              const SizedBox(height: 40),

              // --- 5. Submit Button ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitListing,
                  icon: const Icon(Icons.check_circle_outline, size: 28),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Text('POST LISTING', style: TextStyle(fontSize: 18)),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00B761), // Primary Green
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 5,
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF0D4C2F),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    IconData? icon,
    int maxLines = 1,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF0D4C2F)) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF00B761), width: 2.0),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildPriceField() {
    return TextFormField(
      controller: _priceController,
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a price.';
        }
        if (double.tryParse(value) == null) {
          return 'Please enter a valid number.';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: 'Price (in PHP)',
        hintText: 'e.g., 25000.00',
        // Using a standard currency icon
        prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF0D4C2F)), 
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF00B761), width: 2.0),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildDropdownField(
    String labelText,
    List<String> items,
    String? selectedValue,
    void Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: selectedValue,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: const Icon(Icons.category_outlined, color: Color(0xFF0D4C2F)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF00B761), width: 2.0),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'Please select a $labelText.' : null,
    );
  }
}