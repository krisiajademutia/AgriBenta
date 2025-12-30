import 'package:agribenta/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agribenta/services/livestock_manager.dart';
import '../../models/livestock_model.dart';
// import 'services/location_service.dart'; // Uncomment if needed

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
  late TextEditingController _shippingController;
  late TextEditingController _ageController;
  late TextEditingController _weightController;
  // _locationController REMOVED
  late TextEditingController _descController;
  late TextEditingController _quantityController;

  // --- LOCATION STATE ---
  bool _isLocationLoaded = false;
  String? _selectedRegion;
  String? _selectedProvince;
  String? _selectedCity;
  String? _selectedBarangay;
  String? _originalLocation; // To display current value

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
    _initLocation();

    final item = widget.livestock;
    _nameController = TextEditingController(text: item.name);
    _priceController =
        TextEditingController(text: item.price.toStringAsFixed(0));
    _shippingController =
        TextEditingController(text: item.shippingFee.toStringAsFixed(0));
    _ageController = TextEditingController(text: item.age);
    _weightController = TextEditingController(text: item.weight);
    _descController = TextEditingController(text: item.description);
    _quantityController = TextEditingController(text: item.quantity.toString());

    // Store original location to display
    _originalLocation = item.location;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<LivestockManager>().initForEdit(item);
    });
  }

  Future<void> _initLocation() async {
    await LocationService.loadData();
    if (mounted) setState(() => _isLocationLoaded = true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _shippingController.dispose();
    _ageController.dispose();
    _weightController.dispose();
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
              // 2. CATEGORY & INPUTS (Same as before, abbreviated here for brevity)
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
              // ... Add Weight/Age/Quantity rows here (same as AddLivestock) ...

              const SizedBox(height: 12),

              // --- LOCATION EDITING ---
              _buildSectionTitle("Location"),
              const SizedBox(height: 10),

              // Display Current Location
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Current Location:",
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(_originalLocation ?? "Not set",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textDark)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text("Select new location to override:",
                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),

              if (!_isLocationLoaded)
                const Center(child: CircularProgressIndicator())
              else ...[
                // DROPDOWNS
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
                const SizedBox(height: 8),
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
                const SizedBox(height: 8),
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
                    // UPDATE MANAGER
                    manager.setLocation(val ?? "");
                  });
                }),
                const SizedBox(height: 8),
                _buildDropdown(
                    "Barangay",
                    _selectedBarangay,
                    _selectedCity == null
                        ? []
                        : LocationService.getBarangays(_selectedRegion!,
                            _selectedProvince!, _selectedCity!),
                    (val) => setState(() => _selectedBarangay = val)),
              ],

              const SizedBox(height: 24),
              // Description
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

  // Helper widgets (Same as AddLivestockScreen)
  Widget _buildDropdown(String label, String? value, List<String> items,
      Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(label),
          isExpanded: true,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ... Include _buildPhotoTile, _buildSectionTitle, _buildInputCard, _inputDeco from previous file ...
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
