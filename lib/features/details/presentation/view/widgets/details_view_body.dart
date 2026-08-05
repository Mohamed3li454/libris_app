import 'package:flutter/material.dart';
import 'package:libris_app/constants/app_colors.dart';
import 'package:libris_app/core/models/book_model.dart';
import 'package:libris_app/core/utils/styles.dart';
import 'package:libris_app/features/details/presentation/view/widgets/book_description_section.dart';
import 'package:libris_app/features/details/presentation/view/widgets/book_details_item.dart';
import 'package:libris_app/features/details/presentation/view/widgets/book_header_info.dart';
import 'package:libris_app/features/details/presentation/view/widgets/book_stats_card.dart';
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
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 28,
                  color: AppColors.primary,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                "Libris",
                style: Styles.intelStyle.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(
                  Icons.share,
                  size: 28,
                  color: AppColors.primary,
                ),
                onPressed: () {},
              ),
            ),
            const SizedBox(height: 8),
            BookDetailsItem(imageUrl: bookModel?.coverUrl),
            const SizedBox(height: 12),
            BookHeaderInfo(
              title: bookModel?.title ?? 'Book Details',
              author: bookModel?.authorName ?? '',
            ),
            const SizedBox(height: 4),
            BookStatsCard(publishYear: bookModel?.firstPublishYear),
            const BookDescriptionSection(),
          ],
        ),
      ),
    );
  }
}
