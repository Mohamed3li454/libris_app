import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libris_app/core/theme/app_theme.dart';
import 'package:libris_app/features/details/presentation/manager/book_details_cubit/book_details_cubit.dart';
import 'package:shimmer/shimmer.dart';

class BookStatsCard extends StatelessWidget {
  final int? publishYear;
  final String? language;

  const BookStatsCard({super.key, this.publishYear, this.language});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookDetailsCubit, BookDetailsState>(
      builder: (context, state) {
        if (state is BookDetailsLoading) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.07),
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
        String languageText = language ?? 'EN';
        if (state is BookDetailsSuccess) {
          rating = state.bookDetail.averageRating;
          ratingCount = state.bookDetail.ratingCount;
          final detailLanguage = state.bookDetail.language;
          if (detailLanguage != null && detailLanguage.isNotEmpty) {
            languageText = detailLanguage;
          }
        }

        final String ratingText = rating > 0 ? rating.toStringAsFixed(1) : "N/A";
        final String yearText = publishYear != null ? "$publishYear" : "N/A";
        final String ratingsCountText = ratingCount > 0 ? "$ratingCount" : "OpenLib";

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: context.colors.primary.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: context.colors.primary.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
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
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.titleColor,
                          ),
                        ),
                      ],
                    ),
                    label: 'RATING',
                  ),
                ),
                _buildDivider(context),
                Expanded(
                  child: _buildStatItem(
                    context,
                    value: yearText,
                    label: 'YEAR',
                  ),
                ),
                _buildDivider(context),
                Expanded(
                  child: _buildStatItem(
                    context,
                    value: languageText,
                    label: 'LANG',
                  ),
                ),
                _buildDivider(context),
                Expanded(
                  child: _buildStatItem(
                    context,
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

  Widget _buildDivider(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: context.colors.primary.withValues(alpha: 0.15),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.titleColor,
              ),
            ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: context.mutedColor,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}
