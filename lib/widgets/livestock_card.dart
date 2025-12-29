import 'package:flutter/material.dart';
import '../models/livestock_model.dart';

class LivestockCard extends StatelessWidget {
  final Livestock livestock;
  final VoidCallback onTap;

  const LivestockCard({
    super.key,
    required this.livestock,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color brandGreen = Color(0xFF52B788);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Image Section
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  livestock.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[100],
                    child: const Icon(Icons.image_not_supported,
                        color: Colors.grey),
                  ),
                ),
              ),
            ),

            // 2. Info Section
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    livestock.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1B4332),
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Location (Added as requested)
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          livestock.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Price
                  Text(
                    "₱${livestock.price.toStringAsFixed(0)}",
                    style: const TextStyle(
                      color: brandGreen,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
