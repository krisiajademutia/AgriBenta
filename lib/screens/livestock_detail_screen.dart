import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/livestock_model.dart';
import '../../models/user_model.dart';
import '../../services/cart_manager.dart';
import '../../models/cart_model.dart';
import 'checkout_screen.dart';
import 'chat_screen.dart';
import 'seller_store_screen.dart';

class LivestockDetailScreen extends StatefulWidget {
  final Livestock livestock;

  const LivestockDetailScreen({super.key, required this.livestock});

  @override
  State<LivestockDetailScreen> createState() => _LivestockDetailScreenState();
}

class _LivestockDetailScreenState extends State<LivestockDetailScreen> {
  int _currentImageIndex = 0;
  bool _isFavorite = false;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  UserModel? _seller;
  bool _isLoadingSeller = true;

  // --- VARIANT STATE ---
  LivestockVariant? _selectedVariant;

  bool get isOwnListing => currentUser?.uid == widget.livestock.sellerId;

  @override
  void initState() {
    super.initState();
    _fetchSellerInfo();
    _checkFavoriteStatus();

    // Auto-select the first option if variants exist
    if (widget.livestock.variants.isNotEmpty) {
      _selectedVariant = widget.livestock.variants.first;
    }
  }

  Future<void> _checkFavoriteStatus() async {
    if (currentUser == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('favorites')
          .doc(widget.livestock.id)
          .get();
      if (mounted) {
        setState(() {
          _isFavorite = doc.exists;
        });
      }
    } catch (e) {
      debugPrint("Fav Error: $e");
    }
  }

  Future<void> _toggleFavorite() async {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please log in to save items")));
      return;
    }
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('favorites')
        .doc(widget.livestock.id);

