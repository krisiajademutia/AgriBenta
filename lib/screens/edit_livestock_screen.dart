import 'package:agribenta/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agribenta/services/livestock_manager.dart';
import '../../models/livestock_model.dart';
import 'package:agribenta/models/category_model.dart';

class EditLivestockScreen extends StatefulWidget {
  final Livestock livestock;
  const EditLivestockScreen({super.key, required this.livestock});

  @override
  State<EditLivestockScreen> createState() => _EditLivestockScreenState();
}

class _EditLivestockScreenState extends State<EditLivestockScreen> {
  final _formKey = GlobalKey<FormState>();

  // --- CONTROLLERS ---
  late TextEditingController _nameController;
  late TextEditingController _shippingController;
  late TextEditingController _ageController;
  late TextEditingController _descController;
  List<Map<String, TextEditingController>> _variantControllers = [];

  // --- LOCATION STATE ---
  bool _isLocationLoaded = false;
  String? _selectedRegion;
  String? _selectedProvince;
  String? _selectedCity;
  String? _selectedBarangay;

  // Colors (Matching Add Screen)
  final Color bgCream = const Color(0xFFF9F6F0);
  final Color textDark = const Color(0xFF1B4332);
  final Color brandGreen = const Color(0xFF52B788);

  @override
  void initState() {
    super.initState();
    _initData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.warning_amber_rounded, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Note: Please upload LIVESTOCK photos only.Avoid non-related posts.",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange[800], // Warning Color
            duration: const Duration(seconds: 6), // Stay longer so they read it
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(20),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    });
  }

  Future<void> _initData() async {
    // 1. Initialize Location Service
    await LocationService.loadData();
    if (mounted) setState(() => _isLocationLoaded = true);

    // 2. Initialize Manager Data (Photos, Category)
    final manager = Provider.of<LivestockManager>(context, listen: false);
    manager.initForEdit(widget.livestock);

    // 3. Initialize Text Controllers
    _nameController = TextEditingController(text: widget.livestock.name);
    _shippingController =
        TextEditingController(text: widget.livestock.shippingFee.toString());
    _ageController = TextEditingController(text: widget.livestock.age);
    _descController = TextEditingController(text: widget.livestock.description);

    // 4. Initialize Variants (Load existing options)
    if (widget.livestock.variants.isNotEmpty) {
      for (var v in widget.livestock.variants) {
        _variantControllers.add({
          'weight': TextEditingController(text: v.weight),
          'price': TextEditingController(text: v.price.toStringAsFixed(0)),
          'qty': TextEditingController(text: v.quantity.toString()),
        });
      }
    } else {
      // Legacy fallback
      _variantControllers.add({
        'weight': TextEditingController(text: widget.livestock.weight),
        'price': TextEditingController(
            text: widget.livestock.price.toStringAsFixed(0)),
        'qty':
            TextEditingController(text: widget.livestock.quantity.toString()),
      });
    }
  }

  // --- VARIANT LOGIC ---
  void _addVariantRow() {
    setState(() {
      _variantControllers.add({
        'weight': TextEditingController(),
        'price': TextEditingController(),
        'qty': TextEditingController(),
      });
    });
  }

  void _removeVariantRow(int index) {
    if (_variantControllers.length > 1) {
      setState(() {
        _variantControllers.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You need at least one size option.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use Consumer to rebuild when manager state changes (images, etc)
    return Consumer<LivestockManager>(
      builder: (context, manager, child) {
        return Scaffold(
          backgroundColor: bgCream,
          appBar: AppBar(
            backgroundColor: bgCream,
            elevation: 0,
            leading: IconButton(
                icon: Icon(Icons.close, color: textDark),
                onPressed: () => Navigator.pop(context)),
            title: Text("Edit Livestock",
                style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
            centerTitle: true,
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: manager.isSaving
                  ? null
                  : () async {
                      if (!_formKey.currentState!.validate()) return;

                      // Require at least one image (Old or New)
                      if (manager.existingUrls.isEmpty &&
                          manager.newImages.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text("Please include at least one photo")));
                        return;
                      }

                      // --- 1. GATHER VARIANT DATA & CALC TOTALS ---
                      List<LivestockVariant> finalVariants = [];
                      double minPrice = double.infinity;
                      int totalQty = 0;
                      String displayWeight = "";

                      for (var controllers in _variantControllers) {
                        String w = controllers['weight']!.text.trim();
                        double p = double.tryParse(
                                controllers['price']!.text.trim()) ??
                            0.0;
                        int q =
                            int.tryParse(controllers['qty']!.text.trim()) ?? 0;

                        finalVariants.add(
                            LivestockVariant(weight: w, price: p, quantity: q));

                        if (p < minPrice) minPrice = p;
                        totalQty += q;
                        if (displayWeight.isEmpty) displayWeight = w;
                      }

                      if (minPrice == double.infinity) minPrice = 0.0;

                      // --- 2. LOCATION LOGIC ---
                      // If user selected dropdowns, use them. Else keep original.
                      String finalLocation = widget.livestock.location;
                      if (_selectedCity != null) {
                        finalLocation =
                            "$_selectedRegion, $_selectedProvince, $_selectedCity";
                        if (_selectedBarangay != null) {
                          finalLocation += ", $_selectedBarangay";
                        }
                      }

                      // --- 3. SUBMIT UPDATE ---
                      try {
                        await manager.updateLivestock(
                          docId: widget.livestock.id,
                          name: _nameController.text,
                          category: manager.category ?? 'other',
                          price: minPrice,
                          weight: displayWeight,
                          quantity: totalQty,
                          description: _descController.text,
                          location: finalLocation,
                          age: _ageController.text,
                          shippingFee:
                              double.tryParse(_shippingController.text) ?? 0.0,
                          existingUrls: manager.existingUrls,
                          newImages: manager.newImages,
                          variants: finalVariants,
                        );

                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: const Text("Changes Saved!"),
                                backgroundColor: brandGreen),
                          );
                        }
                      } catch (e) {
                        // Error handled in manager/UI
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: brandGreen,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: manager.isSaving
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
                  // 1. PHOTOS (Existing + New)
                  _buildSectionTitle("Photos"),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      // Count = AddButton + ExistingImages + NewImages
                      itemCount: 1 +
                          manager.existingUrls.length +
                          manager.newImages.length,
                      itemBuilder: (context, index) {
                        // A. Add Button (Always first)
                        if (index == 0) {
                          return GestureDetector(
                            onTap: manager
                                .pickImage, // Using single pick for simplicity or pickImages for multi
                            child: Container(
                              width: 120,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: brandGreen.withOpacity(0.3)),
                              ),
                              child: Icon(Icons.add_a_photo_rounded,
                                  size: 30, color: brandGreen),
                            ),
                          );
                        }

                        // B. Existing Images
                        int existingCount = manager.existingUrls.length;
                        if (index <= existingCount) {
                          int realIndex = index - 1;
                          String url = manager.existingUrls[realIndex];
                          return _buildPhotoThumb(
                            imageProvider: NetworkImage(url),
                            onRemove: () => manager.removeExisting(url),
                          );
                        }

                        // C. New Images
                        int newIndex = index - 1 - existingCount;
                        return _buildPhotoThumb(
                          imageProvider: FileImage(manager.newImages[newIndex]),
                          onRemove: () => manager.removeNew(newIndex),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2. CATEGORY
                  _buildSectionTitle("Category"),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('categories')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox(height: 50);
                      final categoriesDocs = snapshot.data!.docs;
                      return SizedBox(
                        height: 50,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: categoriesDocs.length,
                          itemBuilder: (context, index) {
                            final doc = categoriesDocs[index];
                            final categoryObj = Category.fromSnapshot(
                                doc.id, doc.data() as Map<String, dynamic>);
                            final bool isSelected =
                                manager.category == categoryObj.name;

                            return GestureDetector(
                              onTap: () =>
                                  manager.setCategory(categoryObj.name),
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
                                    Text(
                                      categoryObj.getEmoji(),
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(categoryObj.name,
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

                  // 3. ITEM DETAILS
                  _buildSectionTitle("Item Details"),
                  const SizedBox(height: 10),
                  _buildInputCard(
                      child: TextFormField(
                          controller: _nameController,
                          validator: (v) => v!.isEmpty ? "Required" : null,
                          decoration:
                              _inputDeco("Title", "e.g. Brahman Bull"))),
                  const SizedBox(height: 12),

                  // 4. SIZES & VARIANTS
                  _buildSectionTitle("Sizes & Prices"),
                  const SizedBox(height: 4),
                  const Text("Add options like 50kg, 100kg",
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 10),

                  ..._variantControllers.asMap().entries.map((entry) {
                    int idx = entry.key;
                    var controllers = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: controllers['weight'],
                                  decoration: _inputDeco("Weight", "e.g. 50kg"),
                                  validator: (v) => v!.isEmpty ? "Req" : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: controllers['price'],
                                  keyboardType: TextInputType.number,
                                  decoration:
                                      _inputDeco("Price", "0.00", prefix: "₱"),
                                  validator: (v) => v!.isEmpty ? "Req" : null,
                                ),
                              ),
                              if (_variantControllers.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red),
                                  onPressed: () => _removeVariantRow(idx),
                                )
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: controllers['qty'],
                            keyboardType: TextInputType.number,
                            decoration: _inputDeco(
                                "Stock Quantity", "Available heads",
                                icon: Icons.inventory_2_outlined),
                            validator: (v) => v!.isEmpty ? "Req" : null,
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  // Add Variant Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _addVariantRow,
                      icon: const Icon(Icons.add),
                      label: const Text("Add Another Size Option"),
                      style:
                          OutlinedButton.styleFrom(foregroundColor: brandGreen),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 5. LOCATION
                  _buildSectionTitle("Location"),
                  const SizedBox(height: 4),
                  // Display current location for reference
                  Text("Current: ${widget.livestock.location}",
                      style: TextStyle(
                          color: brandGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                  const SizedBox(height: 10),

                  if (!_isLocationLoaded)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    _buildDropdown(
                        "Region", _selectedRegion, LocationService.getRegions(),
                        (val) {
                      setState(() {
                        _selectedRegion = val;
                        _selectedProvince = null;
                        _selectedCity = null;
                        _selectedBarangay = null;
                      });
                    }),
                    const SizedBox(height: 10),
                    _buildDropdown(
                        "Province",
                        _selectedProvince,
                        _selectedRegion == null
                            ? []
                            : LocationService.getProvinces(_selectedRegion!),
                        (val) {
                      setState(() {
                        _selectedProvince = val;
                        _selectedCity = null;
                        _selectedBarangay = null;
                      });
                    }),
                    const SizedBox(height: 10),
                    _buildDropdown(
                        "City / Municipality",
                        _selectedCity,
                        (_selectedRegion == null || _selectedProvince == null)
                            ? []
                            : LocationService.getCities(
                                _selectedRegion!, _selectedProvince!), (val) {
                      setState(() {
                        _selectedCity = val;
                        _selectedBarangay = null;
                      });
                    }),
                    const SizedBox(height: 10),
                    _buildDropdown(
                        "Barangay",
                        _selectedBarangay,
                        _selectedCity == null
                            ? []
                            : LocationService.getBarangays(_selectedRegion!,
                                _selectedProvince!, _selectedCity!), (val) {
                      setState(() => _selectedBarangay = val);
                    }),
                  ],

                  const SizedBox(height: 24),

                  // 6. EXTRA DETAILS
                  _buildSectionTitle("Additional Details"),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: _buildInputCard(
                          child: TextFormField(
                              controller: _ageController,
                              decoration: _inputDeco("Age", "e.g. 2 yrs"))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInputCard(
                          child: TextFormField(
                              controller: _shippingController,
                              keyboardType: TextInputType.number,
                              decoration:
                                  _inputDeco("Shipping", "Fee", prefix: "₱ "))),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  _buildInputCard(
                      child: TextFormField(
                          controller: _descController,
                          maxLines: 5,
                          decoration: _inputDeco(
                              "Description", "Describe health, breed...",
                              isMultiLine: true))),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildPhotoThumb(
      {required ImageProvider imageProvider, required VoidCallback onRemove}) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
      ),
      child: Align(
        alignment: Alignment.topRight,
        child: GestureDetector(
          onTap: onRemove,
          child: const Icon(Icons.cancel, color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items,
      Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: textDark.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ]),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(label, style: TextStyle(color: Colors.grey[600])),
          isExpanded: true,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
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
