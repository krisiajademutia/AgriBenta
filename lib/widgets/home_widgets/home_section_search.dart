import 'package:flutter/material.dart';

class SectionSearch extends StatelessWidget {
  final ValueChanged<String> onSearchChanged;

  const SectionSearch({
    super.key,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4332).withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        onChanged: onSearchChanged,
        decoration: InputDecoration(
          hintText: "Search livestock...",
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon:
              const Icon(Icons.search_rounded, color: Color(0xFF52B788)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}
