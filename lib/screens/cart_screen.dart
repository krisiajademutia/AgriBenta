import 'package:agribenta/screens/checkout_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cart_manager.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // State variables
  bool _isSelectionMode = false;
  final Set<String> _selectedItemIds = {};

  // Theme Colors
  final Color textDark = const Color(0xFF1B4332);
  final Color brandGreen = const Color(0xFF52B788);
  final Color bgCream = const Color(0xFFF9F6F0);

  // --- ACTIONS ---

  // Enter selection mode
  void _enterSelectionMode(String? initialItemId) {
    setState(() {
      _isSelectionMode = true;
      if (initialItemId != null) {
        _selectedItemIds.add(initialItemId);
      }
    });
  }

  // Exit selection mode
  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedItemIds.clear();
    });
  }

  // Toggle individual item
  void _toggleItem(String itemId) {
    setState(() {
      if (_selectedItemIds.contains(itemId)) {
        _selectedItemIds.remove(itemId);
        // Optional: Exit mode if last item deselected
        if (_selectedItemIds.isEmpty) {
          // _isSelectionMode = false; // Uncomment if you want auto-exit
        }
      } else {
        _selectedItemIds.add(itemId);
      }
    });
  }

  // Bulk Remove Action
  Future<void> _deleteSelected(CartManager cartManager) async {
    if (_selectedItemIds.isEmpty) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Remove Items?"),
        content:
            Text("Remove ${_selectedItemIds.length} items from your cart?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Remove", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      for (var id in _selectedItemIds) {
        await cartManager.removeFromCart(id);
      }
      _exitSelectionMode();

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Items removed")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartManager>(
      builder: (context, cartManager, child) {
        return StreamBuilder<List<CartItem>>(
          stream: cartManager.cartStream,
          builder: (context, snapshot) {
            // 1. Handle Loading & Empty States
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                  backgroundColor: bgCream,
                  body: Center(
                      child: CircularProgressIndicator(color: brandGreen)));
            }
            final cartItems = snapshot.data ?? [];
            if (cartItems.isEmpty) return _buildEmptyState(context);

            // 2. Calculate Totals
            // A. Selection Mode Total
            final selectedItemsList = cartItems
                .where((item) => _selectedItemIds.contains(item.id))
                .toList();
            final totalSelectedPrice = selectedItemsList.fold<double>(
                0, (sum, item) => sum + item.totalPrice);

            // B. Normal Mode Total (All Items)
            final totalAllPrice =
                cartItems.fold<double>(0, (sum, item) => sum + item.totalPrice);

            return WillPopScope(
              // Pressing back while in selection mode should just exit mode
              onWillPop: () async {
                if (_isSelectionMode) {
                  _exitSelectionMode();
                  return false;
                }
                return true;
              },
              child: Scaffold(
                backgroundColor: bgCream,

                // --- APP BAR ---
                appBar: AppBar(
                  backgroundColor: bgCream,
                  elevation: 0,
                  centerTitle: true,
                  leading: _isSelectionMode
                      ? IconButton(
                          icon: const Icon(Icons.close, color: Colors.black),
                          onPressed: _exitSelectionMode,
                        )
                      : IconButton(
                          icon: Icon(Icons.arrow_back_ios, color: textDark),
                          onPressed: () => Navigator.pop(context),
                        ),
                  title: Text(
                    _isSelectionMode
                        ? "${_selectedItemIds.length} Selected"
                        : "My Cart",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textDark),
                  ),
                  actions: [
                    if (!_isSelectionMode)
                      TextButton(
                        onPressed: () => _enterSelectionMode(null),
                        child: Text("Select",
                            style: TextStyle(
                                color: brandGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ),
                  ],
                ),

                // --- BODY ---
                body: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          final cartItem = cartItems[index];
                          final isSelected =
                              _selectedItemIds.contains(cartItem.id);

                          return _buildCartItem(
                            cartItem: cartItem,
                            cartManager: cartManager,
                            isSelected: isSelected,
                            isSelectionMode: _isSelectionMode,
                          );
                        },
                      ),
                    ),

                    // --- BOTTOM ACTION BAR ---
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                offset: Offset(0, -5))
                          ]),
                      child: SafeArea(
                        child: _isSelectionMode
                            ? _buildSelectionModeBottomBar(
                                cartManager, selectedItemsList)
                            : _buildNormalModeBottomBar(
                                cartItems, totalAllPrice),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- WIDGETS ---

  // 1. The Cart Item Card
  Widget _buildCartItem({
    required CartItem cartItem,
    required CartManager cartManager,
    required bool isSelected,
    required bool isSelectionMode,
  }) {
    return GestureDetector(
      // Logic:
      // - Normal Mode: Long press -> Enter Selection Mode
      // - Selection Mode: Tap -> Toggle Selection
      onLongPress: () {
        if (!isSelectionMode) {
          _enterSelectionMode(cartItem.id);
        }
      },
      onTap: () {
        if (isSelectionMode) {
          _toggleItem(cartItem.id);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: isSelected ? brandGreen.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isSelected ? brandGreen : Colors.transparent,
                width: 1.5),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
            ]),
        child: Row(
          children: [
            // Checkbox (Only visible in Selection Mode)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelectionMode ? 32 : 0,
              curve: Curves.easeInOut,
              child: isSelectionMode
                  ? Checkbox(
                      value: isSelected,
                      activeColor: brandGreen,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                      onChanged: (val) => _toggleItem(cartItem.id),
                    )
                  : null,
            ),

            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(cartItem.livestock.imagePath,
                  width: 80, height: 80, fit: BoxFit.cover),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cartItem.livestock.name,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text('₱${cartItem.livestock.price.toStringAsFixed(0)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  const SizedBox(height: 8),

                  // Qty Controls (Disable in selection mode to prevent conflicts)
                  IgnorePointer(
                    ignoring: isSelectionMode,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          _quantityButton(Icons.remove, () {
                            if (cartItem.quantity > 1)
                              cartManager.updateQuantity(
                                  cartItem.id, cartItem.quantity - 1);
                          }),
                          Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('${cartItem.quantity}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold))),
                          _quantityButton(
                              Icons.add,
                              () => cartManager.updateQuantity(
                                  cartItem.id, cartItem.quantity + 1)),
                        ]),
                        Text('₱${cartItem.totalPrice.toStringAsFixed(0)}',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: brandGreen)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. Bottom Bar: Normal Mode (Checkout All)
  Widget _buildNormalModeBottomBar(List<CartItem> allItems, double total) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Total",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('₱${total.toStringAsFixed(0)}',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: brandGreen)),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CheckoutScreen(
                    items: allItems,
                    totalAmount: total,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: brandGreen,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text("Check Out All",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ),
        ),
      ],
    );
  }

  // 3. Bottom Bar: Selection Mode (Remove OR Checkout Selected)
  Widget _buildSelectionModeBottomBar(
      CartManager cartManager, List<CartItem> selectedItems) {
    final hasSelection = selectedItems.isNotEmpty;
    final totalSelected =
        selectedItems.fold<double>(0, (sum, item) => sum + item.totalPrice);

    return Row(
      children: [
        // Remove Button
        Expanded(
          flex: 1,
          child: SizedBox(
            height: 55,
            child: OutlinedButton(
              onPressed:
                  hasSelection ? () => _deleteSelected(cartManager) : null,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline, color: Colors.redAccent),
                  Text("Remove",
                      style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Checkout Selected Button
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 55,
            child: ElevatedButton(
              onPressed: hasSelection
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CheckoutScreen(
                            items: selectedItems,
                            totalAmount: totalSelected,
                          ),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: brandGreen,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Check Out (${selectedItems.length})",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
                  if (hasSelection)
                    Text("₱${totalSelected.toStringAsFixed(0)}",
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
          ),
        ),
      ],
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

  Widget _buildEmptyState(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      appBar: AppBar(
          backgroundColor: bgCream,
          elevation: 0,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
              onPressed: () => Navigator.pop(context))),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined,
                size: 100, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text("Your cart is empty",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
