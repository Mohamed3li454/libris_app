import 'package:flutter/material.dart';

class FilterChipsList extends StatelessWidget {
  const FilterChipsList({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> filters = [
      'All',
      'Tech',
      'Fiction',
      'History',
      'Business',
      'Science',
      'Programming',
      'Thriller',
      'Romance',
      'Motivational',
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final isSelected = index == 0;
          return FilterChipItem(label: filters[index], isSelected: isSelected);
        },
      ),
    );
  }
}

class FilterChipItem extends StatelessWidget {
  final String label;
  final bool isSelected;

  const FilterChipItem({
    super.key,
    required this.label,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFBE2AC) : const Color(0xFFEBEAE4),
        borderRadius: BorderRadius.circular(9999),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
          color: const Color(0xFF2C2C2C),
        ),
      ),
    );
  }
}
