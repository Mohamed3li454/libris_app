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
  Future<Either<Failure, List<BookModel>>> searchBooks(String query) async {
    try {
      var data = await apiService.searchBooks(query);
      final bookResponse = BookResponseModel.fromJson(data);
      return right(bookResponse.books);
    } catch (e) {
      if (e is Failure) return left(e);
      if (e is DioException) return left(ServerFailure.fromDioError(e));
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<BookModel>>> fetchBooksBySubject(
    String subject,
  ) async {
    try {
      var data = await apiService.fetchBooksBySubject(subject);
      final bookResponse = BookResponseModel.fromJson(data);
      return right(bookResponse.books);
    } catch (e) {
      if (e is Failure) return left(e);
      if (e is DioException) return left(ServerFailure.fromDioError(e));
      return left(ServerFailure(e.toString()));
    }
  }
}
