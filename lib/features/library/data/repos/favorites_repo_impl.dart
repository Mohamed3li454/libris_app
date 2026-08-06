import 'package:hive_flutter/hive_flutter.dart';
import 'package:libris_app/constants/hive_constants.dart';
import 'package:libris_app/core/models/book_model.dart';
import 'package:libris_app/features/library/data/repos/favorites_repo.dart';

class FavoritesRepoImpl implements FavoritesRepo {
  Box get _box => Hive.box(kFavoritesBox);

  @override
  List<BookModel> getFavoriteBooks() {
    try {
      final List<BookModel> books = [];
      for (var key in _box.keys) {
        final item = _box.get(key);
        if (item != null) {
          books.add(BookModel.fromJson(Map<String, dynamic>.from(item as Map)));
        }
      }
      return books;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> addFavoriteBook(BookModel book) async {
    await _box.put(book.key, book.toJson());
  }

  @override
  Future<void> removeFavoriteBook(String key) async {
    await _box.delete(key);
  }

  @override
  bool isBookFavorite(String key) {
    return _box.containsKey(key);
  }

  @override
  Future<bool> toggleFavoriteBook(BookModel book) async {
    if (isBookFavorite(book.key)) {
      await removeFavoriteBook(book.key);
      return false;
    } else {
      await addFavoriteBook(book);
      return true;
    }
  }
}
