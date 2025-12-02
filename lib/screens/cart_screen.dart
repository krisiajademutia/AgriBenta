// lib/screens/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:agribenta/models/cart_model.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<CartItem> cartItems = [
    CartItem(id: "1", name: "Sapi Limousin", price: 85000000, imagePath: "assets/popular/sapi_limousin.jpg"),
    CartItem(id: "2", name: "Ayam KUB", price: 450000, imagePath: "assets/popular/ayam_kub.jpg"),
  ];

  double get totalPrice => cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));

  void _updateQuantity(int index, int change) {
    setState(() {
      cartItems[index].quantity = (cartItems[index].quantity + change).clamp(1, 99);
    });
  }

  void _removeItem(int index) {
    setState(() {
      cartItems.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E4F2A),
        title: const Text("My Cart", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: cartItems.isEmpty
          ? const Center(child: Text("Cart is empty", style: TextStyle(fontSize: 24, color: Colors.white70)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return Card(
                  color: Colors.white.withOpacity(0.18),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(item.imagePath, width: 90, height: 90, fit: BoxFit.cover),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              Text("Rp ${item.price.toStringAsFixed(0)}", style: const TextStyle(color: Colors.white, fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(onPressed: () => _updateQuantity(index, -1), icon: const Icon(Icons.remove_circle_outline, color: Colors.white)),
                          Text("${item.quantity}", style: const TextStyle(color: Colors.white, fontSize: 18)),
                          IconButton(onPressed: () => _updateQuantity(index, 1), icon: const Icon(Icons.add_circle_outline, color: Colors.white)),
                        ],
                      ),
                      IconButton(onPressed: () => _removeItem(index), icon: const Icon(Icons.delete, color: Colors.red)),
                    ],
                  ),
                );
              },
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        color: const Color(0xFF2E4F2A).withOpacity(0.95),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Total:", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            Text("Rp ${totalPrice.toStringAsFixed(0)}", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}