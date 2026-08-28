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
      final results = await Future.wait([
        apiService
            .searchBooks(query, page: page, limit: limit)
            .then((data) => BookResponseModel.fromJson(data).books)
            .catchError((_) => <BookModel>[]),
        apiService
            .searchArchiveBooks(query, page: page, limit: limit)
            .then(BookModel.listFromArchiveResponse)
            .catchError((_) => <BookModel>[]),
      ]);

      final openLibraryBooks = results[0];
      var archiveBooks = results[1];

      if (archiveBooks.isEmpty) {
        archiveBooks = await apiService
            .searchArchiveBooks(
              query,
              page: page,
              limit: limit,
              applyLanguageFilter: false,
            )
            .then(BookModel.listFromArchiveResponse)
            .catchError((_) => <BookModel>[]);
      }

      return right(_mergeSearchResults(openLibraryBooks, archiveBooks));
    } catch (e) {
      if (e is Failure) return left(e);
      if (e is DioException) return left(ServerFailure.fromDioError(e));
      if (e is FormatException || e is TypeError) {
        return left(const FormatFailure());
      }
      return left(const ServerFailure('Search failed. Please try again.'));
    }
  }

  List<BookModel> _mergeSearchResults(
    List<BookModel> openLibraryBooks,
    List<BookModel> archiveBooks,
  ) {
    final merged = <BookModel>[...openLibraryBooks];
    final olByTitle = <String, int>{};

    for (var i = 0; i < merged.length; i++) {
      final normalized = normalizeBookTitle(merged[i].title);
      if (normalized.isNotEmpty) {
        olByTitle.putIfAbsent(normalized, () => i);
      }
    }

    for (final archiveBook in archiveBooks) {
      final normalized = normalizeBookTitle(archiveBook.title);
      final matchIndex = normalized.isEmpty ? null : olByTitle[normalized];
      if (matchIndex != null) {
        continue;
      }
      merged.add(archiveBook);
    }

    return merged;
  }

  @override
  Future<Either<Failure, List<BookModel>>> fetchBooksBySubject(
    String subject, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final data = await apiService.fetchBooksBySubject(
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
        const ServerFailure('Failed to load category books. Please try again.'),
      );
    }
  }

  @override
  Future<Either<Failure, List<BookModel>>> fetchTrendingBooks({
    int limit = 50,
  }) async {
    try {
      final data = await apiService.fetchTrendingBooks(limit: limit);
      final bookResponse = BookResponseModel.fromJson(data);
      return right(bookResponse.books);
    } catch (e) {
      if (e is Failure) return left(e);
      if (e is DioException) return left(ServerFailure.fromDioError(e));
      if (e is FormatException || e is TypeError) {
        return left(const FormatFailure());
      }
      return left(
        const ServerFailure('Failed to load trending books. Please try again.'),
      );
    }
  }
}
