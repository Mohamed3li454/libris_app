import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libris_app/constants/app_colors.dart';
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
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
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
      child: AnimatedScale(
        scale: isSelected ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? AppColors.darkPrimary.withValues(alpha: 0.7)
                  : AppColors.lightOutline,
              width: 1.5,
            ),
            color: isSelected
                ? const Color.fromARGB(210, 246, 245, 243)
                : const Color(0xFFEBEAE4),
            borderRadius: BorderRadius.circular(9999),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFC9A74D).withValues(alpha: 0.28),
                      blurRadius: 8,
                      spreadRadius: 0.1,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: const Color(0xFF2C2C2C),
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}
