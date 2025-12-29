import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart';
import '../../models/livestock_model.dart';
import '../../models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/cart_manager.dart';
import 'checkout_screen.dart';
import 'seller_store_screen.dart';
import 'chat_screen.dart';

class LivestockDetailScreen extends StatefulWidget {
  final Livestock livestock;

  const LivestockDetailScreen({super.key, required this.livestock});

  @override
  State<LivestockDetailScreen> createState() => _LivestockDetailScreenState();
}

class _LivestockDetailScreenState extends State<LivestockDetailScreen> {
  int _currentImageIndex = 0;
  bool _isFavorite = false;
  bool _isLoadingFavorite = true;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  UserModel? _seller;
  bool _isLoadingSeller = true;

  bool get isOwnListing => currentUser?.uid == widget.livestock.sellerId;

  @override
  void initState() {
    super.initState();
    _fetchSellerInfo();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    if (currentUser == null) {
      setState(() => _isLoadingFavorite = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('favorites')
          .doc(widget.livestock.id) // Assuming your model has an 'id' field
          .get();

      if (mounted) {
        setState(() {
          _isFavorite = doc.exists;
          _isLoadingFavorite = false;
        });
      }
    } catch (e) {
      debugPrint("Error checking favorite: $e");
      if (mounted) setState(() => _isLoadingFavorite = false);
    }
  }

  // --- 2. TOGGLE FAVORITE BUTTON ---
  Future<void> _toggleFavorite() async {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in to add favorites")),
      );
      Navigator.pushNamed(context, '/login');
      return;
    }

    // Optimistic Update: Flip the UI immediately for speed
    setState(() => _isFavorite = !_isFavorite);

    final favRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('favorites')
        .doc(widget.livestock.id);

