import 'package:agribenta/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agribenta/services/livestock_manager.dart';

class AddLivestockScreen extends StatefulWidget {
  const AddLivestockScreen({super.key});

  @override
  State<AddLivestockScreen> createState() => _AddLivestockScreenState();
}

class _AddLivestockScreenState extends State<AddLivestockScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _shippingController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  // _locationController REMOVED -> Replaced by Dropdowns
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  // --- LOCATION STATE ---
  bool _isLocationLoaded = false;
  String? _selectedRegion;
  String? _selectedProvince;
  String? _selectedCity;
  String? _selectedBarangay;

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
  }

  Future<void> _initLocation() async {
    await LocationService.loadData();
    if (mounted) setState(() => _isLocationLoaded = true);
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
            onPressed: () => Navigator.pop(context)),
        title: Text("Sell Livestock",
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
                  // Validation for Location
                  if (_selectedCity == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Please select a City/Municipality")));
                    return;
                  }

                  final success = await manager.postListing();
                  if (success && mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: const Text("Success!"),
                          backgroundColor: brandGreen),
                    );
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: brandGreen,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: manager.isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white))
              : const Text("Post Listing",
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
                  itemCount: manager.newImages.length + 1,
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
                    return Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                            image: FileImage(manager.newImages[index - 1]),
                            fit: BoxFit.cover),
                      ),
                      child: Align(
                        alignment: Alignment.topRight,
                        child: GestureDetector(
                          onTap: () => manager.removeNew(index - 1),
                          child: const Icon(Icons.cancel, color: Colors.red),
                        ),
                      ),
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

              // 3. ITEM DETAILS
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
                                _inputDeco("Price", "0.00", prefix: "₱ "))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInputCard(
                        child: TextFormField(
                            controller: _shippingController,
                            onChanged: manager.setShippingFee,
                            keyboardType: TextInputType.number,
                            decoration:
                                _inputDeco("Shipping", "Fee", prefix: "₱ "))),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: _buildInputCard(
                        child: TextFormField(
                            controller: _weightController,
                            onChanged: manager.setWeight,
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
                        icon: Icons.inventory_2_outlined),
                    onChanged: (val) => manager.setQuantity(val),
                  ),
                )),
              ]),

              const SizedBox(height: 24),

              // --- 4. LOCATION (NEW DROPDOWNS) ---
              _buildSectionTitle("Location"),
              const SizedBox(height: 10),
              if (!_isLocationLoaded)
                const Center(child: CircularProgressIndicator())
              else ...[
                // REGION
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
                // PROVINCE
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
                // CITY
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
                    // CRITICAL: We save the City as the location for Shipping Calc compatibility
                    manager.setLocation(val ?? "");
                  });
                }),
                const SizedBox(height: 10),
                // BARANGAY
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

              // 5. DESCRIPTION
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

  // --- HELPER WIDGETS ---

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
