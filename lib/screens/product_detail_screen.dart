// lib/screens/product_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:agribenta/models/popular_model.dart';
import 'package:agribenta/screens/cart_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  final PopularModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2C2218), Color(0xFF2E4F2A), Color(0xFFE9D7C4)],
          ),
        ),
        child: Column(
          children: [
            // Image + Back button
            Stack(
              children: [
                Image.asset(product.imagePath, height: 400, width: double.infinity, fit: BoxFit.cover),
                Positioned(
                  top: 40,
                  left: 16,
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFE9D7C4),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(children: [const Icon(Icons.location_on), Text(product.location)]),
                    const SizedBox(height: 20),
                    Text("Rp ${product.price.toStringAsFixed(0)}", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF2E4F2A))),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E4F2A)),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
                        },
                        child: const Text("Add to Cart", style: TextStyle(fontSize: 20, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}