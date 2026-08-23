import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:libris_app/constants/app_colors.dart';
import 'package:libris_app/core/widgets/custom_error_widget.dart';
import 'package:libris_app/features/library/presentation/manager/library_cubit/library_cubit.dart';
import 'package:libris_app/features/library/presentation/view/widgets/empty_library_view.dart';
import 'package:libris_app/features/library/presentation/view/widgets/saved_books_grid_view.dart';

class LibraryViewBody extends StatefulWidget {
  const LibraryViewBody({super.key});

  @override
  State<LibraryViewBody> createState() => _LibraryViewBodyState();
}

class _LibraryViewBodyState extends State<LibraryViewBody> {
  Future<void> _showExportDialog(BuildContext context) async {
    final exportText = context.read<LibraryCubit>().exportFavoritesJson();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Library Backup'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(child: SelectableText(exportText)),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(dialogContext);
                await Clipboard.setData(ClipboardData(text: exportText));
                if (mounted) {
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Backup JSON copied.')),
                  );
                }
                if (!mounted) return;
                nav.pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Backup JSON copied.')),
                );
              },
              child: const Text('Copy'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showImportDialog(BuildContext context) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Import Library Backup'),
          content: TextField(
            controller: controller,
            maxLines: 10,
            decoration: const InputDecoration(
              hintText: 'Paste backup JSON here',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(dialogContext);
                try {
                  await context.read<LibraryCubit>().importFavoritesJson(
                    controller.text,
                  );
                  if (mounted) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Library imported successfully.'),
                      ),
                    );
                  }
                  if (!mounted) return;
                  nav.pop();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Library imported successfully.'),
                    ),
                  );
                } catch (_) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid backup JSON.')),
                    );
                  }
                  if (!mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Invalid backup JSON.')),
                  );
                }
              },
              child: const Text('Import'),
            ),
          ],
        );
      },
    );
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<LibraryCubit>();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Library',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Export backup',
                      onPressed: () => _showExportDialog(context),
                      icon: const Icon(
                        Icons.ios_share_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Import backup',
                      onPressed: () => _showImportDialog(context),
                      icon: const Icon(
                        Icons.file_download_done_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Your saved books, active reading lists, and bookmarks.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: LibraryCubit.collections.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final collection = LibraryCubit.collections[index];
                  final isSelected = cubit.selectedCollection == collection;
                  return ChoiceChip(
                    label: Text(collection),
                    selected: isSelected,
                    onSelected: (_) {
                      context.read<LibraryCubit>().setCollectionFilter(
                        collection,
                      );
                    },
                    selectedColor: const Color(0xFFFBE2AC),
                    backgroundColor: const Color(0xFFEBEAE4),
                    side: BorderSide.none,
                    labelStyle: TextStyle(
                      color: const Color(0xFF2C2C2C),
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: BlocBuilder<LibraryCubit, LibraryState>(
                builder: (context, state) {
                  if (state is LibraryLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is LibrarySuccess) {
                    return SavedBooksGridView(
                      books: state.books,
                      onMoveToCollection: (key, collection) {
                        context.read<LibraryCubit>().moveBookToCollection(
                          key,
                          collection,
                        );
                      },
                    );
                  } else if (state is LibraryFailure) {
                    return CustomErrorWidget(
                      errMessage: state.errMessage,
                      onRetry: () {
                        BlocProvider.of<LibraryCubit>(
                          context,
                        ).fetchFavoriteBooks();
                      },
                    );
                  } else {
                    return EmptyLibraryView(
                      message:
                          'No books in "${context.read<LibraryCubit>().selectedCollection}" yet.',
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
