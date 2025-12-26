import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cart_manager.dart';
import '../services/order_manager.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> items;

  const CheckoutScreen(
      {super.key, required this.items, required double totalAmount});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _addressController = TextEditingController();

  String _paymentMethod = 'COD'; // Default
  bool _isPickUp = false;
  double _shippingFee = 0.0;
  String _shippingLabel = "Enter address to calculate";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Recalculate shipping whenever address changes
    _addressController.addListener(_calculateShipping);
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _calculateShipping() {
    // 1. If Pickup is ON, Fee is 0
    if (_isPickUp) {
      if (mounted) {
        setState(() {
          _shippingFee = 0.0;
          _shippingLabel = "Customer Pickup (Free)";
        });
      }
      return;
    }

    String buyerAddress = _addressController.text.toLowerCase().trim();
    if (buyerAddress.isEmpty) {
      if (mounted) {
        setState(() {
          _shippingFee = 0.0;
          _shippingLabel = "Enter address";
        });
      }
      return;
    }

    double totalShipping = 0.0;
    bool isLongDistance = false;

    // 2. Loop through items to calculate fee
    for (var item in widget.items) {
      double baseFee = item.livestock.shippingFee;
      String sellerLoc = item.livestock.location.toLowerCase().trim();

      // LOGIC: Check if cities match
      bool isSameCity =
          buyerAddress.contains(sellerLoc) || sellerLoc.contains(buyerAddress);

      if (isSameCity) {
        // SAME CITY
        totalShipping += baseFee;
      } else {
        // DIFFERENT CITY (Add Surcharge)
        totalShipping += (baseFee + 500.0);
        isLongDistance = true;
      }
    }

    // 3. Update UI
    String label = isLongDistance
        ? "Includes Distance Surcharge (+₱500)"
        : "Standard Delivery";

    if (mounted) {
      setState(() {
        _shippingFee = totalShipping;
        _shippingLabel = label;
      });
    }
  }

  double get subtotal {
    return widget.items.fold(0, (sum, item) => sum + item.totalPrice);
  }

  double get total => subtotal + _shippingFee;

  Future<void> _placeOrder() async {
    if (!_isPickUp && _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a delivery address")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await OrderManager().placeOrder(
      items: widget.items,
      totalAmount: total,
      deliveryAddress: _addressController.text.trim(),
      paymentMethod: _paymentMethod,
      isPickup: _isPickUp, // Pass the toggle state
      context: context,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      // Clear Cart
      context.read<CartManager>().clearCart();

      // Show Success & Go Home
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
          content: const Text(
            "Order Placed Successfully!\nWait for seller confirmation.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // Close Dialog
                Navigator.of(context)
                    .popUntil((route) => route.isFirst); // Go to Home
              },
              child: const Text("OK"),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color brandGreen = Color(0xFF52B788);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      appBar: AppBar(
        title: const Text("Checkout",
            style: TextStyle(
                color: Color(0xFF1B4332), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1B4332)),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -4))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total Payment:",
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
                Text("₱${total.toStringAsFixed(0)}",
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: brandGreen)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandGreen,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Place Order",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. DELIVERY ADDRESS
            const Text("Delivery Address",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _addressController,
              enabled: !_isPickUp, // Disable if picking up
              decoration: InputDecoration(
                hintText: _isPickUp
                    ? "Not required for pickup"
                    : "Enter complete address (City, Barangay)",
                filled: true,
                fillColor: _isPickUp ? Colors.grey[200] : Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.location_on, color: Colors.grey),
              ),
            ),

            // 2. PICKUP TOGGLE
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeColor: brandGreen,
              title: const Text("I will pick up the item",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Meet seller at their farm (Free Shipping)"),
              value: _isPickUp,
              onChanged: (val) {
                setState(() {
                  _isPickUp = val;
                  _calculateShipping();
                });
              },
            ),
            const Divider(),

            // 3. ORDER SUMMARY
            const SizedBox(height: 10),
            const Text("Order Summary",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(item.livestock.imagePath),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  title: Text(item.livestock.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      "${item.quantity} x ₱${item.livestock.price.toStringAsFixed(0)}"),
                  trailing: Text("₱${item.totalPrice.toStringAsFixed(0)}"),
                );
              },
            ),

            const Divider(),

            // 4. PAYMENT METHOD
            const Text("Payment Method",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: RadioListTile(
                    title: const Text("Cash"),
                    value: "Cash",
                    groupValue: _paymentMethod,
                    activeColor: brandGreen,
                    onChanged: (val) =>
                        setState(() => _paymentMethod = val.toString()),
                  ),
                ),
                Expanded(
                  child: RadioListTile(
                    title: const Text("GCash"),
                    value: "GCash",
                    groupValue: _paymentMethod,
                    activeColor: brandGreen,
                    onChanged: (val) =>
                        setState(() => _paymentMethod = val.toString()),
                  ),
                ),
              ],
            ),

            const Divider(),

            // 5. BILL BREAKDOWN
            _buildSummaryRow("Subtotal", "₱${subtotal.toStringAsFixed(0)}"),
            const SizedBox(height: 8),
            _buildSummaryRow(
                "Shipping Fee", "₱${_shippingFee.toStringAsFixed(0)}",
                isHighlighted: true),
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text(_shippingLabel,
                  style: TextStyle(
                      fontSize: 12,
                      color: _shippingFee > 0 ? Colors.orange[800] : brandGreen,
                      fontStyle: FontStyle.italic)),
            ),
            const Divider(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 14,
                color: isHighlighted ? Colors.black : Colors.grey[700])),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight:
                    isHighlighted ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }
}
