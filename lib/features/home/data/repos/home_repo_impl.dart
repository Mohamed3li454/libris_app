import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:libris_app/constants/hive_constants.dart';
import 'package:libris_app/core/errors/failure.dart';
import 'package:libris_app/core/models/book_model.dart';
import 'package:libris_app/core/utils/api_service.dart';
import 'package:libris_app/features/home/data/repos/home_repo.dart';

class HomeRepoImpl implements HomeRepo {
  final ApiService apiService;
  static const Duration _cacheTtl = Duration(hours: 8);

  HomeRepoImpl({required this.apiService});

  bool _isCacheValid(int? timestamp) {
    if (timestamp == null) return false;
    final cachedAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now().difference(cachedAt) <= _cacheTtl;
  }

  Future<void> _writeCachedList(Box box, String key, List rawList) async {
    await box.put(key, {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'items': rawList,
    });
  }

  List<BookModel> _readCachedBooks(Box box, String key) {
    if (!box.containsKey(key)) return [];
    final cached = box.get(key);

    List<dynamic>? rawItems;
    if (cached is Map) {
      final timestamp = cached['timestamp'] as int?;
      if (!_isCacheValid(timestamp)) return [];
      final items = cached['items'];
      if (items is List) rawItems = items;
    } else if (cached is List) {
      // Backward compatibility with old cache shape.
      rawItems = cached;
    }

    if (rawItems == null || rawItems.isEmpty) return [];

    return rawItems
        .map((item) => BookModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<Either<Failure, List<BookModel>>> fetchFeaturedBooks() async {
    final box = Hive.box(kFeaturedBox);
    try {
      final data = await apiService.getData(
        endPoint: "trending/weekly.json?limit=20",
      );
      final bookResponse = BookResponseModel.fromJson(data);
      final List rawList = data['works'] ?? data['docs'] ?? [];
      await _writeCachedList(box, 'featured_list_eng', rawList);
      return right(bookResponse.books);
    } catch (e) {
      try {
        final cachedBooks = _readCachedBooks(box, 'featured_list_eng');
        if (cachedBooks.isNotEmpty) {
          return right(cachedBooks);
        }
      } catch (_) {
        // Fallback to network failure below when cache parse fails.
      }

      if (e is Failure) return left(e);
      if (e is DioException) return left(ServerFailure.fromDioError(e));
      if (e is FormatException || e is TypeError) {
        return left(const FormatFailure());
      }
      return left(const ServerFailure('Failed to load books. Please try again.'));
    }
  }

  @override
  Future<Either<Failure, List<BookModel>>> fetchFilterBooks({
    required String category,
  }) async {
    final box = Hive.box(kFilterBox);
    final String subject = (category.isEmpty || category.toLowerCase() == 'all')
        ? 'general'
        : category.toLowerCase();

    try {
      final data = await apiService.getData(
        endPoint: "search.json?q=$subject&language=eng&limit=50",
      );
      final bookResponse = BookResponseModel.fromJson(data);
      final List rawList = data['works'] ?? data['docs'] ?? [];
      await _writeCachedList(box, '${subject}_eng', rawList);
      return right(bookResponse.books);
    } catch (e) {
      try {
        final cachedBooks = _readCachedBooks(box, '${subject}_eng');
        if (cachedBooks.isNotEmpty) {
          return right(cachedBooks);
        }
      } catch (_) {
        // Fallback to network failure below when cache parse fails.
      }

      if (e is Failure) return left(e);
      if (e is DioException) return left(ServerFailure.fromDioError(e));
      if (e is FormatException || e is TypeError) {
        return left(const FormatFailure());
      }
      return left(const ServerFailure('Failed to load books. Please try again.'));
    }
  }

  @override
  Future<void> clearCache() async {
    await Hive.box(kFeaturedBox).clear();
    await Hive.box(kFilterBox).clear();
  }
}
