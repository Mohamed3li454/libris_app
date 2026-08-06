import 'package:flutter/material.dart';
import 'package:libris_app/constants/app_colors.dart';

class ExploreWelcomeState extends StatelessWidget {
  const ExploreWelcomeState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFE8DFC8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_outlined,
              size: 44,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Search Any Book or Genre',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Type a book name above or select a category to start exploring.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
