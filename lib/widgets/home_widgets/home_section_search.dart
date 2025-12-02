// lib/widgets/home/section_search.dart
import 'package:flutter/material.dart';

class SectionSearch extends StatelessWidget {
  const SectionSearch({super.key});

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: "Search livestock",
        prefixIcon: const Icon(Icons.search, color: Color(0xFF1A5F3A)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}