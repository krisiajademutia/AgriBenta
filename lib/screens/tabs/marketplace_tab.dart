import 'package:agribenta/screens/cart_screen.dart';
import 'package:agribenta/services/cart_manager.dart';
import 'package:agribenta/widgets/home_widgets/home_section_categories.dart';
import 'package:agribenta/widgets/home_widgets/home_section_search.dart';
import 'package:agribenta/widgets/home_widgets/livestock_filter_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MarketplaceTab extends StatefulWidget {
  const MarketplaceTab({super.key});

  @override
  State<MarketplaceTab> createState() => _MarketplaceTabState();
}

class _MarketplaceTabState extends State<MarketplaceTab> {
  String _selectedCategoryName = 'All';
  String _searchQuery = ''; // <--- New State Variable

  void _updateSelectedCategory(String newCategoryName) {
    setState(() {
      _selectedCategoryName = newCategoryName;
    });
  }

  void _updateSearchQuery(String value) {
    // <--- New Function
    setState(() {
      _searchQuery = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color bgCream = Color(0xFFF9F6F0);
    const Color textDark = Color(0xFF1B4332);

    return Scaffold(
      backgroundColor: bgCream,
      body: CustomScrollView(
        slivers: [
          // 1. APP BAR
          SliverAppBar(
            floating: true,
            backgroundColor: bgCream,
            surfaceTintColor: bgCream,
            automaticallyImplyLeading: false,
            elevation: 0,
            title: const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Text("AgriBenta",
                  style: TextStyle(
                      color: textDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 24)),
            ),
            actions: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_outlined,
                    color: textDark, size: 26),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Consumer<CartManager>(
                  builder: (context, cartManager, child) {
                    return Stack(
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const CartScreen()),
                            );
                          },
                          icon: const Icon(Icons.shopping_cart_outlined,
                              color: textDark, size: 26),
                        ),
                        StreamBuilder<int>(
                          stream: cartManager.cartItemCountStream,
                          builder: (context, snapshot) {
                            final itemCount = snapshot.data ?? 0;
                            if (itemCount == 0) return const SizedBox();

                            return Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                    minWidth: 18, minHeight: 18),
                                child: Text(
                                  '$itemCount',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),

          // 2. BODY
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // SEARCH SECTION (Now connected)
                  SectionSearch(
                    onSearchChanged: _updateSearchQuery,
                  ),

                  const SizedBox(height: 24),

                  // CATEGORIES SECTION
                  SectionCategories(
                    onCategorySelected: _updateSelectedCategory,
                    selectedCategoryName: _selectedCategoryName,
                  ),

                  const SizedBox(height: 32),

                  // LIST SECTION (Now receives search query)
                  LivestockFilterWrapper(
                    // Key forces a rebuild if category changes, ensuring stream updates
                    key: ValueKey("$_selectedCategoryName-$_searchQuery"),
                    selectedCategoryName: _selectedCategoryName,
                    searchQuery: _searchQuery,
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
