import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libris_app/constants/app_colors.dart';
import 'package:libris_app/core/widgets/custom_error_widget.dart';
import 'package:libris_app/features/explore/presentation/manager/explore_cubit/explore_cubit.dart';
import 'package:libris_app/features/explore/presentation/view/widgets/custom_search_text_field.dart';
import 'package:libris_app/features/explore/presentation/view/widgets/explore_category_chips_list.dart';
import 'package:libris_app/features/explore/presentation/view/widgets/explore_empty_state.dart';
import 'package:libris_app/features/explore/presentation/view/widgets/explore_shimmer_loading.dart';
import 'package:libris_app/features/explore/presentation/view/widgets/explore_welcome_state.dart';
import 'package:libris_app/features/home/presentation/view/widgets/filter_book_item.dart';

class ExploreViewBody extends StatefulWidget {
  const ExploreViewBody({super.key});

  @override
  State<ExploreViewBody> createState() => _ExploreViewBodyState();
}

class _ExploreViewBodyState extends State<ExploreViewBody> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;

  final List<String> categories = const [
    'Fiction',
    'Programming',
    'History',
    'Science',
    'Fantasy',
    'Self-Help',
    'Business',
    'Mystery',
    'Romance',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      _searchController.clear();
    });
    BlocProvider.of<ExploreCubit>(context).fetchBooksBySubject(category);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _selectedCategory = null;
    });
    BlocProvider.of<ExploreCubit>(context).resetSearch();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Explore',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Discover new genres, authors, or search any book.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),
            CustomSearchTextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _selectedCategory = null;
                });
                BlocProvider.of<ExploreCubit>(
                  context,
                ).searchBooksDebounced(value);
              },
              onClear: _clearSearch,
            ),
            const SizedBox(height: 16),
            ExploreCategoryChipsList(
              categories: categories,
              selectedCategory: _selectedCategory,
              onCategorySelected: _onCategorySelected,
              onClearSelection: _clearSearch,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BlocBuilder<ExploreCubit, ExploreState>(
                builder: (context, state) {
                  if (state is ExploreLoading) {
                    return const ExploreShimmerLoading();
                  } else if (state is ExploreSuccess) {
                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 20),
                      physics: const BouncingScrollPhysics(),
                      itemCount: state.books.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return FilterBookItem(bookModel: state.books[index]);
                      },
                    );
                  } else if (state is ExploreEmpty) {
                    return ExploreEmptyState(query: state.query);
                  } else if (state is ExploreFailure) {
                    return CustomErrorWidget(
                      errMessage: state.errMessage,
                      onRetry: () {
                        if (_searchController.text.isNotEmpty) {
                          BlocProvider.of<ExploreCubit>(
                            context,
                          ).searchBooks(_searchController.text);
                        } else if (_selectedCategory != null) {
                          BlocProvider.of<ExploreCubit>(
                            context,
                          ).fetchBooksBySubject(_selectedCategory!);
                        }
                      },
                    );
                  } else {
                    return const ExploreWelcomeState();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
