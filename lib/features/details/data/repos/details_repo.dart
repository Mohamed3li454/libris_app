import 'package:dartz/dartz.dart';
import 'package:libris_app/core/errors/failure.dart';
import 'package:libris_app/core/models/book_model.dart';
import 'package:libris_app/features/details/data/models/book_detail_model.dart';

abstract class DetailsRepo {
  Future<Either<Failure, BookDetailModel>> fetchBookDetails(
    String workKey, {
    BookModel? book,
  });
}
