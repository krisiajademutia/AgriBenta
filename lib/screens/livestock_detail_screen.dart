import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart';
import '../../models/livestock_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/cart_manager.dart';
import 'checkout_screen.dart';

class LivestockDetailScreen extends StatefulWidget {
  final Livestock livestock;

  const LivestockDetailScreen({super.key, required this.livestock});

  @override
  State<LivestockDetailScreen> createState() => _LivestockDetailScreenState();
}

class _LivestockDetailScreenState extends State<LivestockDetailScreen> {
  int _currentImageIndex = 0;
  bool _isFavorite = false;

  // Fixed: Only declare once
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Computed getter — clean and safe
  bool get isOwnListing => currentUser?.uid == widget.livestock.sellerId;

  void _contactSeller() {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in to message the seller")),
      );
      Navigator.pushNamed(context, '/login');
      return;
    }

    if (isOwnListing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You cannot message yourself")),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Opening chat with seller... (Coming soon!)"),
        backgroundColor: Color(0xFF52B788),
      ),
    );
  }

  void _buyNow() {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in to buy")),
      );
      Navigator.pushNamed(context, '/login');
      return;
    }

    if (isOwnListing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You cannot buy your own listing")),
      );
      return;
    }

    // 1. Create a temporary CartItem just for this transaction
    final buyNowItem = CartItem(
      id: 'buy_now_${DateTime.now().millisecondsSinceEpoch}',
      livestock: widget.livestock,
      quantity: 1,
    );

    // 2. Navigate to Checkout
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          items: [buyNowItem], // Pass as a list of 1
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
            onPressed: () {
              setState(() => _isFavorite = !_isFavorite);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isFavorite
                        ? "Added to favorites"
                        : "Removed from favorites",
                  ),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: textDark, size: 22),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Share functionality coming soon"),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Carousel Section
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
                  // Image indicator dots
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

            // Product Information Card
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Badge
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

                  // Product Name
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

                  // Price and Rating Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '₱${widget.livestock.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: brandGreen,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Spacer(),
                      // Mock Rating
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Specifications Card
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
                  _buildSpecRow('Availability', 'In Stock', isGreen: true),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Description Card
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

            // Seller Information Card
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: brandGreen.withOpacity(0.1),
                    child: const Icon(Icons.store, color: brandGreen, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Verified Seller',
                          style: TextStyle(
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
                  TextButton(
                    onPressed: () {},
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

      // Bottom Action Bar
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
                // Contact Seller Button
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
                    onPressed: _contactSeller, // Use the method defined at top
                  ),
                ),
                const SizedBox(width: 12),

                // Add to Cart Button
                Expanded(
                  child: Consumer<CartManager>(
                    builder: (context, cartManager, child) {
                      bool isLoading = false;
                      return StatefulBuilder(
                        builder: (context, setState) {
                          return SizedBox(
                            height: 50,
                            child: OutlinedButton(
                              onPressed: isLoading
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
                                side: const BorderSide(
                                    color: Color(0xFF52B788), width: 1.5),
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
                                  : const Text(
                                      'Add to Cart',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF52B788),
                                      ),
                                    ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),

                // Buy Now Button (FIXED HERE)
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      // We simply call the _buyNow function defined at the top of your class
                      // This validates the user and sends them to the CheckoutScreen
                      onPressed: _buyNow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF52B788),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        'Buy Now',
                        style: TextStyle(
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
