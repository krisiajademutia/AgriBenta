import 'package:agribenta/services/notification_manager.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class SellerOrdersScreen extends StatelessWidget {
  final int initialIndex;

  const SellerOrdersScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    const Color brandGreen = Color(0xFF52B788);

    return DefaultTabController(
      length: 3,
      initialIndex: initialIndex,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F6F0),
        appBar: AppBar(
          title: const Text("My Sales",
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
              Tab(text: "New Requests"),
              Tab(text: "To Deliver"),
              Tab(text: "Sold"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OrdersList(status: 'pending'),
            _OrdersList(status: 'confirmed'),
            _OrdersList(status: 'completed'),
          ],
        ),
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  final String status;

  const _OrdersList({required this.status});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Please login"));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('sellerId', isEqualTo: user.uid)
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data!.docs;

        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 60, color: Colors.grey[300]),
                const SizedBox(height: 10),
                Text(
                  status == 'pending'
                      ? "No new orders yet"
                      : status == 'confirmed'
                          ? "No orders to deliver"
                          : "No completed sales yet",
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return _OrderCard(order: order, status: status);
          },
        );
      },
    );
  }
}

class _OrderCard extends StatefulWidget {
  final DocumentSnapshot order;
  final String status;

  const _OrderCard({required this.order, required this.status});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  // To store fetched buyer name if needed
  String? _fetchedBuyerName;

  @override
  void initState() {
    super.initState();
    // If buyer name is missing/unknown, try to fetch it
    final data = widget.order.data() as Map<String, dynamic>;
    final currentName = data['buyerName'];
    if (currentName == null ||
        currentName == 'Unknown Buyer' ||
        currentName == 'AgriBenta User') {
      _fetchRealBuyerName(data['buyerId']);
    }
  }

  Future<void> _fetchRealBuyerName(String? buyerId) async {
    if (buyerId == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(buyerId)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _fetchedBuyerName = doc.data()?['name'];
        });
      }
    } catch (e) {
      debugPrint("Error fetching buyer name: $e");
    }
  }

  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final orderRef =
          FirebaseFirestore.instance.collection('orders').doc(widget.order.id);
      final data = widget.order.data() as Map<String, dynamic>;

      // 1. Update Order Status
      batch.update(orderRef, {'status': newStatus});

      // 2. If Sold, update Livestock status
      if (newStatus == 'completed') {
        final List<dynamic> items = data['items'] ?? [];
        for (var item in items) {
          final String? livestockId = item['livestockId'];
          if (livestockId != null) {
            final livestockRef = FirebaseFirestore.instance
                .collection('livestock')
                .doc(livestockId);
            batch.update(livestockRef, {'status': 'sold'});
          }
        }
      }

      await batch.commit();

      // 3. Send Notification
      final String buyerId = data['buyerId'];
      String title = "Order Update";
      String body = "Your order status has changed.";

      if (newStatus == 'confirmed') {
        title = "Order Accepted! ✅";
        body = "The seller has accepted your order. It is being prepared.";
      } else if (newStatus == 'cancelled') {
        title = "Order Declined ❌";
        body = "Unfortunately, the seller cannot fulfill this order.";
      } else if (newStatus == 'completed') {
        title = "Order Completed 🎉";
        body = "Thank you for your purchase! The order is complete.";
      }

      await NotificationManager.sendNotification(
        receiverId: buyerId,
        title: title,
        body: body,
        type: 'order_update',
        referenceId: widget.order.id,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Order marked as $newStatus"),
            backgroundColor: const Color(0xFF52B788),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating order: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.order.data() as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;
    final total = data['totalAmount'] ?? 0.0;

    // Priority: Fetched Name -> Stored Name -> Default
    final buyerName = _fetchedBuyerName ?? data['buyerName'] ?? 'Unknown Buyer';

    final address = data['deliveryAddress'] ?? 'No Address';
    final timestamp = (data['createdAt'] as Timestamp?)?.toDate();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Order #${widget.order.id.substring(0, 6).toUpperCase()}",
                    style: TextStyle(
                        color: Colors.grey[600], fontWeight: FontWeight.bold)),
                if (timestamp != null)
                  Text(DateFormat('MMM d, h:mm a').format(timestamp),
                      style: TextStyle(fontSize: 12, color: Colors.grey[400])),
              ],
            ),
          ),
          const Divider(height: 1),

          // Items
          ...items.map((item) {
            // FIX: Check for empty string images
            final String? imageUrl = item['image'];
            final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;

            return ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: hasImage
                    ? Image.network(
                        imageUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image, size: 20));
                        },
                      )
                    : Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported, size: 20)),
              ),
              title: Text(item['name'] ?? 'Item',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Qty: ${item['quantity']}"),
              trailing: Text("₱${item['price']}",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            );
          }),

          const Divider(height: 1),

          // Buyer Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_outline,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(buyerName,
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(address,
                            style: TextStyle(color: Colors.grey[600]))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total Earnings",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("₱${total.toStringAsFixed(2)}",
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF52B788))),
                  ],
                ),
              ],
            ),
          ),

          // Buttons
          if (widget.status == 'pending')
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateStatus(context, 'cancelled'),
                      style:
                          OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text("Reject"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateStatus(context, 'confirmed'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF52B788)),
                      child: const Text("Accept Order",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),

          if (widget.status == 'confirmed')
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _updateStatus(context, 'completed'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700]),
                  child: const Text("Mark as Delivered / Picked Up",
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
