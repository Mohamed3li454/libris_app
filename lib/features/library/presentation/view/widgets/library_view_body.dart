import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libris_app/core/theme/app_theme.dart';
import 'package:libris_app/core/widgets/custom_error_widget.dart';
import 'package:libris_app/features/library/presentation/manager/library_cubit/library_cubit.dart';
import 'package:libris_app/features/library/presentation/view/widgets/empty_library_view.dart';
import 'package:libris_app/features/library/presentation/view/widgets/saved_books_grid_view.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class LibraryViewBody extends StatefulWidget {
  const LibraryViewBody({super.key});

  @override
  State<LibraryViewBody> createState() => _LibraryViewBodyState();
}

class _LibraryViewBodyState extends State<LibraryViewBody> {
  Future<void> _exportBackup() async {
    final exportText = context.read<LibraryCubit>().exportFavoritesJson();
    try {
      if (kIsWeb) {
        await SharePlus.instance.share(
          ShareParams(text: exportText, title: 'Libris library backup'),
        );
        return;
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/libris_library_backup.json');
      await file.writeAsString(exportText);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/json')],
          title: 'Libris library backup',
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not export library backup.')),
      );
    }
  }

  Future<void> _importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final picked = result.files.first;
      final content = picked.bytes != null
          ? utf8.decode(picked.bytes!)
          : (picked.path != null ? await File(picked.path!).readAsString() : '');

      if (content.trim().isEmpty) {
        throw const FormatException('Empty file');
      }

      if (!mounted) return;
      await context.read<LibraryCubit>().importFavoritesJson(content);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Library imported successfully.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid backup file.')),
      );
    }
  }

  String _sortLabel(LibrarySort sort) {
    switch (sort) {
      case LibrarySort.recent:
        return 'Recently added';
      case LibrarySort.title:
        return 'Title';
      case LibrarySort.year:
        return 'Year';
    }
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
                Text(
                  'My Library',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: context.colors.primary,
                  ),
                ),
                Row(
                  children: [
                    PopupMenuButton<LibrarySort>(
                      tooltip: 'Sort',
                      initialValue: cubit.selectedSort,
                      onSelected: (value) {
                        context.read<LibraryCubit>().setSort(value);
                      },
                      itemBuilder: (context) => [
                        for (final sort in LibrarySort.values)
                          PopupMenuItem(
                            value: sort,
                            child: Text(_sortLabel(sort)),
                          ),
                      ],
                      icon: Icon(
                        Icons.sort_rounded,
                        color: context.colors.primary,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Export backup',
                      onPressed: _exportBackup,
                      icon: Icon(
                        Icons.ios_share_rounded,
                        color: context.colors.primary,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Import backup',
                      onPressed: _importBackup,
                      icon: Icon(
                        Icons.file_download_done_rounded,
                        color: context.colors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Your saved books, reading lists, and bookmarks.',
              style: TextStyle(fontSize: 14, color: context.mutedColor),
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
                  final count = cubit.collectionCounts[collection] ?? 0;
                  return ChoiceChip(
                    label: Text('$collection ($count)'),
                    selected: isSelected,
                    onSelected: (_) {
                      context.read<LibraryCubit>().setCollectionFilter(
                        collection,
                      );
                    },
                    selectedColor: context.pillColor,
                    backgroundColor: context.isDark
                        ? const Color(0xFF2A241C)
                        : const Color(0xFFEBEAE4),
                    side: BorderSide.none,
                    labelStyle: TextStyle(
                      color: context.titleColor,
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
                        context.read<LibraryCubit>().fetchFavoriteBooks();
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
