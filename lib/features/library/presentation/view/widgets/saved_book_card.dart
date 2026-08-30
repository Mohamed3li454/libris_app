import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:libris_app/core/models/book_model.dart';
import 'package:libris_app/core/theme/app_theme.dart';
import 'package:libris_app/features/library/presentation/manager/library_cubit/library_cubit.dart';

class SavedBookCard extends StatelessWidget {
  final BookModel bookModel;
  final ValueChanged<String>? onCollectionSelected;

  const SavedBookCard({
    super.key,
    required this.bookModel,
    this.onCollectionSelected,
  });

  Future<void> _editProgress(BuildContext context) async {
    var value = (bookModel.progress ?? 0).clamp(0, 100).toDouble();
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reading progress'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${value.round()}%',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Slider(
                    value: value,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    label: '${value.round()}%',
                    onChanged: (next) {
                      setState(() {
                        value = next;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, value.round()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != null && context.mounted) {
      await context.read<LibraryCubit>().updateBookProgress(
        bookModel.key,
        result,
      );
    }
  }

  Future<void> _openDetails(BuildContext context) async {
    await GoRouter.of(context).push('/details', extra: bookModel);
    if (context.mounted) {
      context.read<LibraryCubit>().fetchFavoriteBooks();
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (bookModel.progress ?? 0).clamp(0, 100);
    final isReading = (bookModel.collection ?? 'Favorites') == 'Reading';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.30 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openDetails(context),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover image with overlaid collection badge and actions menu
                Stack(
                  children: [
                    Hero(
                      tag: bookModel.coverHeroTag,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: 1 / 1.38,
                          child: Container(
                            color: context.pillColor,
                            child: bookModel.coverUrl.isEmpty
                                ? Icon(
                                    Icons.menu_book_rounded,
                                    color: context.mutedColor,
                                    size: 32,
                                  )
                                : CachedNetworkImage(
                                    imageUrl: bookModel.coverUrl,
                                    fit: BoxFit.fill,
                                    placeholder: (context, url) => Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: context.colors.primary,
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Icon(
                                      Icons.menu_book_rounded,
                                      color: context.mutedColor,
                                      size: 32,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    // Collection badge
                    Positioned(
                      left: 6,
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.70),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          bookModel.collection ?? 'Favorites',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                    // Options menu button (Move to collection / Remove)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: PopupMenuButton<String>(
                        tooltip: 'Options',
                        padding: EdgeInsets.zero,
                        elevation: 6,
                        constraints: const BoxConstraints(),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        color: context.isDark
                            ? const Color(0xFF28231A)
                            : Colors.white,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.more_vert_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                          onSelected: (value) {
                            if (value == 'remove') {
                              context.read<LibraryCubit>().removeFavoriteBook(
                                bookModel.key,
                              );
                            } else {
                              onCollectionSelected?.call(value);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem<String>(
                              enabled: false,
                              height: 26,
                              child: Text(
                                'MOVE TO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                  color: context.mutedColor,
                                ),
                              ),
                            ),
                            for (final col
                                in LibraryCubit.movableCollections)
                              PopupMenuItem<String>(
                                value: col,
                                height: 36,
                                child: Row(
                                  children: [
                                    Icon(
                                      col ==
                                              (bookModel.collection ??
                                                  'Favorites')
                                          ? Icons.radio_button_checked_rounded
                                          : Icons
                                              .radio_button_unchecked_rounded,
                                      size: 16,
                                      color: col ==
                                              (bookModel.collection ??
                                                  'Favorites')
                                          ? context.colors.primary
                                          : context.mutedColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      col,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: col ==
                                                (bookModel.collection ??
                                                    'Favorites')
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        color: context.titleColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const PopupMenuDivider(),
                            const PopupMenuItem<String>(
                              value: 'remove',
                              height: 38,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.bookmark_remove_rounded,
                                    size: 18,
                                    color: Color(0xFFE53935),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Remove from Library',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFFE53935),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                // Book details
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        bookModel.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: context.titleColor,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        bookModel.authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: context.mutedColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (isReading)
                        GestureDetector(
                          onTap: () => _editProgress(context),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Progress',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: context.mutedColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '$progress%',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: context.colors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress / 100,
                                  minHeight: 5,
                                  backgroundColor: context.pillColor,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    context.colors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 11,
                              color: context.mutedColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              bookModel.firstPublishYear != null
                                  ? '${bookModel.firstPublishYear}'
                                  : 'N/A',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: context.mutedColor,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
