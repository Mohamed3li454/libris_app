import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:libris_app/core/errors/failure.dart';
import 'package:libris_app/core/models/book_model.dart';
import 'package:libris_app/core/utils/api_service.dart';
import 'package:libris_app/features/explore/data/repos/search_repo.dart';

class SearchRepoImpl implements SearchRepo {
  final ApiService apiService;

  SearchRepoImpl({required this.apiService});

  @override
  Future<Either<Failure, List<BookModel>>> searchBooks(
    String query, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      var data = await apiService.searchBooks(query, page: page, limit: limit);
      final bookResponse = BookResponseModel.fromJson(data);
      return right(bookResponse.books);
    } catch (e) {
      if (e is Failure) return left(e);
      if (e is DioException) return left(ServerFailure.fromDioError(e));
      if (e is FormatException || e is TypeError) {
        return left(const FormatFailure());
      }
      return left(ServerFailure('Search failed. Please try again.'));
    }
  }

  @override
  Future<Either<Failure, List<BookModel>>> fetchBooksBySubject(
    String subject, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      var data = await apiService.fetchBooksBySubject(
        subject,
        page: page,
        limit: limit,
      );
      final bookResponse = BookResponseModel.fromJson(data);
      return right(bookResponse.books);
    } catch (e) {
      if (e is Failure) return left(e);
      if (e is DioException) return left(ServerFailure.fromDioError(e));
      if (e is FormatException || e is TypeError) {
        return left(const FormatFailure());
      }
      return left(
        ServerFailure('Failed to load category books. Please try again.'),
      );
    }
  }

  @override
  Future<Either<Failure, List<BookModel>>> fetchTrendingBooks({
    int limit = 50,
  }) async {
    try {
      var data = await apiService.fetchTrendingBooks(limit: limit);
      final bookResponse = BookResponseModel.fromJson(data);
      return right(bookResponse.books);
    } catch (e) {
      if (e is Failure) return left(e);
      if (e is DioException) return left(ServerFailure.fromDioError(e));
      if (e is FormatException || e is TypeError) {
        return left(const FormatFailure());
      }
      return left(
        ServerFailure('Failed to load trending books. Please try again.'),
      );
    }
  }
}
