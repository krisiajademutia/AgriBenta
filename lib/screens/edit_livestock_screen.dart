import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agribenta/services/livestock_manager.dart';
import '../../models/livestock_model.dart';

class EditLivestockScreen extends StatefulWidget {
  final Livestock livestock;
  const EditLivestockScreen({super.key, required this.livestock});

  @override
  State<EditLivestockScreen> createState() => _EditLivestockScreenState();
}

class _EditLivestockScreenState extends State<EditLivestockScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _shippingController; // Shipping
  late TextEditingController _ageController;
  late TextEditingController _weightController;
  late TextEditingController _locationController;
  late TextEditingController _descController;
  late TextEditingController _quantityController;

  // --- RESTORED: Your Original Icon Registry ---
  final Map<String, IconData> _iconRegistry = {
    'cow': Icons.catching_pokemon,
    'carabao': Icons.agriculture,
    'goat': Icons.grass,
    'pig': Icons.savings,
    'chicken': Icons.egg,
    'duck': Icons.water,
    'other': Icons.grid_view,
  };

  IconData _getIconFromKey(String key) =>
      _iconRegistry[key] ?? Icons.help_outline;

  final Color bgCream = const Color(0xFFF9F6F0);
  final Color textDark = const Color(0xFF1B4332);
  final Color brandGreen = const Color(0xFF52B788);

  @override
  void initState() {
    super.initState();
    final item = widget.livestock;
    _nameController = TextEditingController(text: item.name);
    _priceController =
        TextEditingController(text: item.price.toStringAsFixed(0));
    _shippingController =
        TextEditingController(text: item.shippingFee.toStringAsFixed(0));
    _ageController = TextEditingController(text: item.age);
    _weightController = TextEditingController(text: item.weight);
    _locationController = TextEditingController(text: item.location);
    _descController = TextEditingController(text: item.description);
    _quantityController = TextEditingController(text: item.quantity.toString());

    // FIX: Delay initialization to avoid "setState during build" error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<LivestockManager>().initForEdit(item);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _shippingController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _locationController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<LivestockManager>();

    return Scaffold(
      backgroundColor: bgCream,
      appBar: AppBar(
        title: Text("Edit Listing",
            style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
        backgroundColor: bgCream,
        elevation: 0,
        leading: IconButton(
            icon: Icon(Icons.close, color: textDark),
            onPressed: () => Navigator.pop(context)),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton(
          onPressed: manager.isLoading
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;
                  final success =
                      await manager.saveEdit(widget.livestock, context);
                  if (success && mounted) Navigator.pop(context);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: brandGreen,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: manager.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white))
              : const Text("Save Changes",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. PHOTOS
              _buildSectionTitle("Photos"),
              const SizedBox(height: 10),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: manager.existingUrls.length +
                      manager.newImages.length +
                      1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return GestureDetector(
                        onTap: manager.pickImages,
                        child: Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border:
                                Border.all(color: brandGreen.withOpacity(0.3)),
                          ),
                          child: Icon(Icons.add_a_photo_rounded,
                              size: 30, color: brandGreen),
                        ),
                      );
                    }
                    index--;
                    if (index < manager.existingUrls.length) {
                      return _buildPhotoTile(
                          NetworkImage(manager.existingUrls[index]),
                          () => manager
                              .removeExisting(manager.existingUrls[index]));
                    } else {
                      int newIndex = index - manager.existingUrls.length;
                      return _buildPhotoTile(
                          FileImage(manager.newImages[newIndex]),
                          () => manager.removeNew(newIndex));
                    }
                  },
                ),
              ),

              const SizedBox(height: 24),

              // 2. CATEGORY (RESTORED WITH ICONS)
              _buildSectionTitle("Category"),
              const SizedBox(height: 10),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('categories')
                    .snapshots(),
                builder: (context, snapshot) {
                  // FIX: Bounded height loading state
                  if (!snapshot.hasData) {
                    return const SizedBox(
                        height: 50,
                        child: Center(child: LinearProgressIndicator()));
                  }

                  final categoriesDocs = snapshot.data!.docs;
                  return SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categoriesDocs.length,
                      itemBuilder: (context, index) {
                        final data = categoriesDocs[index].data()
                            as Map<String, dynamic>;
                        final String catName = data['name'] ?? 'Unknown';
                        final String iconKey =
                            data['icon_key'] ?? 'other'; // Icon Key
                        final bool isSelected = manager.category == catName;

                        return GestureDetector(
                          onTap: () => manager.setCategory(catName),
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
                                Icon(_getIconFromKey(iconKey),
                                    size: 18,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey[600]),
                                const SizedBox(width: 8),
                                Text(catName,
                                    style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.grey[600],
                                        fontWeight: FontWeight.bold)),
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

              // 3. INPUTS
              _buildSectionTitle("Item Details"),
              const SizedBox(height: 10),
              _buildInputCard(
                  child: TextFormField(
                      controller: _nameController,
                      onChanged: manager.setName,
                      decoration: _inputDeco("Title", "e.g. Brahman Bull"))),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: _buildInputCard(
                          child: TextFormField(
                              controller: _priceController,
                              onChanged: manager.setPrice,
                              keyboardType: TextInputType.number,
                              decoration:
                                  _inputDeco("Price", "0.00", prefix: "₱ ")))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildInputCard(
                          child: TextFormField(
                              controller: _shippingController,
                              onChanged: manager.setShippingFee,
                              keyboardType: TextInputType.number,
                              decoration: _inputDeco("Shipping", "Fee",
                                  prefix: "₱ ")))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: _buildInputCard(
                          child: TextFormField(
                              controller: _weightController,
                              onChanged: manager.setWeight,
                              keyboardType: TextInputType.number,
                              decoration: _inputDeco("Weight", "kg")))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildInputCard(
                          child: TextFormField(
                              controller: _ageController,
                              onChanged: manager.setAgeMonths,
                              decoration: _inputDeco("Age", "months")))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInputCard(
                      child: TextFormField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDeco("Quantity", "e.g. 5",
                            icon: Icons.inventory),
                        onChanged: (val) =>
                            context.read<LivestockManager>().setQuantity(val),
                        validator: (val) => val!.isEmpty ? "Required" : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
              const SizedBox(height: 12),
              _buildInputCard(
                  child: TextFormField(
                      controller: _locationController,
                      onChanged: manager.setLocation,
                      decoration: _inputDeco("Location", "City, Province",
                          icon: Icons.location_on_outlined))),
              const SizedBox(height: 24),
              _buildSectionTitle("Description"),
              const SizedBox(height: 10),
              _buildInputCard(
                  child: TextFormField(
                      controller: _descController,
                      onChanged: manager.setDescription,
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

  Widget _buildPhotoTile(ImageProvider image, VoidCallback onRemove) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(image: image, fit: BoxFit.cover),
      ),
      child: Align(
        alignment: Alignment.topRight,
        child: GestureDetector(
          onTap: onRemove,
          child: Container(
            margin: const EdgeInsets.all(5),
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.close, size: 14, color: Colors.red),
          ),
        ),
      ),
    );
  }

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
