import 'package:flutter/material.dart';
import 'package:libris_app/constants/app_colors.dart';
import 'package:libris_app/core/utils/styles.dart';

class CustomAppBar extends StatelessWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Libris",
            style: Styles.intelStyle.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
              fontSize: 32,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, size: 32, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
