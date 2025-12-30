import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agribenta/services/notification_manager.dart';
import 'package:intl/intl.dart';

// In lib/screens/orders_tab.dart

class OrdersTab extends StatelessWidget {
  final int initialIndex; // 1. Add this field

  // 2. Add it to the constructor (default to 0)
  const OrdersTab({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    const Color brandGreen = Color(0xFF52B788);

    return DefaultTabController(
      length: 3,
      initialIndex: initialIndex, // 3. Pass the index here
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
              Tab(text: "Pending"), // Index 0
              Tab(text: "To Receive"), // Index 1
              Tab(text: "Completed"), // Index 2
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
          .where('buyerId', isEqualTo: user.uid)
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
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

            // WE PASS THE DOC ID HERE so we can update it later
            return _BuyerOrderCard(
              data: data,
              orderDocId: doc.id,
            );
          },
        );
      },
    );
  }
}

class _BuyerOrderCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String orderDocId; // <--- ADDED THIS

  const _BuyerOrderCard({
    required this.data,
    required this.orderDocId,
  });

  // --- FUNCTION TO MARK ORDER AS RECEIVED ---
// --- FUNCTION TO MARK ORDER AS RECEIVED (UPDATED) ---
  Future<void> _markAsReceived(BuildContext context) async {
    // 1. Ask for confirmation
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Receipt"),
        content: const Text(
            "Have you received this item? This will complete the transaction and release payment to the seller."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF52B788),
              foregroundColor: Colors.white,
            ),
            child: const Text("Yes, Received"),
          ),
        ],
      ),
    );

    // 2. Update Firestore & Notify Seller
    if (confirm == true) {
      try {
        // A. Update the Order Status
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(orderDocId)
            .update({
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
        });

        // B. SEND NOTIFICATION TO SELLER (New!)
        final sellerId = data['sellerId'];
        if (sellerId != null) {
          await NotificationManager.sendNotification(
            receiverId: sellerId,
            title: "Order Completed! 🎉",
            body:
                "Buyer has received Order #${orderDocId.substring(0, 6)}. Transaction is now complete.",
            type: "order",
          );
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Transaction Completed! 🎉"),
              backgroundColor: Color(0xFF52B788),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = (data['items'] as List<dynamic>?) ?? [];
    final firstItem = items.isNotEmpty ? items.first : null;
    final totalAmount = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final shippingFee = (data['shippingFee'] as num?)?.toDouble() ?? 0.0;
    final isPickup = data['isPickup'] ?? false;
    final date = (data['createdAt'] as Timestamp?)?.toDate();
    final status = data['status'] ?? 'pending'; // Get the status

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

          // Footer: Shipping, Payment, AND ACTION BUTTON
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        isPickup
                            ? "Shipping: FREE (Pickup)"
                            : "Shipping: ₱${shippingFee.toStringAsFixed(0)}",
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 12)),
                    Text("Pay via ${data['paymentMethod'] ?? 'COD'}",
                        style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),

                // --- THE NEW BUTTON ---
                if (status == 'confirmed') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _markAsReceived(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF52B788),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Order Received"),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}
