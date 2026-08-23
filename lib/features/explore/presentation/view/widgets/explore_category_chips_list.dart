import 'package:flutter/material.dart';

class ExploreCategoryChipsList extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final VoidCallback onClearSelection;

  const ExploreCategoryChipsList({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.onClearSelection,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            final isAllSelected = selectedCategory == null;
            return ChoiceChip(
              label: const Text('All'),
              selected: isAllSelected,
              selectedColor: const Color(0xFFFBE2AC),
              backgroundColor: const Color(0xFFEBEAE4),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9999),
              ),
              labelStyle: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: isAllSelected ? FontWeight.w600 : FontWeight.w400,
                color: const Color(0xFF2C2C2C),
              ),
              onSelected: (_) => onClearSelection(),
            );
          }

          final category = categories[index - 1];
          final isSelected = selectedCategory == category;
          return ChoiceChip(
            label: Text(category),
            selected: isSelected,
            selectedColor: const Color(0xFFFBE2AC),
            backgroundColor: const Color(0xFFEBEAE4),
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9999),
            ),
            labelStyle: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: const Color(0xFF2C2C2C),
            ),
            onSelected: (selected) {
              if (selected) {
                onCategorySelected(category);
              } else {
                onClearSelection();
              }
            },
          );
        },
      ),
    );
  }
}
