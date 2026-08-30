import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:libris_app/constants/hive_constants.dart';
import 'package:libris_app/core/models/book_model.dart';
import 'package:libris_app/features/library/data/repos/favorites_repo.dart';

class FavoritesRepoImpl implements FavoritesRepo {
  static const String defaultCollection = 'Favorites';
  Box get _box => Hive.box(kFavoritesBox);

  @override
  List<BookModel> getFavoriteBooks({String? collection}) {
    try {
      final List<BookModel> books = [];
      for (var key in _box.keys) {
        final item = _box.get(key);
        if (item != null && item is Map) {
          final map = Map<String, dynamic>.from(item);
          final itemCollection =
              (map['collection'] as String?) ?? defaultCollection;
          if (collection == null ||
              collection == 'All' ||
              itemCollection == collection) {
            books.add(BookModel.fromJson(map));
          }
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
      final payload = Map<String, dynamic>.from(book.toJson());
      payload['collection'] = payload['collection'] ?? defaultCollection;
      payload['added_at'] =
          payload['added_at'] ?? DateTime.now().millisecondsSinceEpoch;
      payload['progress'] = payload['progress'] ?? 0;
      await _box.put(book.key, payload);
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

  @override
  Future<void> updateBookCollection(String key, String collection) async {
    try {
      final item = _box.get(key);
      if (item is Map) {
        final payload = Map<String, dynamic>.from(item);
        payload['collection'] = collection;
        await _box.put(key, payload);
      }
    } catch (e) {
      debugPrint('Error updating collection: $e');
    }
  }

  @override
  Future<void> updateBookProgress(String key, int progress) async {
    try {
      final item = _box.get(key);
      if (item is Map) {
        final payload = Map<String, dynamic>.from(item);
        final clamped = progress.clamp(0, 100);
        payload['progress'] = clamped;
        if (clamped >= 100) {
          payload['collection'] = 'Finished';
        }
        await _box.put(key, payload);
      }
    } catch (e) {
      debugPrint('Error updating progress: $e');
    }
  }


  @override
  String exportFavoritesJson() {
    try {
      final Map<String, dynamic> exportMap = {};
      for (var key in _box.keys) {
        final item = _box.get(key);
        if (item is Map) {
          final payload = Map<String, dynamic>.from(item);
          payload['collection'] =
              (payload['collection'] as String?) ?? defaultCollection;
          exportMap[key.toString()] = payload;
        }
      }
      return const JsonEncoder.withIndent('  ').convert(exportMap);
    } catch (e) {
      debugPrint('Error exporting favorites: $e');
      return '{}';
    }
  }

  @override
  Future<void> importFavoritesJson(String rawJson) async {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map) return;

      for (final entry in decoded.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        if (value is Map) {
          final payload = Map<String, dynamic>.from(value);
          payload['key'] = payload['key'] ?? key;
          payload['collection'] =
              (payload['collection'] as String?) ?? defaultCollection;
          await _box.put(key, payload);
        }
      }
    } catch (e) {
      debugPrint('Error importing favorites: $e');
      rethrow;
    }
  }
}
