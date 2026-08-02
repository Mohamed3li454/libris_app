import 'package:flutter/material.dart';
import 'package:libris_app/constants/app_colors.dart';

class BookDescriptionSection extends StatefulWidget {
  const BookDescriptionSection({
    super.key,
    this.title = 'About the Book',
    this.description =
        "In a city built on secrets and steam, Aurelia, a gifted alchemist's apprentice, discovers a forbidden manuscript detailing the creation of eternal gold. As powerful factions hunt her down, she must unravel the ancient mysteries before the empire falls into chaos and everything she holds dear is destroyed.",
    this.collapsedMaxLines = 3,
  });

  final String title;
  final String description;
  final int collapsedMaxLines;

  @override
  State<BookDescriptionSection> createState() =>
      _BookDescriptionSectionState();
}

class _BookDescriptionSectionState extends State<BookDescriptionSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Title
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2416),
            ),
          ),
          const SizedBox(height: 12),

          // Paragraph Content with expansion transition
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: Text(
              widget.description,
              maxLines: _isExpanded ? null : widget.collapsedMaxLines,
              overflow:
                  _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Color(0xFF625D52),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Read More / Read Less Clickable Action
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isExpanded ? 'Read Less' : 'Read More',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
