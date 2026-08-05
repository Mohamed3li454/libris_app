import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libris_app/constants/app_colors.dart';
import 'package:libris_app/core/utils/styles.dart';
import 'package:libris_app/features/home/presentation/manager/featured%20books%20cubit/featured_books_cubit.dart';
import 'package:libris_app/features/home/presentation/manager/filter_books_cubit/filter_books_cubit.dart';
import 'package:libris_app/features/home/presentation/view/widgets/custom_appbar.dart';
import 'package:libris_app/features/home/presentation/view/widgets/featured_books_section.dart';
import 'package:libris_app/features/home/presentation/view/widgets/filter_book_sliver_list_view.dart';
import 'package:libris_app/features/home/presentation/view/widgets/filter_chips_list.dart';

class HomeViewBody extends StatelessWidget {
  const HomeViewBody({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          final featuredCubit = BlocProvider.of<FeaturedBooksCubit>(context);
          final filterCubit = BlocProvider.of<FilterBooksCubit>(context);

          await Future.wait([
            featuredCubit.fetchFeaturedBooks(),
            filterCubit.fetchFilterBooks(
              category: filterCubit.currentCategory,
            ),
          ]);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
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
      ),
    );
  }
}
