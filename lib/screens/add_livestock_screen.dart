// lib/screens/add_livestock_screen.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:agribenta/services/livestock_manager.dart'; 

class AddLivestockScreen extends StatelessWidget {
  const AddLivestockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen: false since we only want to call methods, not rebuild
    final manager = Provider.of<LivestockManager>(context, listen: false); 
    final locationController = TextEditingController(text: manager.location);
    final _formKey = GlobalKey<FormState>();

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
              // --- 1. Product Photos (Multiple Photos) ---
              _buildSectionTitle('Product Photos'),
              const SizedBox(height: 10),
              Consumer<LivestockManager>( // Listens to image list changes
                builder: (context, mgr, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Horizontal scrollable list of selected images
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: mgr.tempImageFiles.length + 1, // +1 for the Add button
                          itemBuilder: (context, index) {
                            if (index == mgr.tempImageFiles.length) {
                              return _buildAddPhotoTile(mgr);
                            }
                            
                            return _buildImageTile(mgr, mgr.tempImageFiles[index]);
                          },
                        ),
                      ),
                      if (mgr.tempImageFiles.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text('At least one photo is required.', style: TextStyle(color: Colors.red, fontSize: 12)),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 30),

              // --- 2. Basic Details ---
              _buildSectionTitle('Basic Details'),
              const SizedBox(height: 15),
              
              // Name Input
              _buildTextField(
                onChanged: manager.setName,
                labelText: 'Name / Breed',
                hintText: 'e.g., Brahman Bull, Rhode Island Red Hen',
                validator: (value) => value!.isEmpty ? 'Please enter a name.' : null,
              ),
              const SizedBox(height: 20),
              
              // Price Input (₱ Peso symbol)
              _buildPriceField(manager.setPrice),
              const SizedBox(height: 20),
              
