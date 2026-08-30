import 'package:flutter/material.dart';
import 'package:libris_app/constants/app_colors.dart';
import 'package:libris_app/core/theme/app_theme.dart';

class CustomSearchTextField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback onClear;

  const CustomSearchTextField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onSubmitted,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.lightOutline, width: 1.5),
        color: const Color.fromARGB(163, 246, 245, 243),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          color: Color(0xFF2C2C2C),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Search books, authors, or genres...',
          hintStyle: const TextStyle(
            color: AppColors.muted,
            fontSize: 14,
            fontFamily: 'Inter',
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.primary,
            size: 22,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear_rounded,
                    color: AppColors.secondary,
                    size: 20,
                  ),
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
