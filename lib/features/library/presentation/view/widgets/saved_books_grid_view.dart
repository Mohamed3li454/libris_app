import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:libris_app/core/models/book_model.dart';
import 'package:libris_app/features/library/presentation/view/widgets/saved_book_card.dart';

class SavedBooksGridView extends StatelessWidget {
  final List<BookModel> books;

  const SavedBooksGridView({super.key, required this.books});

  @override
  Widget build(BuildContext context) {
    return MasonryGridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.only(bottom: 20),
      physics: const BouncingScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      itemCount: books.length,
      itemBuilder: (context, index) {
        return SavedBookCard(bookModel: books[index]);
      },
    );
  }
}