    try {
      if (_isFavorite) {
        // --- ADD TO FAVORITES ---
        // We save a "Snapshot" of the item so we can display it in a list later
        // without fetching the main livestock collection again.
        await favRef.set({
          'livestockId': widget.livestock.id,
          'name': widget.livestock.name,
          'price': widget.livestock.price,
          'imagePath': widget.livestock.imagePath,
          'sellerId': widget.livestock.sellerId,
          'addedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Added to favorites"),
              duration: Duration(seconds: 1),
              backgroundColor: Color(0xFF52B788),
            ),
          );
        }
      } else {
        // --- REMOVE FROM FAVORITES ---
        await favRef.delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Removed from favorites"),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      // If error, revert the UI change
      if (mounted) {
        setState(() => _isFavorite = !_isFavorite);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating favorite: $e")),
        );
      }
    }
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
      } else {
        if (mounted) setState(() => _isLoadingSeller = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingSeller = false);
      debugPrint("Error fetching seller: $e");
    }
  }

  void _contactSeller() {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in to message the seller")),
      );
      // Ensure you have a route named '/login' or handle navigation
      // Navigator.pushNamed(context, '/login');
      return;
    }

    if (isOwnListing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You cannot message yourself")),
      );
      return;
    }

    final String myId = currentUser!.uid.trim();
    final String sellerId = widget.livestock.sellerId.trim();

    List<String> ids = [myId, sellerId];
    ids.sort(); // This ensures A->B is same chat room as B->A
    String chatId = ids.join("_");

    // 4. GET SELLER NAME (Use loaded data OR fallback immediately)
    // We do NOT await here. We navigate instantly.
    String sellerName = _seller?.name ?? "Seller";

    // 5. NAVIGATE INSTANTLY
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatId: chatId,
          otherUserId: sellerId,
          otherUserName: sellerName,
        ),
      ),
    );
  }

  void _buyNow() {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in to buy")),
      );
      // Navigator.pushNamed(context, '/login');
      return;
    }

    if (isOwnListing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You cannot buy your own listing")),
      );
      return;
    }

    final buyNowItem = CartItem(
      id: 'buy_now_${DateTime.now().millisecondsSinceEpoch}',
      livestock: widget.livestock,
      quantity: 1,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          items: [buyNowItem],
          totalAmount: widget.livestock.price,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color textDark = Color(0xFF1B4332);
    const Color brandGreen = Color(0xFF52B788);
    const Color bgColor = Color(0xFFFAFAFA);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Product Details',
          style: TextStyle(
            color: textDark,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : textDark,
              size: 22,
            ),
            onPressed: _isLoadingFavorite ? null : _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: textDark, size: 22),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Image Carousel ---
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  CarouselSlider(
                    options: CarouselOptions(
                      height: 320,
                      viewportFraction: 1.0,
                      enableInfiniteScroll:
                          widget.livestock.imagePaths.length > 1,
                      autoPlay: false,
                      onPageChanged: (index, reason) {
                        setState(() => _currentImageIndex = index);
                      },
                    ),
                    items: widget.livestock.imagePaths.map((url) {
                      return Image.network(
                        url,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[100],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_not_supported_outlined,
                                  size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text(
                                'Image not available',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (widget.livestock.imagePaths.length > 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          widget.livestock.imagePaths.length,
                          (index) => Container(
                            width: _currentImageIndex == index ? 20 : 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: _currentImageIndex == index
                                  ? brandGreen
                                  : Colors.grey[300],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // --- Product Info ---
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: brandGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.livestock.category.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: brandGreen,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.livestock.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                      letterSpacing: -0.3,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '₱${widget.livestock.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: brandGreen,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // --- Specs ---
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Specifications',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSpecRow('Weight', '${widget.livestock.weight} kg'),
                  _buildSpecRow('Age', widget.livestock.age),
                  _buildSpecRow('Location', widget.livestock.location),
                  _buildSpecRow(
                    'Stock Available',
                    widget.livestock.quantity > 0
                        ? '${widget.livestock.quantity} heads'
                        : 'Out of Stock',
                    isGreen: widget.livestock.quantity > 0,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // --- Description ---
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.livestock.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.6,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // --- SELLER INFO (Optimized) ---
            // Uses the _seller variable we loaded in initState
            if (_isLoadingSeller)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: brandGreen.withOpacity(0.1),
                      backgroundImage: (_seller != null &&
                              _seller!.profileImageUrl.isNotEmpty &&
                              !_seller!.profileImageUrl
                                  .contains('placehold.co'))
                          ? NetworkImage(_seller!.profileImageUrl)
                          : null,
                      child: (_seller == null ||
                              _seller!.profileImageUrl.isEmpty ||
                              _seller!.profileImageUrl.contains('placehold.co'))
                          ? const Icon(Icons.person,
                              color: brandGreen, size: 24)
                          : null,
                    ),
                    const SizedBox(width: 12),

                    // Name & Trusted Label
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _seller?.name ?? "Seller",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.verified, size: 14, color: brandGreen),
                              const SizedBox(width: 4),
                              Text(
                                'Trusted Merchant',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // View Store Button
                    TextButton(
                      onPressed: _seller == null
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SellerStoreScreen(
                                    seller: _seller!,
                                  ),
                                ),
                              );
                            },
                      style: TextButton.styleFrom(
                        foregroundColor: brandGreen,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      child: const Text(
                        'View Store',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 80),
          ],
        ),
      ),

      // --- Bottom Action Bar ---
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                // MESSAGE BUTTON (Now Fixed)
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.chat_bubble_outline,
                        color: Color(0xFF1B4332), size: 22),
                    onPressed: _contactSeller, // Uses the optimized function
                  ),
                ),
                const SizedBox(width: 12),

                // Add to Cart
                Expanded(
                  child: Consumer<CartManager>(
                    builder: (context, cartManager, child) {
                      bool isLoading = false;
                      bool isOutOfStock = widget.livestock.quantity == 0;

                      return StatefulBuilder(
                        builder: (context, setState) {
                          return SizedBox(
                            height: 50,
                            child: OutlinedButton(
                              onPressed: (isLoading || isOutOfStock)
                                  ? null
                                  : () async {
                                      setState(() => isLoading = true);
                                      await cartManager.addToCart(
                                          widget.livestock, context);
                                      if (mounted) {
                                        setState(() => isLoading = false);
                                      }
                                    },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    color: isOutOfStock
                                        ? Colors.grey
                                        : const Color(0xFF52B788),
                                    width: 1.5),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF52B788),
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.shopping_cart_outlined,
                                      color: Color(0xFF52B788)),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),

                // Buy Now
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: widget.livestock.quantity > 0 ? _buyNow : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.livestock.quantity > 0
                            ? const Color(0xFF52B788)
                            : Colors.grey,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        widget.livestock.quantity > 0
                            ? 'Buy Now'
                            : 'Out of Stock',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecRow(String label, String value, {bool isGreen = false}) {
    const Color brandGreen = Color(0xFF52B788);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isGreen ? brandGreen : const Color(0xFF1B4332),
            ),
          ),
        ],
      ),
    );
  }
}
