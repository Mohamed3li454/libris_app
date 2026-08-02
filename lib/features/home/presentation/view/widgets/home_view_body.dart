import 'package:flutter/material.dart';
import 'package:libris_app/features/home/presentation/view/widgets/custom_appbar.dart';
import 'package:libris_app/features/home/presentation/view/widgets/featured_books_section.dart';
import 'package:libris_app/features/home/presentation/view/widgets/filter_book_sliver_list_view.dart';
import 'package:libris_app/features/home/presentation/view/widgets/filter_chips_list.dart';

class HomeViewBody extends StatelessWidget {
  const HomeViewBody({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: CustomScrollView(
        physics: BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomAppBar(),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.only(left: 20),
                  child: FeaturedBooksSection(),
                ),
                SizedBox(height: 24),
                Padding(
                  padding: EdgeInsets.only(left: 20),
                  child: FilterChipsList(),
                ),
                SizedBox(height: 12),
              ],
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.only(left: 20),
            sliver: FilterBookSliverListView(),
          ),
        ],
      ),
    );
  }
}
