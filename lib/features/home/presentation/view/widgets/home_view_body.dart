import 'package:flutter/material.dart';
import 'package:libris_app/constants/app_colors.dart';
import 'package:libris_app/features/home/presentation/view/widgets/custom_appbar.dart';
import 'package:libris_app/features/home/presentation/view/widgets/featured_books_section.dart';
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
            sliver: FilterBookListView(),
          ),
        ],
      ),
    );
  }
}

class FilterBookListView extends StatelessWidget {
  const FilterBookListView({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 9),
          child: FilterBookItem(),
        );
      }, childCount: 10),
    );
  }
}

class FilterBookItem extends StatelessWidget {
  const FilterBookItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 120,
            width: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              image: const DecorationImage(
                image: AssetImage("assets/book.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "The Great Gatsby",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  "F. Scott Fitzgerald",
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: AppColors.accent, size: 18),
                    const SizedBox(width: 4),
                    const Text(
                      "5.0",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "(3000 reviews)",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
