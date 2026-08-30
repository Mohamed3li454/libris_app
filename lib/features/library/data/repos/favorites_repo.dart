import 'package:libris_app/core/models/book_model.dart';

abstract class FavoritesRepo {
  List<BookModel> getFavoriteBooks({String? collection});
  Future<void> addFavoriteBook(BookModel book);
  Future<void> removeFavoriteBook(String key);
  bool isBookFavorite(String key);
  Future<bool> toggleFavoriteBook(BookModel book);
  Future<void> updateBookCollection(String key, String collection);
  Future<void> updateBookProgress(String key, int progress);

  String exportFavoritesJson();
  Future<void> importFavoritesJson(String rawJson);
}
