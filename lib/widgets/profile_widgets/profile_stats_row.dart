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
          _buildStat(
              'Listings', totalListings.toString(), Icons.layers_outlined),
          const SizedBox(width: 12),
          _buildStat(
              'Sales', totalSales.toString(), Icons.shopping_bag_outlined),
          const SizedBox(width: 12),
          _buildStat('Earnings', '₱${totalEarnings.toStringAsFixed(0)}',
              Icons.monetization_on_outlined),
        ],
      ),
    );
  }

  Widget _buildStat(String title, String value, IconData icon) {
    const Color textDark = Color(0xFF1B4332);
    const Color brandGreen = Color(0xFF52B788);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, // White Card
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: textDark.withOpacity(0.08), // Soft Shadow
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: brandGreen, size: 28), // Brand Green Icon
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: textDark, // Dark Text
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500, // Grey Label
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
