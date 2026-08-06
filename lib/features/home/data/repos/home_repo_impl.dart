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

  HomeRepoImpl({required this.apiService});

  @override
  Future<Either<Failure, List<BookModel>>> fetchFeaturedBooks() async {
    var box = Hive.box(kFeaturedBox);
    try {
      var data = await apiService.getData(
        endPoint: "trending/weekly.json?limit=20",
      );
      final bookResponse = BookResponseModel.fromJson(data);
      List rawList = data['works'] ?? data['docs'] ?? [];
      await box.put('featured_list', rawList);
      return right(bookResponse.books);
    } catch (e) {
      if (box.containsKey('featured_list')) {
        try {
          List cachedRawList = box.get('featured_list') as List;
          List<BookModel> cachedBooks =
              cachedRawList
                  .map(
                    (item) =>
                        BookModel.fromJson(Map<String, dynamic>.from(item)),
                  )
                  .toList();
          if (cachedBooks.isNotEmpty) {
            return right(cachedBooks);
          }
        } catch (_) {}
      }

      if (e is Failure) return left(e);
      if (e is DioException) return left(ServerFailure.fromDioError(e));
      if (e is FormatException || e is TypeError) {
        return left(const FormatFailure());
      }
      return left(ServerFailure('Failed to load books. Please try again.'));
    }
  }

  @override
  Future<Either<Failure, List<BookModel>>> fetchFilterBooks({
    required String category,
  }) async {
    var box = Hive.box(kFilterBox);
    String subject =
        (category.isEmpty || category.toLowerCase() == 'all')
            ? 'general'
            : category.toLowerCase();

    try {
      var data = await apiService.getData(
        endPoint: "search.json?q=$subject&limit=50",
      );
      final bookResponse = BookResponseModel.fromJson(data);
      List rawList = data['works'] ?? data['docs'] ?? [];
      await box.put(subject, rawList);
      return right(bookResponse.books);
    } catch (e) {
      if (box.containsKey(subject)) {
        try {
          List cachedRawList = box.get(subject) as List;
          List<BookModel> cachedBooks =
              cachedRawList
                  .map(
                    (item) =>
                        BookModel.fromJson(Map<String, dynamic>.from(item)),
                  )
                  .toList();
          if (cachedBooks.isNotEmpty) {
            return right(cachedBooks);
          }
        } catch (_) {}
      }

      if (e is Failure) return left(e);
      if (e is DioException) return left(ServerFailure.fromDioError(e));
      if (e is FormatException || e is TypeError) {
        return left(const FormatFailure());
      }
      return left(ServerFailure('Failed to load books. Please try again.'));
    }
  }
}
