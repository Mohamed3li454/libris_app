import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libris_app/constants/app_colors.dart';
import 'package:libris_app/core/services/search_history_service.dart';
import 'package:libris_app/core/utils/styles.dart';
import 'package:libris_app/core/widgets/custom_error_widget.dart';
import 'package:libris_app/features/library/data/repos/favorites_repo_impl.dart';
import 'package:libris_app/features/explore/presentation/manager/explore_cubit/explore_cubit.dart';
import 'package:libris_app/features/explore/presentation/view/widgets/custom_search_text_field.dart';
import 'package:libris_app/features/explore/presentation/view/widgets/explore_category_chips_list.dart';
import 'package:libris_app/features/explore/presentation/view/widgets/explore_empty_state.dart';
import 'package:libris_app/features/explore/presentation/view/widgets/explore_shimmer_loading.dart';
import 'package:libris_app/features/explore/presentation/view/widgets/explore_welcome_state.dart';
import 'package:libris_app/features/home/presentation/view/widgets/filter_book_item.dart';

class ExploreViewBody extends StatefulWidget {
  final String? initialQuery;

  const ExploreViewBody({super.key, this.initialQuery});

  @override
  State<ExploreViewBody> createState() => _ExploreViewBodyState();
}

class _ExploreViewBodyState extends State<ExploreViewBody>
    with AutomaticKeepAliveClientMixin {
  late final TextEditingController _searchController;
  late final ScrollController _resultsScrollController;
  String? _selectedCategory;
  List<String> _recentSearches = [];
  List<String> _recommendedAuthors = [];

  final List<String> _trendingSearches = const [
    'Atomic Habits',
    'Clean Code',
    'Dune',
    'Psychology',
    'Self Help',
  ];

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
    'Philosophy',
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _resultsScrollController = ScrollController()..addListener(_onScroll);
    _loadQuickSuggestions();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _executeInitialSearch(widget.initialQuery!);
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant ExploreViewBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialQuery != null &&
        widget.initialQuery!.isNotEmpty &&
        widget.initialQuery != oldWidget.initialQuery) {
      _executeInitialSearch(widget.initialQuery!);
    }
  }

  Future<void> _loadQuickSuggestions() async {
    final recent = await SearchHistoryService.getRecentSearches();
    final favoriteBooks = FavoritesRepoImpl().getFavoriteBooks();
    final authorSet = <String>{};
    for (final book in favoriteBooks) {
      final author = book.authorName.trim();
      if (author.isNotEmpty && author.toLowerCase() != 'unknown author') {
        authorSet.add(author);
      }
      if (authorSet.length >= 6) break;
    }
    if (!mounted) return;
    setState(() {
      _recentSearches = recent;
      _recommendedAuthors = authorSet.toList();
    });
  }

  Future<void> _clearRecentSearches() async {
    await SearchHistoryService.clearRecentSearches();
    if (!mounted) return;
    setState(() {
      _recentSearches = [];
    });
  }

  Future<void> _storeRecentQuery(String query) async {
    await SearchHistoryService.saveSearch(query);
    if (!mounted) return;
    final updated = await SearchHistoryService.getRecentSearches();
    if (!mounted) return;
    setState(() {
      _recentSearches = updated;
    });
  }

  void _onScroll() {
    if (!_resultsScrollController.hasClients) return;
    final position = _resultsScrollController.position;
    if (position.pixels >= position.maxScrollExtent - 220) {
      context.read<ExploreCubit>().loadMore();
    }
  }

  void _onSuggestionTap(String value) {
    _searchController.text = value;
    setState(() {
      _selectedCategory = null;
    });
    context.read<ExploreCubit>().searchBooks(value);
  }

  void _executeInitialSearch(String query) {
    if (query == 'trending_all' ||
        query == 'featured_all' ||
        query == 'trending') {
      _searchController.text = 'Featured for you';
      setState(() {
        _selectedCategory = null;
      });
      BlocProvider.of<ExploreCubit>(context).fetchTrendingBooks(limit: 50);
    } else {
      _searchController.text = query;
      setState(() {
        _selectedCategory = null;
      });
      BlocProvider.of<ExploreCubit>(context).searchBooks(query);
    }
  }

  @override
  void dispose() {
    _resultsScrollController.removeListener(_onScroll);
    _resultsScrollController.dispose();
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
    super.build(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'Explore',
              style: Styles.intelStyle.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Find books, browse genres, or search by author.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 14),

            Expanded(
              child: BlocConsumer<ExploreCubit, ExploreState>(
                listener: (context, state) {
                  if (state is ExploreSuccess &&
                      state.query != null &&
                      state.query!.isNotEmpty &&
                      state.query != 'Featured Books') {
                    _storeRecentQuery(state.query!);
                  }
                },
                builder: (context, state) {
                  if (state is ExploreLoading) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ExploreCategoryChipsList(
                          categories: categories,
                          selectedCategory: _selectedCategory,
                          onCategorySelected: _onCategorySelected,
                          onClearSelection: _clearSearch,
                        ),
                        const SizedBox(height: 14),
                        const Expanded(child: ExploreShimmerLoading()),
                      ],
                    );
                  } else if (state is ExploreSuccess) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ExploreCategoryChipsList(
                          categories: categories,
                          selectedCategory: _selectedCategory,
                          onCategorySelected: _onCategorySelected,
                          onClearSelection: _clearSearch,
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Row(
                            children: [
                              Text(
                                state.activeCategory != null
                                    ? '${state.activeCategory} Books'
                                    : state.query != null &&
                                            state.query!.isNotEmpty
                                        ? 'Results for "${state.query}"'
                                        : 'Results',
                                style: Styles.intelStyle.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${state.books.length} found',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: ListView.separated(
                            controller: _resultsScrollController,
                            padding: const EdgeInsets.only(bottom: 20),
                            physics: const BouncingScrollPhysics(),
                            itemCount: state.books.length + 1,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              if (index == state.books.length) {
                                if (state.isLoadingMore) {
                                  return const Center(
                                    child: Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 8),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  );
                                }
                                if (!state.hasMore) {
                                  return const SizedBox(height: 4);
                                }
                                return Center(
                                  child: TextButton(
                                    onPressed: () {
                                      context.read<ExploreCubit>().loadMore();
                                    },
                                    child: const Text('Load more'),
                                  ),
                                );
                              }
                              return FilterBookItem(
                                bookModel: state.books[index],
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  } else if (state is ExploreEmpty) {
                    return Column(
                      children: [
                        ExploreCategoryChipsList(
                          categories: categories,
                          selectedCategory: _selectedCategory,
                          onCategorySelected: _onCategorySelected,
                          onClearSelection: _clearSearch,
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: ExploreEmptyState(query: state.query),
                        ),
                      ],
                    );
                  } else if (state is ExploreFailure) {
                    return Column(
                      children: [
                        ExploreCategoryChipsList(
                          categories: categories,
                          selectedCategory: _selectedCategory,
                          onCategorySelected: _onCategorySelected,
                          onClearSelection: _clearSearch,
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: CustomErrorWidget(
                            errMessage: state.errMessage,
                            onRetry: () {
                              if (_searchController.text ==
                                  'Featured for you') {
                                BlocProvider.of<ExploreCubit>(
                                  context,
                                ).fetchTrendingBooks(limit: 50);
                              } else if (_searchController.text.isNotEmpty) {
                                BlocProvider.of<ExploreCubit>(
                                  context,
                                ).searchBooks(_searchController.text);
                              } else if (_selectedCategory != null) {
                                BlocProvider.of<ExploreCubit>(
                                  context,
                                ).fetchBooksBySubject(_selectedCategory!);
                              }
                            },
                          ),
                        ),
                      ],
                    );
                  } else {
                    return ExploreWelcomeState(
                      recentSearches: _recentSearches,
                      trendingSearches: _trendingSearches,
                      recommendedAuthors: _recommendedAuthors,
                      onSuggestionTap: _onSuggestionTap,
                      onCategorySelected: _onCategorySelected,
                      onClearRecentSearches: _recentSearches.isNotEmpty
                          ? _clearRecentSearches
                          : null,
                    );
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
