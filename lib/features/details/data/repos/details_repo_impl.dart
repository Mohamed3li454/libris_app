import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:libris_app/core/errors/failure.dart';
import 'package:libris_app/core/utils/api_service.dart';
import 'package:libris_app/features/details/data/models/book_detail_model.dart';
import 'package:libris_app/features/details/data/repos/details_repo.dart';

class DetailsRepoImpl implements DetailsRepo {
  final ApiService apiService;

  DetailsRepoImpl({required this.apiService});

  @override
  Future<Either<Failure, BookDetailModel>> fetchBookDetails(
    String workKey,
  ) async {
    try {
      final detailsDataFuture = apiService.fetchBookDetails(workKey);
      final ratingDataFuture = apiService
          .fetchBookRating(workKey)
          .catchError((_) => <String, dynamic>{});

      final results = await Future.wait([detailsDataFuture, ratingDataFuture]);
      final detailsJson = results[0];
      final ratingJson = results[1];

      final detailModel = BookDetailModel.fromJson(
        detailsJson: detailsJson,
        ratingJson: ratingJson,
      );

      return right(detailModel);
    } catch (e) {
      if (e is Failure) return left(e);
      if (e is DioException) return left(ServerFailure.fromDioError(e));
      if (e is FormatException || e is TypeError) {
        return left(const FormatFailure());
      }
      return left(
        ServerFailure('Failed to load book details. Please try again.'),
      );
    }
  }
}
