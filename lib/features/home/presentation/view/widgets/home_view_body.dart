import 'package:flutter/material.dart';
import 'package:libris_app/constants/app_colors.dart';
import 'package:libris_app/core/utils/styles.dart';
import 'package:libris_app/features/home/presentation/view/widgets/custom_appbar.dart';
import 'package:libris_app/features/home/presentation/view/widgets/featured_books_section.dart';
import 'package:libris_app/features/home/presentation/view/widgets/filter_book_sliver_list_view.dart';
import 'package:libris_app/features/home/presentation/view/widgets/filter_chips_list.dart';

class HomeViewBody extends StatelessWidget {
  const HomeViewBody({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomAppBar(
                  leading: Text(
                    "Libris",
                    style: Styles.intelStyle.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.only(left: 20),
                  child: FeaturedBooksSection(),
                ),
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.only(left: 20),
                  child: FilterChipsList(),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.only(left: 20),
            sliver: FilterBookSliverListView(),
          ),
        ],
      ),
    );
  }
}
