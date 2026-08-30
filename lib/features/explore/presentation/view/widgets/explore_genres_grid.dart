import 'package:flutter/material.dart';
import 'package:libris_app/constants/app_colors.dart';

class GenreItemData {
  final String title;
  final IconData icon;

  const GenreItemData({required this.title, required this.icon});
}

class ExploreGenresGrid extends StatelessWidget {
  final ValueChanged<String> onGenreSelected;

  const ExploreGenresGrid({super.key, required this.onGenreSelected});

  static const List<GenreItemData> genres = [
    GenreItemData(title: 'Fiction', icon: Icons.auto_stories_rounded),
    GenreItemData(title: 'Programming', icon: Icons.code_rounded),
    GenreItemData(title: 'History', icon: Icons.account_balance_rounded),
    GenreItemData(title: 'Science', icon: Icons.science_rounded),
    GenreItemData(title: 'Fantasy', icon: Icons.auto_fix_high_rounded),
    GenreItemData(title: 'Self-Help', icon: Icons.psychology_rounded),
    GenreItemData(title: 'Business', icon: Icons.trending_up_rounded),
    GenreItemData(title: 'Mystery', icon: Icons.travel_explore_rounded),
    GenreItemData(title: 'Romance', icon: Icons.favorite_rounded),
    GenreItemData(title: 'Philosophy', icon: Icons.lightbulb_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.4,
      ),
      itemCount: genres.length,
      itemBuilder: (context, index) {
        final genre = genres[index];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onGenreSelected(genre.title),
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.lightOutline, width: 1.5),
                color: const Color.fromARGB(210, 246, 245, 243),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8DFC8),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        genre.icon,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        genre.title,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C2C2C),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: AppColors.primary.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
