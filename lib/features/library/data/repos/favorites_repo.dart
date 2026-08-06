import 'package:libris_app/core/models/book_model.dart';

abstract class FavoritesRepo {
  List<BookModel> getFavoriteBooks();
  Future<void> addFavoriteBook(BookModel book);
  Future<void> removeFavoriteBook(String key);
  bool isBookFavorite(String key);
  Future<bool> toggleFavoriteBook(BookModel book);
}
