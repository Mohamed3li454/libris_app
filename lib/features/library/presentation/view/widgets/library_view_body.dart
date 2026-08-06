import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libris_app/constants/app_colors.dart';
import 'package:libris_app/core/widgets/custom_error_widget.dart';
import 'package:libris_app/features/library/presentation/manager/library_cubit/library_cubit.dart';
import 'package:libris_app/features/library/presentation/view/widgets/empty_library_view.dart';
import 'package:libris_app/features/library/presentation/view/widgets/saved_books_grid_view.dart';

class LibraryViewBody extends StatelessWidget {
  const LibraryViewBody({super.key});

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
              'My Library',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your saved books, active reading lists, and bookmarks.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: BlocBuilder<LibraryCubit, LibraryState>(
                builder: (context, state) {
                  if (state is LibraryLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is LibrarySuccess) {
                    return SavedBooksGridView(books: state.books);
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
                    return const EmptyLibraryView();
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
