import 'package:flutter/material.dart';
import 'package:libris_app/constants/app_colors.dart';

class BookHeaderInfo extends StatelessWidget {
  const BookHeaderInfo({
    super.key,
    this.category = 'FANTASY',
    this.title = 'The Gilded Alchemist',
    this.author = 'by Elena Vance',
  });

  final String category;
  final String title;
  final String author;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Category / Genre Tag
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Text(
            category.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Book Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2416),
              height: 1.25,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Author Name
        Text(
          author,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }
}
