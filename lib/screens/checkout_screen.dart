import 'dart:convert';
import 'package:agribenta/models/cart_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cart_manager.dart';
import '../services/order_manager.dart';
import 'package:flutter/services.dart';
import 'package:agribenta/services/shipping_calculator.dart';

// -----------------------------------------------------------------------------
// SERVICE: Handles Loading the Philippines Location JSON
// -----------------------------------------------------------------------------
class LocationService {
  static Map<String, dynamic>? _fullData;

  static Future<void> loadData() async {
    if (_fullData != null) return;
    try {
      final String response =
          await rootBundle.loadString('assets/ph_locations.json');
      _fullData = json.decode(response);
    } catch (e) {
      debugPrint("Error loading location data: $e");
    }
  }

  static List<String> getRegions() {
    if (_fullData == null) return [];
    return _fullData!.keys.toList();
  }

  static List<String> getProvinces(String region) {
    if (_fullData == null || !_fullData!.containsKey(region)) return [];
    try {
      Map<String, dynamic> provinceList = _fullData![region]['province_list'];
      return provinceList.keys.toList();
    } catch (e) {
      return [];
    }
  }

  static List<String> getCities(String region, String province) {
    if (_fullData == null) return [];
    try {
      Map<String, dynamic> cityList =
          _fullData![region]['province_list'][province]['municipality_list'];
      return cityList.keys.toList();
    } catch (e) {
      return [];
    }
  }

  static List<String> getBarangays(
      String region, String province, String city) {
    if (_fullData == null) return [];
    try {
      List<dynamic> bList = _fullData![region]['province_list'][province]
          ['municipality_list'][city]['barangay_list'];
      return bList.map((e) => e.toString()).toList();
    } catch (e) {
      return [];
    }
  }
}

// -----------------------------------------------------------------------------
// CHECKOUT SCREEN WIDGET
// -----------------------------------------------------------------------------
class CheckoutScreen extends StatefulWidget {
  final List<CartItem> items;
  const CheckoutScreen(
      {super.key, required this.items, required double totalAmount});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // --- STATE ---
  String? _selectedRegion;
  String? _selectedProvince;
  String? _selectedCity;
  String? _selectedBarangay;
  bool _isLocationLoaded = false;

  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _gcashRefController = TextEditingController();

  String _paymentMethod = 'COD';
  bool _isPickUp = false;
  double _shippingFee = 0.0;
  String _shippingLabel = "Enter address to calculate";
  String _sellerPhone = "Loading...";
  bool _isLoading = false;

  // --- BRAND COLORS ---
  final Color _primaryColor = const Color(0xFF1B4332); // Dark Green
  final Color _accentColor = const Color(0xFF52B788); // Light Green
  final Color _bgColor = const Color(0xFFF4F6F8); // Soft Grey Background

  @override
  void initState() {
    super.initState();
    _initLocationData();
    _fetchSellerInfo();
  }

