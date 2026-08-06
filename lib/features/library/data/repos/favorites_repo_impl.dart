import 'package:flutter/foundation.dart';
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
        if (item != null && item is Map) {
          books.add(BookModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
      return books;
    } catch (e) {
      debugPrint('Error loading favorite books: $e');
      return [];
    }
  }

  @override
  Future<void> addFavoriteBook(BookModel book) async {
    try {
      await _box.put(book.key, book.toJson());
    } catch (e) {
      debugPrint('Error saving favorite book: $e');
    }
  }

  @override
  Future<void> removeFavoriteBook(String key) async {
    try {
      await _box.delete(key);
    } catch (e) {
      debugPrint('Error removing favorite book: $e');
    }
  }

  @override
  bool isBookFavorite(String key) {
    try {
      return _box.containsKey(key);
    } catch (e) {
      debugPrint('Error checking favorite status: $e');
      return false;
    }
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
