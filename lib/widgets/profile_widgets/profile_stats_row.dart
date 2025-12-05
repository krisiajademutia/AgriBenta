import 'package:flutter/material.dart';

class ProfileStatsRow extends StatelessWidget {
  final int totalListings;
  final int totalSales;
  final double totalEarnings;

  const ProfileStatsRow({
    super.key,
    required this.totalListings,
    required this.totalSales,
    required this.totalEarnings,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          _buildStat('Listings', totalListings.toString(), Icons.layers_outlined),
          _buildStat('Sales', totalSales.toString(), Icons.shopping_bag_outlined),
          _buildStat('Earnings', '₱${totalEarnings.toStringAsFixed(0)}', Icons.monetization_on_outlined),
        ],
      ),
    );
  }

  Widget _buildStat(String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFF1E6A3F), size: 30),
              //const SizedBox(height: 5),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0D4C2F))),
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}