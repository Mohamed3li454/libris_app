import 'package:flutter/material.dart';
import 'package:libris_app/core/models/book_model.dart';
import 'package:libris_app/features/library/presentation/view/widgets/saved_book_card.dart';

class SavedBooksGridView extends StatelessWidget {
  final List<BookModel> books;

  const SavedBooksGridView({super.key, required this.books});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        return SavedBookCard(bookModel: books[index]);
      },
    );
  }
}