    if (_isFavorite) {
      await ref.delete();
    } else {
      await ref.set({
        'livestockId': widget.livestock.id,
        'addedAt': FieldValue.serverTimestamp(),
      });
    }
    if (mounted) setState(() => _isFavorite = !_isFavorite);
  }

  Future<void> _fetchSellerInfo() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.livestock.sellerId)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _seller = UserModel.fromSnapshot(doc);
          _isLoadingSeller = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching seller: $e");
      if (mounted) setState(() => _isLoadingSeller = false);
    }
  }

  // --- ACTIONS ---
  void _navigateToChat() {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login to chat with seller")));
      return;
    }
    if (_seller == null) return;

    final List<String> ids = [currentUser!.uid, widget.livestock.sellerId]
      ..sort();
    final String chatId = "${ids[0]}_${ids[1]}";

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: chatId,
          otherUserId: widget.livestock.sellerId,
          otherUserName: _seller!.name,
        ),
      ),
    );
  }

  void _addToCart() async {
    if (currentUser == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Please login first")));
      return;
    }

    final double finalPrice = _selectedVariant?.price ?? widget.livestock.price;
    final String finalWeight =
        _selectedVariant?.weight ?? widget.livestock.weight;

    final cartManager = Provider.of<CartManager>(context, listen: false);

    await cartManager.addToCart(
      widget.livestock,
      context,
      variantWeight: finalWeight,
      variantPrice: finalPrice,
    );
  }

  void _buyNow() {
    if (currentUser == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Please login first")));
      return;
    }

    final double finalPrice = _selectedVariant?.price ?? widget.livestock.price;
    final String finalWeight =
        _selectedVariant?.weight ?? widget.livestock.weight;

    final tempItem = CartItem(
      id: "direct_buy_${widget.livestock.id}",
      livestock: widget.livestock,
      quantity: 1,
      selectedWeight: finalWeight,
      selectedPrice: finalPrice,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          items: [tempItem],
          totalAmount: tempItem.totalPrice,
        ),
      ),
    );
  }

  // Helper to safely parse numbers from Firestore
  int _safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    // 1. LISTEN TO DATABASE IN REAL-TIME
    return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('livestock')
            .doc(widget.livestock.id)
            .snapshots(),
        builder: (context, snapshot) {
          // --- VITAL FIX: DEFAULT TO 0 (Safe State), NOT widget.quantity (Stale State) ---
          int liveQty = 0;
          String liveStatus = 'available';

          // 2. GET REAL-TIME DATA
          if (snapshot.hasData &&
              snapshot.data != null &&
              snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            liveStatus = data['status'] ?? 'available';

            // Is this a variant selection?
            if (_selectedVariant != null && data['variants'] != null) {
              // VARIANT LOGIC
              List<dynamic> variants = data['variants'];
              bool foundVariant = false;
              for (var v in variants) {
                // Ensure we match weight cleanly
                if (v['weight'].toString() == _selectedVariant!.weight) {
                  liveQty = _safeInt(v['quantity']); // Use safe parser
                  foundVariant = true;
                  break;
                }
              }
              if (!foundVariant) {
                liveQty = 0;
              }
            } else {
              // SIMPLE PRODUCT LOGIC
              liveQty = _safeInt(data['quantity']);
            }
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            liveQty = widget.livestock.quantity;
          }

          // 3. DETERMINE SOLD OUT STATE
          final bool isSoldOut =
              liveQty <= 0 || liveStatus.toLowerCase() == 'sold';

          // UI Variables
          final double displayPrice =
              _selectedVariant?.price ?? widget.livestock.price;
          final String displayWeight =
              _selectedVariant?.weight ?? widget.livestock.weight;

          return Scaffold(
            backgroundColor: const Color(0xFFF9F6F0),
            body: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 300,
                  pinned: true,
                  leading: IconButton(
                    icon: const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.arrow_back, color: Colors.black),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    IconButton(
                      icon: CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorite ? Colors.red : Colors.grey,
                        ),
                      ),
                      onPressed: _toggleFavorite,
                    ),
                    const SizedBox(width: 10),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        CarouselSlider(
                          options: CarouselOptions(
                            height: 350,
                            viewportFraction: 1.0,
                            enableInfiniteScroll: false,
                            onPageChanged: (index, reason) {
                              setState(() => _currentImageIndex = index);
                            },
                          ),
                          items: widget.livestock.imagePaths.map((url) {
                            return Image.network(url,
                                fit: BoxFit.cover, width: double.infinity);
                          }).toList(),
                        ),
                        if (widget.livestock.imagePaths.length > 1)
                          Positioned(
                            bottom: 20,
                            child: Row(
                              children: widget.livestock.imagePaths
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                return Container(
                                  width: 8,
                                  height: 8,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentImageIndex == entry.key
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.5),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TITLE & PRICE
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                widget.livestock.name,
                                style: const TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              "₱${displayPrice.toStringAsFixed(0)}",
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF52B788)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // VARIANT SELECTOR
                        if (widget.livestock.variants.isNotEmpty) ...[
                          const Text("Select Weight / Size:",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: widget.livestock.variants.map((variant) {
                              bool isSelected = _selectedVariant == variant;
                              return ChoiceChip(
                                label: Text("${variant.weight}"),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _selectedVariant = variant);
                                  }
                                },
                                selectedColor:
                                    const Color(0xFF52B788).withOpacity(0.2),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? const Color(0xFF1B4332)
                                      : Colors.black,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              );
                            }).toList(),
                          ),
                          const Divider(height: 30),
                        ],

                        // LOCATION
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                color: Colors.grey, size: 20),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                widget.livestock.location,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // SELLER INFO
                        _buildSellerTile(context),

                        const SizedBox(height: 20),

                        // DESCRIPTION
                        const Text("Description",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(
                          widget.livestock.description,
                          style:
                              TextStyle(color: Colors.grey[600], height: 1.5),
                        ),
                        const SizedBox(height: 20),

                        // SPECS
                        const Text("Details",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        _buildSpecRow("Category", widget.livestock.category),
                        _buildSpecRow("Age", widget.livestock.age),
                        _buildSpecRow("Weight", displayWeight),

                        // REAL-TIME STOCK DISPLAY
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Stock",
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500)),

                              // Display "Sold Out" or the Qty
                              Text(
                                  isSoldOut ? "Sold Out" : "$liveQty available",
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isSoldOut
                                          ? Colors.red
                                          : const Color(0xFF52B788))),
                            ],
                          ),
                        ),

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // 4. DISABLE BUTTONS BASED ON LIVE DATA
            bottomNavigationBar: SafeArea(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    )
                  ],
                ),
                child: !isOwnListing
                    ? Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.chat_bubble_outline,
                                  color: Color(0xFF1B4332)),
                              tooltip: "Chat with Seller",
                              onPressed: _navigateToChat,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // ADD TO CART
                          Expanded(
                            child: ElevatedButton(
                              // Disable if Sold Out
                              onPressed: isSoldOut ? null : _addToCart,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSoldOut
                                    ? Colors.grey[300]
                                    : const Color(0xFFE8F5E9),
                                foregroundColor: isSoldOut
                                    ? Colors.grey
                                    : const Color(0xFF1B4332),
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(
                                  isSoldOut ? "Sold Out" : "Add to Cart",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // BUY NOW
                          Expanded(
                            child: ElevatedButton(
                              // Disable if Sold Out
                              onPressed: isSoldOut ? null : _buyNow,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSoldOut
                                    ? Colors.grey
                                    : const Color(0xFF1B4332),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(
                                isSoldOut ? "Sold Out" : "Buy Now",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      )
                    : const SizedBox(
                        height: 50,
                        child: Center(child: Text("This is your listing")),
                      ),
              ),
            ),
          );
        });
  }

  // --- WIDGETS ---
  Widget _buildSellerTile(BuildContext context) {
    if (_isLoadingSeller) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_seller == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7F4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(_seller!.profileImageUrl),
            radius: 24,
            backgroundColor: Colors.grey[300],
            onBackgroundImageError: (_, __) {},
            child: _seller!.profileImageUrl.isEmpty
                ? const Icon(Icons.person)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_seller!.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const Text("Verified Seller",
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => SellerStoreScreen(seller: _seller!)),
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Row(
              children: [
                Text(
                  "View Store",
                  style: TextStyle(
                    color: Color(0xFF52B788),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios,
                    size: 10, color: Color(0xFF52B788)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value, {bool isGreen = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500)),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isGreen
                      ? const Color(0xFF52B788)
                      : const Color(0xFF1B4332))),
        ],
      ),
    );
  }
}
