import 'package:libris_app/core/models/book_model.dart';

abstract class HomeRepo {
  Future<List<BookModel>> fetchNewestBooks();
  Future<List<BookModel>> fetchFeaturedBooks();
}
