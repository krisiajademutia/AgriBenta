import 'package:agribenta/services/livestock_manager.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
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
  late TextEditingController _ageController;
  late TextEditingController _weightController;
  late TextEditingController _locationController;
  late TextEditingController _descController;

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
    _nameController = TextEditingController(text: widget.livestock.name);
    _priceController =
        TextEditingController(text: widget.livestock.price.toStringAsFixed(0));
    _ageController = TextEditingController(text: widget.livestock.age);
    _weightController = TextEditingController(text: widget.livestock.weight);
    _locationController =
        TextEditingController(text: widget.livestock.location);
    _descController = TextEditingController(text: widget.livestock.description);
    final manager = context.read<LivestockManager>();
    manager.initForEdit(widget.livestock);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
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
        backgroundColor: bgCream,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Edit Listing",
          style: TextStyle(color: textDark, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: Container(
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
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: manager.isLoading
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 3),
                    ),
                    SizedBox(width: 16),
                    Text("Saving...",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                )
              : const Text("Save Changes",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                        onTap: () => manager.pickImages(),
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
                    index--;

                    if (index < manager.existingUrls.length) {
                      final url = manager.existingUrls[index];
                      return Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(
                              image: NetworkImage(url), fit: BoxFit.cover),
                        ),
                        child: Align(
                          alignment: Alignment.topRight,
                          child: GestureDetector(
                            onTap: () => manager.removeExisting(url),
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
                    }

                    index -= manager.existingUrls.length;
                    return Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                            image: FileImage(manager.newImages[index]),
                            fit: BoxFit.cover),
                      ),
                      child: Align(
                        alignment: Alignment.topRight,
                        child: GestureDetector(
                          onTap: () => manager.removeNew(index),
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

              // Category (same as Add screen)
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
                  onChanged: manager.setName,
                  validator: (v) =>
                      v?.trim().isEmpty ?? true ? "Title required" : null,
                  decoration: _inputDeco("Title", "e.g. Brahman Bull"),
                ),
              ),
              const SizedBox(height: 12),
              _buildInputCard(
                child: TextFormField(
                  controller: _priceController,
                  onChanged: manager.setPrice,
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      v?.isEmpty ?? true ? "Price required" : null,
                  decoration: _inputDeco("Price", "0.00", prefix: "₱ "),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInputCard(
                      child: TextFormField(
                        controller: _weightController,
                        onChanged: manager.setWeight,
                        decoration: _inputDeco("Weight", "kg"),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInputCard(
                      child: TextFormField(
                        controller: _ageController,
                        onChanged: manager.setAgeMonths,
                        decoration: _inputDeco("Age", "yrs"),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInputCard(
                child: TextFormField(
                  controller: _locationController,
                  onChanged: manager.setLocation,
                  decoration: _inputDeco("Location", "City, Province",
                      icon: Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle("Description"),
              const SizedBox(height: 10),
              _buildInputCard(
                child: TextFormField(
                  controller: _descController,
                  onChanged: manager.setDescription,
                  maxLines: 5,
                  decoration: _inputDeco("Describe...", "", isMultiLine: true),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String t) => Text(
        t,
        style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
      );

  Widget _buildInputCard({required Widget child}) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: textDark.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: child,
      );

  InputDecoration _inputDeco(String l, String h,
          {String? prefix, IconData? icon, bool isMultiLine = false}) =>
      InputDecoration(
        labelText: isMultiLine ? null : l,
        hintText: h,
        prefixText: prefix,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.all(16),
      );
}
