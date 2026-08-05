import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libris_app/features/home/presentation/manager/filter_books_cubit/filter_books_cubit.dart';

class FilterChipsList extends StatefulWidget {
  const FilterChipsList({super.key});

  @override
  State<FilterChipsList> createState() => _FilterChipsListState();
}

class _FilterChipsListState extends State<FilterChipsList> {
  int _selectedIndex = 0;

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
    'Motivation',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final isSelected = _selectedIndex == index;
          return FilterChipItem(
            label: filters[index],
            isSelected: isSelected,
            onTap: () {
              if (_selectedIndex != index) {
                setState(() {
                  _selectedIndex = index;
                });
                BlocProvider.of<FilterBooksCubit>(
                  context,
                ).fetchFilterBooks(category: filters[index]);
              }
            },
          );
        },
      ),
    );
  }
}

class FilterChipItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const FilterChipItem({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
      ),
    );
  }
}
