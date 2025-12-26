import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class OrdersTab extends StatelessWidget {
  const OrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    const Color brandGreen = Color(0xFF52B788);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F6F0),
        appBar: AppBar(
          title: const Text("My Purchases",
              style: TextStyle(
                  color: Color(0xFF1B4332), fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Color(0xFF1B4332)),
          bottom: const TabBar(
            labelColor: brandGreen,
            unselectedLabelColor: Colors.grey,
            indicatorColor: brandGreen,
            indicatorWeight: 3,
            tabs: [
              Tab(text: "Pending"),
              Tab(text: "To Receive"),
              Tab(text: "Completed"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _BuyerOrderList(status: 'pending'),
            _BuyerOrderList(status: 'confirmed'),
            _BuyerOrderList(status: 'completed'),
          ],
        ),
      ),
    );
  }
}

class _BuyerOrderList extends StatelessWidget {
  final String status;
  const _BuyerOrderList({required this.status});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("Please log in to view orders"));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('buyerId', isEqualTo: user.uid) // <--- Filter by BUYER
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        // 1. Handle Index Error (The Glitch Fix)
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.orange, size: 40),
                  const SizedBox(height: 10),
                  const Text("First time setup required!",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  SelectableText(
                    "Error: ${snapshot.error}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                      "Check your debug console for the blue link to create the index.",
                      textAlign: TextAlign.center)
                ],
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF52B788)));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag_outlined,
                    size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text("No $status orders found",
                    style: TextStyle(color: Colors.grey[500], fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _BuyerOrderCard(data: data);
          },
        );
      },
    );
  }
}

class _BuyerOrderCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _BuyerOrderCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final items = (data['items'] as List<dynamic>?) ?? [];
    final firstItem = items.isNotEmpty ? items.first : null;
    final totalAmount = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final shippingFee = (data['shippingFee'] as num?)?.toDouble() ?? 0.0;
    final isPickup = data['isPickup'] ?? false;
    final date = (data['createdAt'] as Timestamp?)?.toDate();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          // Header: Order ID & Date
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Order #${data['orderId']?.toString().substring(0, 8) ?? '...'}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    if (date != null)
                      Text(
                        DateFormat('MMM d, yyyy • h:mm a').format(date),
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                  ],
                ),
                // Pickup Badge
                if (isPickup)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.orange.withOpacity(0.5)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.storefront, size: 12, color: Colors.orange),
                        SizedBox(width: 4),
                        Text("PICKUP",
                            style: TextStyle(
                                color: Colors.orange,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Body: Item Preview
          if (firstItem != null)
            ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  firstItem['imagePath'] ?? '',
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[200],
                      width: 60,
                      height: 60,
                      child: const Icon(Icons.broken_image,
                          size: 20, color: Colors.grey)),
                ),
              ),
              title: Text(firstItem['name'] ?? 'Unknown Item',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(items.length > 1
                  ? "+ ${items.length - 1} other items"
                  : "Quantity: ${firstItem['quantity']}"),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Total",
                      style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                  Text(
                    "₱${totalAmount.toStringAsFixed(0)}",
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B4332)),
                  ),
                ],
              ),
            ),

          // Footer: Shipping & Payment
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    isPickup
                        ? "Shipping: FREE (Pickup)"
                        : "Shipping: ₱${shippingFee.toStringAsFixed(0)}",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                Text("Pay via ${data['paymentMethod'] ?? 'COD'}",
                    style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