  Future<void> _fetchSellerInfo() async {
    if (widget.items.isEmpty) return;

    // We get the sellerId from the first item in the cart
    final sellerId = widget.items.first.livestock.sellerId;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(sellerId)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          // Fetch 'phone' field, fallback if missing
          _sellerPhone = doc.data()?['phone'] ?? "No # Provided";
        });
      }
    } catch (e) {
      debugPrint("Error fetching seller phone: $e");
    }
  }

  Future<void> _initLocationData() async {
    await LocationService.loadData();
    if (mounted) setState(() => _isLocationLoaded = true);
  }

  @override
  void dispose() {
    _streetController.dispose();
    _gcashRefController.dispose();
    super.dispose();
  }

  // --- LOGIC ---
  void _calculateShipping() {
    if (_isPickUp) {
      setState(() {
        _shippingFee = 0.0;
        _shippingLabel = "Customer Pickup (Free)";
      });
      return;
    }
    if (_selectedCity == null) {
      setState(() {
        _shippingFee = 0.0;
        _shippingLabel = "Select City to calculate";
      });
      return;
    }

    double totalShipping = 0.0;
    double maxSurchargeFound = 0.0;

    for (var item in widget.items) {
      double baseFee = item.livestock.shippingFee;
      double surcharge = ShippingCalculator.calculateSurcharge(
        buyerCity: _selectedCity!,
        buyerProvince: _selectedProvince!,
        buyerRegion: _selectedRegion!,
        sellerLocationString: item.livestock.location,
      );
      totalShipping += (baseFee + surcharge);

      if (surcharge > maxSurchargeFound) {
        maxSurchargeFound = surcharge;
      }
    }

    setState(() {
      _shippingFee = totalShipping;
      // Get the correct label text from the helper too!
      _shippingLabel = ShippingCalculator.getLabel(maxSurchargeFound);
    });
  }

  // FIXED: Changed 0 to 0.0 to match the double type of totalPrice
  double get subtotal =>
      widget.items.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get total => subtotal + _shippingFee;

  Future<void> _placeOrder() async {
    if (!_isPickUp &&
        (_selectedBarangay == null || _streetController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please complete your address")));
      return;
    }
    if (_paymentMethod == 'GCash' && _gcashRefController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter GCash Reference No.")));
      return;
    }

    setState(() => _isLoading = true);

    String finalAddress = _isPickUp
        ? "Customer Pickup"
        : "${_streetController.text}, Brgy. $_selectedBarangay, $_selectedCity, $_selectedProvince, $_selectedRegion";

    String paymentDetails = _paymentMethod == 'GCash'
        ? "GCash (Ref: ${_gcashRefController.text.trim()})"
        : "COD";

    final success = await OrderManager().placeOrder(
      items: widget.items,
      totalAmount: total,
      deliveryAddress: finalAddress,
      paymentMethod: paymentDetails,
      isPickup: _isPickUp,
      context: context,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      final cartManager = context.read<CartManager>();
      // FIXED: Used item.livestock.id instead of item.id
      for (var item in widget.items) {
        await cartManager.removeItem(item.livestock.id);
      }
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, color: _accentColor, size: 80),
            const SizedBox(height: 20),
            const Text("Order Placed!",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              _paymentMethod == 'GCash'
                  ? "We are verifying your payment. You will be notified shortly."
                  : "Please prepare the exact amount upon delivery.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop(); // 1. Close the Success Dialog
                  Navigator.of(context).pop(); // 2. Close Checkout Screen
                  Navigator.of(context)
                      .pop(); // 3. Close Cart Screen -> Back to Marketplace
                },
                child: const Text("Back to Home",
                    style: TextStyle(color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: Text("Checkout",
            style:
                TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: _primaryColor),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      bottomNavigationBar: _buildBottomSummary(),
      body: !_isLocationLoaded
          ? Center(child: CircularProgressIndicator(color: _accentColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildAddressSection(),
                  const SizedBox(height: 16),
                  _buildOrderSummarySection(),
                  const SizedBox(height: 16),
                  _buildPaymentSection(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  // --- SECTION: ADDRESS ---
  Widget _buildAddressSection() {
    return _buildCardContainer(
      title: "Shipping Details",
      icon: Icons.location_on_outlined,
      child: Column(
        children: [
          // Pickup Toggle
          Container(
            decoration: BoxDecoration(
              color: _isPickUp
                  ? _accentColor.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: _isPickUp ? _accentColor : Colors.grey.shade300),
            ),
            child: SwitchListTile(
              activeColor: _primaryColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              title: Text("I will pick up the item",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor)),
              subtitle: const Text("Free • Meet up with seller",
                  style: TextStyle(fontSize: 12)),
              value: _isPickUp,
              onChanged: (val) {
                setState(() {
                  _isPickUp = val;
                  _calculateShipping();
                });
              },
            ),
          ),

          if (!_isPickUp) ...[
            const SizedBox(height: 16),
            _buildModernDropdown(
                "Region", _selectedRegion, LocationService.getRegions(), (val) {
              setState(() {
                _selectedRegion = val;
                _selectedProvince = null;
                _selectedCity = null;
                _selectedBarangay = null;
              });
            }),
            const SizedBox(height: 12),
            _buildModernDropdown(
                "Province",
                _selectedProvince,
                _selectedRegion == null
                    ? []
                    : LocationService.getProvinces(_selectedRegion!), (val) {
              setState(() {
                _selectedProvince = val;
                _selectedCity = null;
                _selectedBarangay = null;
              });
            }),
            const SizedBox(height: 12),
            _buildModernDropdown(
                "City / Municipality",
                _selectedCity,
                (_selectedRegion == null || _selectedProvince == null)
                    ? []
                    : LocationService.getCities(
                        _selectedRegion!, _selectedProvince!), (val) {
              setState(() {
                _selectedCity = val;
                _selectedBarangay = null;
                _calculateShipping();
              });
            }),
            const SizedBox(height: 12),
            _buildModernDropdown(
                "Barangay",
                _selectedBarangay,
                _selectedCity == null
                    ? []
                    : LocationService.getBarangays(
                        _selectedRegion!, _selectedProvince!, _selectedCity!),
                (val) => setState(() => _selectedBarangay = val)),
            const SizedBox(height: 12),
            TextField(
              controller: _streetController,
              decoration: _inputDecoration("Street Name, House No., Landmark"),
            ),
          ],
        ],
      ),
    );
  }

  // --- SECTION: ORDER SUMMARY ---
  Widget _buildOrderSummarySection() {
    return _buildCardContainer(
      title: "Your Items",
      icon: Icons.shopping_bag_outlined,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.items.length,
        separatorBuilder: (ctx, i) => Divider(color: Colors.grey[200]),
        itemBuilder: (context, index) {
          final item = widget.items[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey[200],
                    image: DecorationImage(
                      image: NetworkImage(item.livestock.imagePath),
                      fit: BoxFit.cover,
                      onError: (e, s) {},
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.livestock.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text("Quantity: ${item.quantity}",
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ),
                Text("₱${item.totalPrice.toStringAsFixed(0)}",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- SECTION: PAYMENT ---
  Widget _buildPaymentSection() {
    return _buildCardContainer(
      title: "Payment Method",
      icon: Icons.payment_outlined,
      child: Column(
        children: [
          _buildPaymentOption("Cash on Delivery",
              "Pay when you receive the item", "COD", Icons.money),
          const SizedBox(height: 10),
          _buildPaymentOption("GCash (E-Wallet)", "Scan QR or Send Money",
              "GCash", Icons.phone_android),
          if (_paymentMethod == "GCash")
            Container(
              margin: const EdgeInsets.only(top: 15),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text(_sellerPhone,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800])),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _gcashRefController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "Enter GCash Reference No.",
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blue.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blue.shade100),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // --- WIDGET HELPER: PAYMENT OPTION CARD ---
  Widget _buildPaymentOption(
      String title, String subtitle, String value, IconData icon) {
    final bool isSelected = _paymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? _accentColor.withOpacity(0.08) : Colors.white,
          border: Border.all(
              color: isSelected ? _accentColor : Colors.grey.shade300,
              width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected ? _primaryColor : Colors.grey, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? _primaryColor : Colors.black87)),
                  Text(subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: _accentColor),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPER: CARD CONTAINER ---
  Widget _buildCardContainer(
      {required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: _primaryColor),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 24),
          child,
        ],
      ),
    );
  }

  // --- WIDGET HELPER: STYLED DROPDOWN ---
  Widget _buildModernDropdown(String hint, String? value, List<String> items,
      Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      decoration: _inputDecoration(hint),
      value: value,
      isExpanded: true,
      items: items
          .map((item) => DropdownMenuItem(
              value: item, child: Text(item, overflow: TextOverflow.ellipsis)))
          .toList(),
      onChanged: onChanged,
    );
  }

  // --- WIDGET HELPER: INPUT DECORATION ---
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
      filled: true,
      fillColor: Colors.grey[100],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _accentColor, width: 1.5),
      ),
    );
  }

  // --- BOTTOM BAR ---
  Widget _buildBottomSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, -5))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Subtotal", style: TextStyle(color: Colors.grey)),
              Text("₱${subtotal.toStringAsFixed(0)}",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Shipping Fee", style: TextStyle(color: Colors.grey)),
              Text("₱${_shippingFee.toStringAsFixed(0)}",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Payment",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text("₱${total.toStringAsFixed(0)}",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _placeOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF52B788),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text("Place Order",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
