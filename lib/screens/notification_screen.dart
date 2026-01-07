import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/notification_manager.dart';
import 'seller_orders_screen.dart';
import 'package:agribenta/screens/tabs/orders_tab.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // State variables
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  late Stream<QuerySnapshot> _notificationsStream;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _notificationsStream = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots();
    } else {
      _notificationsStream = const Stream.empty();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // --- ACTIONS ---

  void _enterSelectionMode(String initialId) {
    setState(() {
      _isSelectionMode = true;
      _selectedIds.add(initialId);
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  Future<void> _deleteSelected(String userId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Notifications?"),
        content: Text(
            "Are you sure you want to delete ${_selectedIds.length} notification(s)?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      final batch = FirebaseFirestore.instance.batch();
      final collection = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications');

      for (var id in _selectedIds) {
        batch.delete(collection.doc(id));
      }

      await batch.commit();
      _exitSelectionMode();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Notifications deleted")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Please login")));
    }

    return WillPopScope(
      onWillPop: () async {
        if (_isSelectionMode) {
          _exitSelectionMode();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F6F0),
        appBar: _isSelectionMode
            ? _buildSelectionAppBar(user.uid)
            : _buildNormalAppBar(user.uid, context),
        body: StreamBuilder<QuerySnapshot>(
          stream: _notificationsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF52B788)));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState();
            }

            final docs = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['type'] != 'message';
            }).toList();

            if (docs.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: docs.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final doc = docs[index];
                return KeyedSubtree(
                  key: ValueKey(doc.id),
                  child: _buildNotificationItem(doc, context),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // --- APP BARS ---

  PreferredSizeWidget _buildNormalAppBar(String userId, BuildContext context) {
    return AppBar(
      title: const Text(
        "Notifications",
        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B4332)),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: Color(0xFF1B4332)),
      actions: [
        IconButton(
          icon: const Icon(Icons.done_all, color: Color(0xFF52B788)),
          tooltip: "Mark all as read",
          onPressed: () {
            NotificationManager.markAllAsRead(userId);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text("All marked as read"),
                  backgroundColor: Color(0xFF52B788)),
            );
          },
        )
      ],
    );
  }

  PreferredSizeWidget _buildSelectionAppBar(String userId) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.black),
        onPressed: _exitSelectionMode,
      ),
      title: Text(
        "${_selectedIds.length} Selected",
        style: const TextStyle(
            color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
      ),
      actions: [
        if (_selectedIds.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _deleteSelected(userId),
          ),
      ],
    );
  }

  // --- ITEMS & WIDGETS ---

  Widget _buildNotificationItem(DocumentSnapshot doc, BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final bool isRead = data['isRead'] ?? false;
    final String type = data['type'] ?? 'system';
    final Timestamp? timestamp = data['createdAt'];
    final DateTime? date = timestamp?.toDate();

    final isSelected = _selectedIds.contains(doc.id);

    return Material(
      elevation: isRead ? 0 : 2,
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onLongPress: () {
          if (!_isSelectionMode) {
            _enterSelectionMode(doc.id);
          }
        },
        onTap: () {
          if (_isSelectionMode) {
            _toggleSelection(doc.id);
          } else {
            _handleNotificationTap(context, doc, data);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF52B788).withOpacity(0.15)
                : (isRead ? Colors.white : Colors.green.shade50),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF52B788)
                  : (isRead
                      ? Colors.transparent
                      : const Color(0xFF52B788).withOpacity(0.5)),
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 12.0, top: 8.0),
                  child: Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isSelected ? const Color(0xFF52B788) : Colors.grey,
                    size: 22,
                  ),
                ),
              _buildIcon(type, isRead),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title'] ?? 'Notification',
                      style: TextStyle(
                        fontWeight:
                            isRead ? FontWeight.normal : FontWeight.bold,
                        fontSize: 16,
                        color: const Color(0xFF1B4332),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['body'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                    if (date != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _formatTime(date),
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                      ),
                  ],
                ),
              ),
              if (!isRead && !_isSelectionMode)
                const Padding(
                  padding: EdgeInsets.only(left: 8.0, top: 5),
                  child: CircleAvatar(
                      radius: 4, backgroundColor: Color(0xFF52B788)),
                )
            ],
          ),
        ),
      ),
    );
  }

  void _handleNotificationTap(
      BuildContext context, DocumentSnapshot doc, Map<String, dynamic> data) {
    if (data['isRead'] == false) {
      doc.reference.update({'isRead': true});
    }

    final String type = data['type'];
    final String title = (data['title'] ?? '').toLowerCase();
    final String body = (data['body'] ?? '').toLowerCase();

    // --- FIX IS HERE: Accept 'order' OR 'order_update' ---
    if (type == 'order' || type == 'order_update') {
      bool isBuyerNotification = title.contains('your order') ||
          title.contains('purchase') ||
          title.contains('accepted') ||
          title.contains('confirmed') ||
          title.contains('declined') ||
          body.contains('successfully delivered') ||
          (title.contains('complete') && !body.contains('buyer'));

      if (isBuyerNotification) {
        int tabIndex = 0;
        if (title.contains('accepted') ||
            title.contains('confirmed') ||
            title.contains('shipped') ||
            title.contains('delivery')) {
          tabIndex = 1;
        } else if (title.contains('completed') ||
            title.contains('received') ||
            title.contains('delivered')) {
          tabIndex = 2;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrdersTab(initialIndex: tabIndex),
          ),
        );
      } else {
        // Seller Notification
        int tabIndex = 0;
        if (title.contains('delivery') || title.contains('pickup')) {
          tabIndex = 1;
        } else if (title.contains('completed') || title.contains('sold')) {
          tabIndex = 2;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SellerOrdersScreen(initialIndex: tabIndex),
          ),
        );
      }
    }
  }

  Widget _buildIcon(String type, bool isRead) {
    IconData icon;
    Color color;

    switch (type) {
      case 'order':
      case 'order_update': // --- FIX IS HERE: Add this case
        icon = Icons.local_shipping_outlined;
        color = Colors.orange;
        break;
      case 'system':
      default:
        icon = Icons.notifications_none;
        color = const Color(0xFF52B788);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isRead ? Colors.grey[100] : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Icon(icon, color: isRead ? Colors.grey : color, size: 24),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("No notifications yet",
              style: TextStyle(color: Colors.grey[500], fontSize: 16)),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return DateFormat('MMM d, h:mm a').format(date);
  }
}
