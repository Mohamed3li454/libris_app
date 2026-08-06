import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libris_app/constants/app_colors.dart';
import 'package:libris_app/features/explore/presentation/manager/explore_cubit/explore_cubit.dart';
import 'package:libris_app/features/home/presentation/view/widgets/filter_book_item.dart';
import 'package:shimmer/shimmer.dart';

class ExploreView extends StatelessWidget {
  const ExploreView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ExploreCubit(),
      child: const ExploreViewContent(),
    );
  }
}

class ExploreViewContent extends StatefulWidget {
  const ExploreViewContent({super.key});

  @override
  State<ExploreViewContent> createState() => _ExploreViewContentState();
}

class _ExploreViewContentState extends State<ExploreViewContent> {
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

            // Dynamic Search Input Bar
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3EFE6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5DDD0)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = null;
                  });
                  BlocProvider.of<ExploreCubit>(
                    context,
                  ).searchBooksDebounced(value);
                },
                decoration: InputDecoration(
                  hintText: 'Search books, authors, or genres...',
                  hintStyle: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.secondary,
                  ),
                  suffixIcon:
                      _searchController.text.isNotEmpty
                          ? IconButton(
                            icon: const Icon(
                              Icons.clear_rounded,
                              color: AppColors.muted,
                            ),
                            onPressed: _clearSearch,
                          )
                          : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Category Chips List
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = _selectedCategory == category;
                  return ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    selectedColor: const Color(0xFFFBE2AC),
                    backgroundColor: const Color(0xFFEBEAE4),
                    side: BorderSide.none,
                    labelStyle: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: const Color(0xFF2C2C2C),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        _onCategorySelected(category);
                      } else {
                        _clearSearch();
                      }
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Search & Explore Content Area
            Expanded(
              child: BlocBuilder<ExploreCubit, ExploreState>(
                builder: (context, state) {
                  if (state is ExploreLoading) {
                    return _buildLoadingShimmer();
                  } else if (state is ExploreSuccess) {
                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 20),
                      physics: const BouncingScrollPhysics(),
                      itemCount: state.books.length,
                      separatorBuilder:
                          (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return FilterBookItem(bookModel: state.books[index]);
                      },
                    );
                  } else if (state is ExploreEmpty) {
                    return _buildEmptyState(state.query);
                  } else if (state is ExploreFailure) {
                    return _buildFailureState(state.errMessage);
                  } else {
                    return _buildInitialWelcomeState();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialWelcomeState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFE8DFC8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_outlined,
              size: 44,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Search Any Book or Genre',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Type a book name above or select a category to start exploring.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String query) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 44,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No books found for "$query"',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2416),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check for spelling errors or try searching with a different keyword.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildFailureState(String errMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(
            errMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      itemCount: 6,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 120,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 60,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
