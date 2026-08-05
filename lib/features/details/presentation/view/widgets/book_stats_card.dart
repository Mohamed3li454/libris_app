import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libris_app/constants/app_colors.dart';
import 'package:libris_app/features/details/presentation/manager/book_details_cubit/book_details_cubit.dart';
import 'package:shimmer/shimmer.dart';

class BookStatsCard extends StatelessWidget {
  final int? publishYear;

  const BookStatsCard({super.key, this.publishYear});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookDetailsCubit, BookDetailsState>(
      builder: (context, state) {
        if (state is BookDetailsLoading) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  4,
                  (index) => Container(
                    width: 50,
                    height: 35,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        double rating = 0.0;
        int ratingCount = 0;
        if (state is BookDetailsSuccess) {
          rating = state.bookDetail.averageRating;
          ratingCount = state.bookDetail.ratingCount;
        }

        String ratingText = rating > 0 ? rating.toStringAsFixed(1) : "N/A";
        String yearText = publishYear != null ? "$publishYear" : "N/A";
        String ratingsCountText =
            ratingCount > 0 ? "$ratingCount" : "OpenLib";

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _buildStatItem(
                    valueWidget: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFE5A624),
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          ratingText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C2416),
                          ),
                        ),
                      ],
                    ),
                    label: 'RATING',
                  ),
                ),
                _buildDivider(),
                Expanded(
                  child: _buildStatItem(
                    value: yearText,
                    label: 'YEAR',
                  ),
                ),
                _buildDivider(),
                Expanded(
                  child: _buildStatItem(
                    value: 'EN',
                    label: 'LANG',
                  ),
                ),
                _buildDivider(),
                Expanded(
                  child: _buildStatItem(
                    value: ratingsCountText,
                    label: 'VOTES',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 28,
      color: AppColors.primary.withValues(alpha: 0.15),
    );
  }

  Widget _buildStatItem({
    String? value,
    Widget? valueWidget,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        valueWidget ??
            Text(
              value ?? '',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2416),
              ),
            ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.muted,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}
