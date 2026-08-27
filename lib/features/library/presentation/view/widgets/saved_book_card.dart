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
                  Text('${value.round()}%'),
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

  @override
  Widget build(BuildContext context) {
    final progress = (bookModel.progress ?? 0).clamp(0, 100);
    final isReading = (bookModel.collection ?? 'Favorites') == 'Reading';

    return GestureDetector(
      onTap: () async {
        await GoRouter.of(context).push('/details', extra: bookModel);
        if (context.mounted) {
          context.read<LibraryCubit>().fetchFavoriteBooks();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: context.isDark ? 0.35 : 0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 3 / 4,
                      child: bookModel.coverUrl.isEmpty
                          ? Container(
                              color: context.pillColor,
                              child: Icon(
                                Icons.menu_book_rounded,
                                color: context.mutedColor,
                                size: 36,
                              ),
                            )
                          : CachedNetworkImage(
                              imageUrl: bookModel.coverUrl,
                              fit: BoxFit.fill,
                              placeholder: (context, url) => Container(
                                color: context.pillColor,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: context.pillColor,
                                child: Icon(
                                  Icons.menu_book_rounded,
                                  color: context.mutedColor,
                                  size: 36,
                                ),
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        bookModel.collection ?? 'Favorites',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Row(
                      children: [
                        PopupMenuButton<String>(
                          tooltip: 'Move to collection',
                          onSelected: (value) {
                            onCollectionSelected?.call(value);
                          },
                          itemBuilder: (context) => [
                            for (final collection
                                in LibraryCubit.movableCollections)
                              PopupMenuItem(
                                value: collection,
                                child: Text(collection),
                              ),
                          ],
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.drive_file_move_outline,
                              color: Colors.white,
                              size: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 1),
                        GestureDetector(
                          onTap: () {
                            context.read<LibraryCubit>().removeFavoriteBook(
                              bookModel.key,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.bookmark_remove_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    bookModel.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: context.titleColor,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    bookModel.authorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.mutedColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 12,
                        color: context.mutedColor,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        bookModel.firstPublishYear != null
                            ? '${bookModel.firstPublishYear}'
                            : 'N/A',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: context.mutedColor,
                        ),
                      ),
                    ],
                  ),
                  if (isReading) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _editProgress(context),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(
                            value: progress / 100,
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$progress% · tap to update',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: context.colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
