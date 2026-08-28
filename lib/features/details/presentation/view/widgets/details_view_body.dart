import 'package:flutter/material.dart';
import 'package:libris_app/core/models/book_model.dart';
import 'package:libris_app/core/theme/app_theme.dart';
import 'package:libris_app/core/utils/styles.dart';
import 'package:libris_app/features/details/presentation/view/widgets/book_description_section.dart';
import 'package:libris_app/features/details/presentation/view/widgets/book_details_item.dart';
import 'package:libris_app/features/details/presentation/view/widgets/book_header_info.dart';
import 'package:libris_app/features/details/presentation/view/widgets/book_stats_card.dart';
import 'package:libris_app/features/details/presentation/view/widgets/favorite_icon_button.dart';
import 'package:libris_app/features/details/presentation/view/widgets/similar_books_section.dart';
import 'package:libris_app/features/home/presentation/view/widgets/custom_appbar.dart';

class DetailsViewBody extends StatelessWidget {
  final BookModel? bookModel;

  const DetailsViewBody({super.key, this.bookModel});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            CustomAppBar(
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  size: 28,
                  color: context.colors.primary,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                "Libris",
                style: Styles.interStyle.copyWith(
                  color: context.colors.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                ),
              ),
              trailing: FavoriteIconButton(bookModel: bookModel),
            ),
            const SizedBox(height: 8),
            BookDetailsItem(
              imageUrl: bookModel?.coverUrl,
              heroTag: bookModel?.coverHeroTag,
            ),
            const SizedBox(height: 12),
            BookHeaderInfo(
              title: bookModel?.title ?? 'Book Details',
              author: bookModel?.authorName ?? '',
            ),
            const SizedBox(height: 4),
            BookStatsCard(
              publishYear: bookModel?.firstPublishYear,
              language: bookModel?.language,
            ),
            const BookDescriptionSection(),
            const SimilarBooksSection(),
          ],
        ),
      ),
    );
  }
}
