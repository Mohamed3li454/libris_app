import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:libris_app/core/theme/app_theme.dart';
import 'package:libris_app/core/utils/styles.dart';
import 'package:libris_app/features/home/presentation/manager/featured_books_cubit/featured_books_cubit.dart';
import 'package:libris_app/features/home/presentation/manager/filter_books_cubit/filter_books_cubit.dart';
import 'package:libris_app/features/home/presentation/view/widgets/custom_appbar.dart';
import 'package:libris_app/features/home/presentation/view/widgets/featured_books_section.dart';
import 'package:libris_app/features/home/presentation/view/widgets/filter_book_sliver_list_view.dart';
import 'package:libris_app/features/home/presentation/view/widgets/filter_chips_list.dart';
import 'package:libris_app/features/main/presentation/view/main_navigation_view.dart';

class HomeViewBody extends StatelessWidget {
  const HomeViewBody({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        color: context.colors.primary,
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
                      style: Styles.interStyle.copyWith(
                        color: context.colors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 32,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Search',
                          onPressed: () {
                            MainNavigationView.of(context)?.navigateToExplore();
                          },
                          icon: Icon(
                            Icons.search_rounded,
                            color: context.colors.primary,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Settings',
                          onPressed: () => context.push('/settings'),
                          icon: Icon(
                            Icons.settings_outlined,
                            color: context.colors.primary,
                          ),
                        ),
                      ],
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
