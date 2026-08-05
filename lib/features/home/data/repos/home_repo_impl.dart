import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:libris_app/core/errors/failure.dart';
import 'package:libris_app/core/models/book_model.dart';
import 'package:libris_app/core/utils/api_service.dart';
import 'package:libris_app/features/home/data/repos/home_repo.dart';

class HomeRepoImpl implements HomeRepo {
  final ApiService apiService;

  HomeRepoImpl({required this.apiService});

  @override
  Future<Either<Failure, List<BookModel>>> fetchFeaturedBooks() async {
    try {
      var data = await apiService.getData(
        endPoint: "volumes?q=featured&maxResults=10",
      );
      final bookResponse = BookResponseModel.fromJson(data);
      return right(bookResponse.books);
    } catch (e) {
      if (e is DioException) {
        return left(ServerFailure.fromDioError(e));
      }
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<BookModel>>> fetchFilterBooks({
    required String category,
  }) async {
    try {
      String query = (category.isEmpty || category.toLowerCase() == 'all')
          ? 'general'
          : 'subject:$category';

      var data = await apiService.getData(endPoint: "volumes?q=$query");
      final bookResponse = BookResponseModel.fromJson(data);
      return right(bookResponse.books);
    } catch (e) {
      if (e is Failure) {
        return left(e);
      }
      if (e is DioException) {
        return left(ServerFailure.fromDioError(e));
      }
      return left(ServerFailure(e.toString()));
    }
  }
}
