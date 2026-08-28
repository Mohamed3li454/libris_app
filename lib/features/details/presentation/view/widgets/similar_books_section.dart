import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:libris_app/core/theme/app_theme.dart';
import 'package:libris_app/core/widgets/fade_slide_in.dart';
import 'package:libris_app/features/details/presentation/manager/book_details_cubit/book_details_cubit.dart';

class SimilarBooksSection extends StatelessWidget {
  const SimilarBooksSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookDetailsCubit, BookDetailsState>(
      builder: (context, state) {
        if (state is! BookDetailsSuccess) {
          return const SizedBox.shrink();
        }
        if (state.isSimilarLoading) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Similar books',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.titleColor,
                  ),
                ),
                const SizedBox(height: 12),
                const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ],
            ),
          );
        }
        if (state.similarBooks.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Similar books',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.titleColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 170,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  scrollDirection: Axis.horizontal,
                  itemCount: state.similarBooks.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final book = state.similarBooks[index];
                    return FadeSlideIn(
                      index: index,
                      child: GestureDetector(
                      onTap: () {
                        context.push('/details', extra: book);
                      },
                      child: SizedBox(
                        width: 96,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Hero(
                               tag: book.coverHeroTag,
                               child: ClipRRect(
                               borderRadius: BorderRadius.circular(10),
                               child: AspectRatio(
                                aspectRatio: 3 / 4,
                                child: book.coverUrl.isEmpty
                                    ? ColoredBox(
                                        color: context.pillColor,
                                        child: Icon(
                                          Icons.menu_book_rounded,
                                          color: context.mutedColor,
                                        ),
                                      )
                                    : CachedNetworkImage(
                                        imageUrl: book.coverUrl,
                                        fit: BoxFit.cover,
                                        errorWidget: (context, url, error) =>
                                            ColoredBox(
                                              color: context.pillColor,
                                              child: Icon(
                                                Icons.menu_book_rounded,
                                                color: context.mutedColor,
                                              ),
                                            ),
                                       ),
                               ),
                               ),
                             ),
                             const SizedBox(height: 6),
                            Text(
                              book.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: context.titleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
