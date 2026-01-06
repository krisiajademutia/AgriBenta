import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agribenta/services/notification_manager.dart';
import 'package:intl/intl.dart';

class OrdersTab extends StatelessWidget {
  final int initialIndex;

  const OrdersTab({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    const Color brandGreen = Color(0xFF52B788);

    return DefaultTabController(
      length: 3,
      initialIndex: initialIndex,
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
  final String orderDocId;

  const _BuyerOrderCard({
    super.key,
    required this.data,
    required this.orderDocId,
  });

  Future<void> _markAsReceived(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Receipt"),
        content: const Text(
            "Have you received this item? This will complete the transaction."),
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

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(orderDocId)
            .update({
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
        });

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
    final totalAmount = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final shippingFee = (data['shippingFee'] as num?)?.toDouble() ?? 0.0;
    final status = data['status'] ?? 'pending';

    // Format Date
    final Timestamp? createdAt = data['createdAt'] as Timestamp?;
    final String dateString = createdAt != null
        ? DateFormat('MMM d, yyyy').format(createdAt.toDate())
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER: Order ID & Date ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Order #${orderDocId.substring(0, 6).toUpperCase()}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                Text(
                  dateString,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
            const Divider(height: 24),

            // --- ITEMS LIST ---
            // Display EVERY item in the order with Qty and Weight
            ...items.map((item) {
              final String name = item['name'] ?? 'Unknown Item';
              final String? imagePath = item['imagePath'];
              final String? weight = item['weight'];
              final int qty = item['quantity'] ?? 0;
              final double price = (item['price'] as num?)?.toDouble() ?? 0.0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ITEM IMAGE
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[200],
                        child: (imagePath != null && imagePath.isNotEmpty)
                            ? Image.network(
                                imagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey),
                              )
                            : const Icon(Icons.shopping_bag,
                                color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // DETAILS (Name, Weight, Price)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // WEIGHT / VARIANT INFO
                          if (weight != null && weight.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "Weight: $weight",
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[700]),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // QUANTITY & PRICE
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "x$qty",
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "₱${price.toStringAsFixed(0)}",
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),

            const Divider(height: 24),

            // --- PAYMENT SUMMARY ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Shipping: ₱${shippingFee.toStringAsFixed(0)}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Total Payment",
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800]),
                    ),
                  ],
                ),
                Text(
                  "₱${totalAmount.toStringAsFixed(0)}",
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF52B788)), // Brand Green
                ),
              ],
            ),

            const SizedBox(height: 16),

            // --- ACTION BUTTONS (Status / Received) ---
            Row(
              children: [
                Expanded(
                  child: status == 'confirmed'
                      ? ElevatedButton(
                          onPressed: () => _markAsReceived(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF52B788),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                          child: const Text("Order Received"),
                        )
                      : Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: status == 'completed'
                                ? Colors.green[50]
                                : Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: status == 'completed'
                                    ? Colors.green.withOpacity(0.5)
                                    : Colors.orange.withOpacity(0.5),
                                width: 1),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            status == 'pending'
                                ? "PENDING APPROVAL"
                                : status.toUpperCase(),
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: status == 'completed'
                                    ? Colors.green[700]
                                    : Colors.orange[700]),
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
