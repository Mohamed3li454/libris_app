import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:libris_app/core/models/book_model.dart';
import 'package:libris_app/core/theme/app_theme.dart';
import 'package:libris_app/features/library/presentation/manager/library_cubit/library_cubit.dart';
import 'package:libris_app/features/library/presentation/view/widgets/book_notes_dialog.dart';

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

  Future<void> _editNotes(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => BookNotesDialog(
        initialNotes: bookModel.notes ?? '',
      ),
    );

    if (result != null && context.mounted) {
      await context.read<LibraryCubit>().updateBookNotes(
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
    final hasNotes =
        bookModel.notes != null && bookModel.notes!.trim().isNotEmpty;

    return Container(
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
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
            child: GestureDetector(
              onTap: () => _openDetails(context),
              child: Stack(
                children: [
                  Hero(
                    tag: bookModel.coverHeroTag,
                    child: ClipRRect(
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
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: context.pillColor,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) =>
                                    Container(
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
                  ),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        bookModel.collection ?? 'Favorites',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                PopupMenuButton<String>(
                  tooltip: 'Move to collection',
                  padding: EdgeInsets.zero,
                  onSelected: (value) => onCollectionSelected?.call(value),
                  itemBuilder: (context) => [
                    for (final collection in LibraryCubit.movableCollections)
                      PopupMenuItem(
                        value: collection,
                        child: Text(collection),
                      ),
                  ],
                  child: _CardAction(
                    icon: Icons.drive_file_move_outline,
                    color: context.colors.primary,
                  ),
                ),
                _CardAction(
                  icon: hasNotes
                      ? Icons.note_alt_rounded
                      : Icons.note_add_outlined,
                  color: hasNotes
                      ? context.colors.primary
                      : context.mutedColor,
                  onTap: () => _editNotes(context),
                ),
                _CardAction(
                  icon: Icons.bookmark_remove_rounded,
                  color: const Color(0xFFB42318),
                  onTap: () {
                    context.read<LibraryCubit>().removeFavoriteBook(
                      bookModel.key,
                    );
                  },
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _openDetails(context),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
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
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: progress / 100),
                            duration: const Duration(milliseconds: 420),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, _) {
                              return LinearProgressIndicator(
                                value: value,
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(8),
                              );
                            },
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
          ),
        ],
      ),
    );
  }
}

class _CardAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _CardAction({
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
