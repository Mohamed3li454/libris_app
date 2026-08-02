import 'package:flutter/material.dart';
import 'package:libris_app/constants/app_colors.dart';

class BookStatsCard extends StatelessWidget {
  const BookStatsCard({
    super.key,
    this.rating = 4.9,
    this.pageCount = 320,
    this.language = 'EN',
    this.downloads = '1.2k',
  });

  final double rating;
  final int pageCount;
  final String language;
  final String downloads;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: _buildStatItem(
                valueWidget: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFE5A624),
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C2416),
                      ),
                    ),
                  ],
                ),
                label: 'RATING',
              ),
            ),
            _buildDivider(),
            Expanded(
              child: _buildStatItem(
                value: '$pageCount',
                label: 'PAGES',
              ),
            ),
            _buildDivider(),
            Expanded(
              child: _buildStatItem(
                value: language,
                label: 'LANG',
              ),
            ),
            _buildDivider(),
            Expanded(
              child: _buildStatItem(
                value: downloads,
                label: 'DLS',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 28,
      color: AppColors.primary.withValues(alpha: 0.15),
    );
  }

  Widget _buildStatItem({
    String? value,
    Widget? valueWidget,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        valueWidget ??
            Text(
              value ?? '',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2416),
              ),
            ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.muted,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}
