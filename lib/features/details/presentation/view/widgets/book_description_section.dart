import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libris_app/constants/app_colors.dart';
import 'package:libris_app/features/details/presentation/manager/book_details_cubit/book_details_cubit.dart';
import 'package:shimmer/shimmer.dart';

class BookDescriptionSection extends StatefulWidget {
  const BookDescriptionSection({
    super.key,
    this.title = 'About the Book',
    this.collapsedMaxLines = 3,
  });

  final String title;
  final int collapsedMaxLines;

  @override
  State<BookDescriptionSection> createState() =>
      _BookDescriptionSectionState();
}

class _BookDescriptionSectionState extends State<BookDescriptionSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2416),
            ),
          ),
          const SizedBox(height: 12),

          BlocBuilder<BookDetailsCubit, BookDetailsState>(
            builder: (context, state) {
              if (state is BookDetailsLoading) {
                return Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: MediaQuery.sizeOf(context).width * 0.6,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                );
              }

              String description = 'No description available for this book.';
              if (state is BookDetailsSuccess) {
                description = state.bookDetail.description;
              } else if (state is BookDetailsFailure) {
                description = 'Could not load book description.';
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: Text(
                      description,
                      maxLines: _isExpanded ? null : widget.collapsedMaxLines,
                      overflow:
                          _isExpanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Color(0xFF625D52),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (description.length > 100)
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _isExpanded ? 'Read Less' : 'Read More',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              size: 20,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
