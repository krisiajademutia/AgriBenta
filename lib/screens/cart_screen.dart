// lib/screens/cart_screen.dart

import 'package:agribenta/screens/checkout_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cart_manager.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color textDark = Color(0xFF1B4332);
    const Color brandGreen = Color(0xFF52B788);
    const Color bgCream = Color(0xFFF9F6F0);

    return Scaffold(
      backgroundColor: bgCream,
      appBar: AppBar(
        backgroundColor: bgCream,
        elevation: 0,
        centerTitle: true,
        title: const Text("My Cart",
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: textDark)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: textDark),
            onPressed: () => Navigator.pop(context)),
        actions: [
          Consumer<CartManager>(
            builder: (context, cartManager, _) => TextButton(
              onPressed: cartManager
                      .cartItemsStream.isBroadcast // simple check if has items
                  ? () async {
                      await cartManager.clearCart();
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Cart cleared")));
                    }
                  : null,
              child: const Text("Clear",
                  style: TextStyle(color: Colors.redAccent)),
            ),
          ),
        ],
      ),
      body: Consumer<CartManager>(
        builder: (context, cartManager, child) {
          return StreamBuilder<List<CartItem>>(
            stream: cartManager.cartItemsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: brandGreen));
              }

              final cartItems = snapshot.data ?? [];

              if (cartItems.isEmpty) {
                return _buildEmptyState(context);
              }

              final totalPrice = cartItems.fold<double>(
                  0, (sum, item) => sum + item.totalPrice);

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final cartItem = cartItems[index];
                        return Dismissible(
                          key: Key(cartItem.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child:
                                const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (_) =>
                              cartManager.removeFromCart(cartItem.id),
                          child: _buildCartItemCard(
                              context, cartItem, cartManager),
                        );
                      },
                    ),
                  ),

                  // Total & Checkout
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 10)
                        ]),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total",
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: textDark)),
                            Text('₱${totalPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: brandGreen)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // ... inside the Column, find the "Total & Checkout" container ...

                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: cartItems.isEmpty
                                ? null // Disable if empty
                                : () {
                                    // Navigate to Checkout with all cart items
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CheckoutScreen(
                                          items: cartItems,
                                          totalAmount: totalPrice,
                                        ),
                                      ),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: brandGreen,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12))),
                            child: const Text("Proceed to Checkout",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCartItemCard(
      BuildContext context, CartItem cartItem, CartManager cartManager) {
    const Color textDark = Color(0xFF1B4332);
    const Color brandGreen = Color(0xFF52B788);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
          ]),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(cartItem.livestock.imagePath,
                width: 90, height: 90, fit: BoxFit.cover),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cartItem.livestock.name,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textDark),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Text('₱${cartItem.livestock.price.toStringAsFixed(0)} each',
                    style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _quantityButton(
                        Icons.remove,
                        () => cartManager.updateQuantity(
                            cartItem.id, cartItem.quantity - 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('${cartItem.quantity}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    _quantityButton(
                        Icons.add,
                        () => cartManager.updateQuantity(
                            cartItem.id, cartItem.quantity + 1)),
                  ],
                ),
              ],
            ),
          ),
          Text('₱${cartItem.totalPrice.toStringAsFixed(0)}',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: brandGreen)),
        ],
      ),
    );
  }

  Widget _quantityButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 18, color: const Color(0xFF52B788)),
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
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600])),
          const SizedBox(height: 12),
          Text("Explore livestock and add items!",
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
              textAlign: TextAlign.center),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF52B788),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
            child: const Text("Continue Shopping",
                style: TextStyle(fontSize: 16, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
