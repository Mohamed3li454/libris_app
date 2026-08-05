import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libris_app/constants/app_colors.dart';
import 'package:libris_app/features/details/presentation/manager/book_details_cubit/book_details_cubit.dart';
import 'package:shimmer/shimmer.dart';

class BookHeaderInfo extends StatelessWidget {
  const BookHeaderInfo({
    super.key,
    required this.title,
    required this.author,
  });

  final String title;
  final String author;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Category / Genre Tag with BlocBuilder & Shimmer loading
        BlocBuilder<BookDetailsCubit, BookDetailsState>(
          builder: (context, state) {
            if (state is BookDetailsLoading) {
              return Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: 100,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              );
            }

            String category = 'GENERAL';
            if (state is BookDetailsSuccess) {
              category = state.bookDetail.primaryCategory.toUpperCase();
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Text(
                category,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  letterSpacing: 1.2,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
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
        const SizedBox(height: 2),
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
