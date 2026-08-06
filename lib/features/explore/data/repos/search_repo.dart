import 'package:dartz/dartz.dart';
import 'package:libris_app/core/errors/failure.dart';
import 'package:libris_app/core/models/book_model.dart';

abstract class SearchRepo {
  Future<Either<Failure, List<BookModel>>> searchBooks(String query);
  Future<Either<Failure, List<BookModel>>> fetchBooksBySubject(String subject);
}
