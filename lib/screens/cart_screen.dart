import 'package:agribenta/screens/checkout_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cart_manager.dart';
import '../models/cart_model.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isSelectionMode = false;
  final Set<String> _selectedItemIds = {};

  Stream<List<CartItem>>? _cartStream;

  final Color textDark = const Color(0xFF1B4332);
  final Color brandGreen = const Color(0xFF52B788);
  final Color bgCream = const Color(0xFFF9F6F0);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cartStream ??= Provider.of<CartManager>(context, listen: false).cartStream;
  }

  void _enterSelectionMode(String? initialItemId) {
    setState(() {
      _isSelectionMode = true;
      if (initialItemId != null) _selectedItemIds.add(initialItemId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedItemIds.clear();
    });
  }

  void _toggleItem(String itemId) {
    setState(() {
      if (_selectedItemIds.contains(itemId)) {
        _selectedItemIds.remove(itemId);
        if (_selectedItemIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedItemIds.add(itemId);
      }
    });
  }

  Future<void> _deleteSelected(CartManager manager) async {
    for (var id in _selectedItemIds) {
      await manager.removeItem(id);
    }
    _exitSelectionMode();
  }

  @override
  Widget build(BuildContext context) {
    final cartManager = Provider.of<CartManager>(context);

    return WillPopScope(
      onWillPop: () async {
        if (_isSelectionMode) {
          _exitSelectionMode();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: bgCream,
        appBar: AppBar(
          backgroundColor: bgCream,
          elevation: 0,
          leading: _isSelectionMode
              ? IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: _exitSelectionMode)
              : IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                  onPressed: () => Navigator.pop(context)),
          title: Text(
            _isSelectionMode
                ? "${_selectedItemIds.length} Selected"
                : "My Cart",
            style: TextStyle(
                color: textDark, fontWeight: FontWeight.bold, fontSize: 20),
          ),
          centerTitle: true,
          actions: [
            if (_isSelectionMode)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _deleteSelected(cartManager),
              ),
          ],
        ),
        body: StreamBuilder<List<CartItem>>(
          stream: _cartStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                  child: CircularProgressIndicator(color: brandGreen));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState(context);
            }

            final cartItems = snapshot.data!;

            // --- FIX START: Filter items based on selection ---
            List<CartItem> checkoutItems;

            if (_isSelectionMode) {
              checkoutItems = cartItems
                  .where((item) => _selectedItemIds.contains(item.id))
                  .toList();
            } else {
              // If not selecting, include ALL items (Default behavior)
              checkoutItems = cartItems;
            }

            // Calculate Total based on the FILTERED checkout list
            double totalPrice = 0;
            for (var item in checkoutItems) {
              totalPrice += item.selectedPrice * item.quantity;
            }

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: cartItems.length, // List shows ALL items
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return _buildCartItem(item, cartManager);
                    },
                  ),
                ),
                // Pass filtered items and correct total to checkout bar
                _buildCheckoutBar(totalPrice, checkoutItems),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCartItem(CartItem item, CartManager manager) {
    bool isSelected = _selectedItemIds.contains(item.id);

    return GestureDetector(
      onLongPress: () => _enterSelectionMode(item.id),
      onTap: () {
        if (_isSelectionMode) _toggleItem(item.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? brandGreen.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: brandGreen, width: 2) : null,
          boxShadow: [
            BoxShadow(
                color: textDark.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            // Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[200],
                image: item.livestock.imagePath.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(item.livestock.imagePath),
                        fit: BoxFit.cover)
                    : null,
              ),
              child: item.livestock.imagePath.isEmpty
                  ? const Icon(Icons.image_not_supported)
                  : null,
            ),
            const SizedBox(width: 16),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.livestock.name,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textDark)),
                  if (item.selectedWeight.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text("Weight: ${item.selectedWeight}",
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600])),
                    ),
                  const SizedBox(height: 8),
                  Text("₱${item.selectedPrice.toStringAsFixed(0)}",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: brandGreen)),
                ],
              ),
            ),

            // Quantity Controls
            Column(
              children: [
                _quantityButton(Icons.remove, () {
                  if (item.quantity > 1) {
                    manager.updateQuantity(item.id, item.quantity - 1);
                  } else {
                    manager.removeItem(item.id);
                  }
                }),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    "${item.quantity}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                _quantityButton(Icons.add, () {
                  manager.updateQuantity(item.id, item.quantity + 1);
                }),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _quantityButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: brandGreen),
      ),
    );
  }

  Widget _buildCheckoutBar(double total, List<CartItem> items) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5))
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Total Price",
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text("₱${total.toStringAsFixed(0)}",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textDark)),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                if (items.isEmpty) return;

                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            CheckoutScreen(items: items, totalAmount: total)));
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: brandGreen,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16))),
              child: const Text("Checkout",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 100, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text("Your cart is empty",
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: textDark)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Start Shopping",
                style: TextStyle(fontSize: 16, color: brandGreen)),
          )
        ],
      ),
    );
  }
}
