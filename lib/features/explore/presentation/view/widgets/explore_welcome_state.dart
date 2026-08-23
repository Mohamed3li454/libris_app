import 'package:flutter/material.dart';
import 'package:libris_app/constants/app_colors.dart';
import 'package:libris_app/features/explore/presentation/view/widgets/explore_genres_grid.dart';

class ExploreWelcomeState extends StatelessWidget {
  final List<String> recentSearches;
  final List<String> trendingSearches;
  final List<String> recommendedAuthors;
  final ValueChanged<String> onSuggestionTap;
  final ValueChanged<String> onCategorySelected;
  final VoidCallback? onClearRecentSearches;

  const ExploreWelcomeState({
    super.key,
    required this.recentSearches,
    required this.trendingSearches,
    required this.recommendedAuthors,
    required this.onSuggestionTap,
    required this.onCategorySelected,
    this.onClearRecentSearches,
  });

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    Color? iconColor,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor ?? AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF3B2F15),
            letterSpacing: 0.1,
          ),
        ),
        const Spacer(),
        ?trailing,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),

          // 1. Recent Searches
          if (recentSearches.isNotEmpty) ...[
            _buildSectionHeader(
              icon: Icons.history_rounded,
              title: 'Recent Searches',
              trailing: onClearRecentSearches != null
                  ? GestureDetector(
                      onTap: onClearRecentSearches,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Text(
                          'Clear',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: recentSearches
                  .map(
                    (query) => Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onSuggestionTap(query),
                        borderRadius: BorderRadius.circular(10),
                        child: Ink(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3EFE6),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFE5DDD0),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search_rounded,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                query,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF2C2416),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 22),
          ],

          // 2. Trending Searches
          if (trendingSearches.isNotEmpty) ...[
            _buildSectionHeader(
              icon: Icons.local_fire_department_rounded,
              iconColor: const Color(0xFFEA580C),
              title: 'Trending Searches',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: trendingSearches
                  .map(
                    (topic) => Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onSuggestionTap(topic),
                        borderRadius: BorderRadius.circular(10),
                        child: Ink(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF5E9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFEADBBE),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                '#',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                topic,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF3D321D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],

          // 3. Browse Genres Grid
          _buildSectionHeader(
            icon: Icons.grid_view_rounded,
            title: 'Browse Genres',
          ),
          const SizedBox(height: 12),
          ExploreGenresGrid(onGenreSelected: onCategorySelected),
          const SizedBox(height: 24),

          // 4. Authors From Library
          if (recommendedAuthors.isNotEmpty) ...[
            _buildSectionHeader(
              icon: Icons.draw_rounded,
              title: 'Authors in Your Library',
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: recommendedAuthors.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final author = recommendedAuthors[index];
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onSuggestionTap(author),
                      borderRadius: BorderRadius.circular(24),
                      child: Ink(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3EFE6),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFFE5DDD0),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE0D5BE),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              author,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2C2416),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