              // Category Dropdown
              Consumer<LivestockManager>( // Listens to category list and selected category
                builder: (context, mgr, child) {
                  if (mgr.isLoadingCategories) {
                    return const Center(child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 10.0),
                      child: LinearProgressIndicator(),
                    ));
                  }
                  final dynamicCategories = mgr.availableCategories;
                  return _buildDropdownField(
                    'Category',
                    dynamicCategories,
                    mgr.category, 
                    (String? newValue) {
                      if (newValue != null) {
                        manager.setCategory(newValue);
                      }
                    },
                  );
                }
              ),
              const SizedBox(height: 30),

              // --- 3. Specifications ---
              _buildSectionTitle('Specifications'),
              const SizedBox(height: 15),
              
              // Age and Weight
              Row(
                children: [
                  Expanded(
                    child: _buildAgeField(manager), 
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildTextField(
                      onChanged: manager.setWeight,
                      labelText: 'Weight',
                      hintText: 'e.g., 200kg, 1.5kg',
                      validator: (value) => value!.isEmpty ? 'Enter weight.' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Location Input
              Consumer<LivestockManager>( // Listens to location updates (e.g., GPS)
                builder: (context, mgr, child) {
                  // Keep the TextEditingController in sync with the Manager's state
                  locationController.text = mgr.location ?? '';
                  locationController.selection = TextSelection.fromPosition(TextPosition(offset: locationController.text.length));
                  
                  return _buildLocationField(
                    controller: locationController,
                    onChanged: manager.setLocation,
                    onGetGps: mgr.isSaving || mgr.isLoadingLocation ? null : () async {
                      await mgr.getCurrentLocation();
                      if (mgr.location != 'Location Error') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Location updated via GPS!')),
                        );
                      }
                    },
                    isLoading: mgr.isLoadingLocation,
                    readOnly: mgr.isLoadingLocation,
                  );
                }
              ),
              
              const SizedBox(height: 20),

              // --- NEW: Description Input ---
              _buildTextField(
                onChanged: manager.setDescription, // Saves to manager state
                labelText: 'Description',
                hintText: 'Provide details about the breed, health, feeding habits, etc.',
                validator: (value) => value!.isEmpty ? 'Please enter a product description.' : null,
                keyboardType: TextInputType.multiline,
                maxLines: 4, // Enables multiline input
              ),
              
              const SizedBox(height: 40),

              // --- 4. Submit Button ---
              Consumer<LivestockManager>( // Listens to isSaving state
                builder: (context, mgr, child) {
                  final hasImages = mgr.tempImageFiles.isNotEmpty;
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: mgr.isSaving ? null : () async {
                        if (_formKey.currentState!.validate() && hasImages) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Posting listing...')),
                          );
                          
                          final success = await mgr.postListing();
                          
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Livestock listed successfully!'),
                                backgroundColor: Color(0xFF00B761),
                              ),
                            );
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to post. Check required fields and Firebase Storage billing.')),
                            );
                          }
                        } else if (!hasImages) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select at least one image for your listing.')),
                          );
                        }
                      },
                      icon: const Icon(Icons.check_circle_outline, size: 28),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: mgr.isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('POST LISTING', style: TextStyle(fontSize: 18)),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00B761),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 5,
                      ),
                    ),
                  );
                }
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets (UNCHANGED except for _buildTextField) ---

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

  // UPDATED: Now supports maxLines for multiline input
  Widget _buildTextField({
    void Function(String)? onChanged,
    required String labelText,
    String? hintText,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1, 
  }) {
    return TextFormField(
      onChanged: onChanged,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines, 
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.grey, width: 1.0)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF00B761), width: 2.0)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
  
  Widget _buildAgeField(LivestockManager manager) {
    return Consumer<LivestockManager>(
      builder: (context, mgr, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    onChanged: manager.setAgeYears,
                    keyboardType: TextInputType.number,
                    decoration: _buildAgeInputDecoration('Years', '0'),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: TextFormField(
                    onChanged: manager.setAgeMonths,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final isYearsEmpty = mgr.ageYears == null || mgr.ageYears!.isEmpty;
                      final isMonthsEmpty = value == null || value.isEmpty;

                      if (isYearsEmpty && isMonthsEmpty) {
                        return 'Enter age in months or years.';
                      }
                      return null;
                    },
                    decoration: _buildAgeInputDecoration('Months', '1-11'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  InputDecoration _buildAgeInputDecoration(String labelText, String hintText) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.grey, width: 1.0)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF00B761), width: 2.0)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
    );
  }

  Widget _buildPriceField(void Function(String) onChanged) {
    return TextFormField(
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter a price.';
        if (double.tryParse(value) == null) return 'Please enter a valid number.';
        return null;
      },
      decoration: InputDecoration(
        labelText: 'Price',
        hintText: 'e.g., 25000.00',
        prefixText: '₱ ', 
        prefixStyle: const TextStyle(color: Color(0xFF0D4C2F), fontSize: 16, fontWeight: FontWeight.bold),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.grey, width: 1.0)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF00B761), width: 2.0)),
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.grey, width: 1.0)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF00B761), width: 2.0)),
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

  Widget _buildLocationField({
    required TextEditingController controller,
    required void Function(String) onChanged,
    required void Function()? onGetGps,
    required bool isLoading,
    required bool readOnly,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onChanged: onChanged,
      validator: (value) => value!.isEmpty ? 'Please enter the location.' : null,
      decoration: InputDecoration(
        labelText: 'Location',
        hintText: 'e.g., Tagum City, Davao del Norte',
        prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF0D4C2F)),
        suffixIcon: IconButton(
          icon: isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.my_location, color: Color(0xFF0D4C2F)),
          onPressed: onGetGps,
          tooltip: 'Get Current Location',
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.grey, width: 1.0)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF00B761), width: 2.0)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildAddPhotoTile(LivestockManager mgr) {
    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: GestureDetector(
        onTap: mgr.isSaving ? null : () async {
          final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70); 
          if (pickedFile != null) {
            mgr.addImageFile(File(pickedFile.path));
          }
        },
        child: Container(
          width: 120,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[400]!),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo, size: 40, color: Colors.grey[600]),
              const Text('Add Photo', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageTile(LivestockManager mgr, File file) {
    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: Stack(
        children: [
          Container(
            width: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(
                image: FileImage(file),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 5,
            right: 5,
            child: GestureDetector(
              onTap: mgr.isSaving ? null : () => mgr.removeImageFile(file),
              child: const CircleAvatar(
                radius: 12,
                backgroundColor: Colors.red,
                child: Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}