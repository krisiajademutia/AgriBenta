import 'package:flutter/material.dart';

class SectionSearch extends StatelessWidget {
  final ValueChanged<String> onSearchChanged;

  const SectionSearch({
    super.key,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 55,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1B4332)
                      .withOpacity(0.06), // Softer shadow
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.grey.shade100), // Subtle border
            ),
            child: TextField(
              onChanged: onSearchChanged,
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                hintText: "Search livestock...",
                hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w400,
                    fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: Color(0xFF52B788), size: 24),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // --- ADDED: Filter Button Visual ---
        Container(
          height: 55,
          width: 55,
          decoration: BoxDecoration(
            color: const Color(0xFF52B788),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF52B788).withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.tune_rounded, color: Colors.white),
        ),
      ],
    );
  }
}
