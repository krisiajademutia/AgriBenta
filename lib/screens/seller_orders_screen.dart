import 'package:agribenta/services/notification_manager.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SellerOrdersScreen extends StatelessWidget {
  const SellerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color brandGreen = Color(0xFF52B788);

    return DefaultTabController(
      length: 3,
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
              Tab(text: "New Requests"), // Pending
              Tab(text: "To Deliver"), // Confirmed
              Tab(text: "Sold"), // Completed
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _SellerOrderList(status: 'pending'),
            _SellerOrderList(status: 'confirmed'),
            _SellerOrderList(status: 'completed'),
          ],
        ),
      ),
    );
  }
}

class _SellerOrderList extends StatelessWidget {
  final String status;
  const _SellerOrderList({required this.status});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('sellerId', isEqualTo: user.uid) // <--- Only show MY sales
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF52B788)));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text("No $status orders",
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
            // Pass the Doc ID to update it later
            return _SellerOrderCard(data: data, orderDocId: doc.id);
          },
        );
      },
    );
  }
}

class _SellerOrderCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String orderDocId;
  const _SellerOrderCard({required this.data, required this.orderDocId});

  // --- UPDATED LOGIC TO UPDATE STATUS & NOTIFY BUYER ---
  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    try {
      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      // 1. Update Order Status
      final orderRef = db.collection('orders').doc(orderDocId);
      batch.update(orderRef, {'status': newStatus});

      // 2. If Completed, Mark Items as SOLD
      if (newStatus == 'completed') {
        final items = (data['items'] as List<dynamic>?) ?? [];
        for (var item in items) {
          final livestockId = item['livestockId'];
          final livestockRef = db.collection('livestock').doc(livestockId);
          batch.update(livestockRef, {'status': 'sold', 'isSold': true});
        }
      }
      // 3. If Cancelled, Return items to ACTIVE
      else if (newStatus == 'cancelled') {
        final items = (data['items'] as List<dynamic>?) ?? [];
        for (var item in items) {
          final livestockId = item['livestockId'];
          final livestockRef = db.collection('livestock').doc(livestockId);
          batch.update(livestockRef, {
            'status': 'active',
            'pendingBuyerId': FieldValue.delete(),
          });
        }
      }

      // 4. COMMIT THE DATABASE CHANGES
      await batch.commit();

      // ---------------------------------------------------------
      // 5. SEND NOTIFICATION TO BUYER (NEW PART!)
      // ---------------------------------------------------------
      final buyerId = data['buyerId'];
      final items = (data['items'] as List<dynamic>?) ?? [];
      final firstItemName = items.isNotEmpty ? items.first['name'] : 'Item';

      if (buyerId != null) {
        String title = '';
        String body = '';

        if (newStatus == 'confirmed') {
          title = 'Order Accepted ✅';
          body =
              'Your order for $firstItemName has been accepted! Please prepare for payment/pickup.';
        } else if (newStatus == 'cancelled') {
          title = 'Order Declined ❌';
          body = 'The seller declined your order for $firstItemName.';
        } else if (newStatus == 'completed') {
          title = 'Order Delivered/Picked Up 📦';
          body =
              'The seller has marked your order for $firstItemName as completed.';
        }

        // Only send if we have a valid status change
        if (title.isNotEmpty) {
          await NotificationManager.sendNotification(
            receiverId: buyerId,
            title: title,
            body: body,
            type: 'order',
          );
        }
      }
      // ---------------------------------------------------------

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Order marked as ${newStatus.toUpperCase()}"),
            backgroundColor: const Color(0xFF52B788),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = (data['items'] as List<dynamic>?) ?? [];
    final firstItem = items.isNotEmpty ? items.first : null;
    final totalAmount = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final status = data['status'] ?? 'pending';
    final isPickup = data['isPickup'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Header
          ListTile(
            title: Text(
                "Order #${data['orderId']?.toString().substring(0, 6) ?? '...'}",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(isPickup ? "📢 CUSTOMER PICKUP" : "🚚 FOR DELIVERY",
                style: TextStyle(
                    color: isPickup ? Colors.orange : Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
            trailing: Text("₱${totalAmount.toStringAsFixed(0)}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1B4332))),
          ),
          const Divider(height: 1),

          // Item Preview
          if (firstItem != null)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(firstItem['imagePath'] ?? '',
                        width: 50, height: 50, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(firstItem['name'],
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                            "${items.length} items • ${data['paymentMethod']}"),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // ADDRESS
          if (!isPickup)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[50],
              child: Text("📍 ${data['deliveryAddress']}",
                  style: TextStyle(color: Colors.grey[700], fontSize: 13)),
            ),

          // ACTION BUTTONS
          if (status == 'pending')
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

          if (status == 'confirmed')
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _updateStatus(context, 'completed'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700]),
                  child: const Text("Mark as Delivered / Picked Up"),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
