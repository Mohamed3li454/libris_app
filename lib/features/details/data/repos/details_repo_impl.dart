import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:libris_app/core/errors/failure.dart';
import 'package:libris_app/core/models/book_model.dart';
import 'package:libris_app/core/utils/api_service.dart';
import 'package:libris_app/features/details/data/models/book_detail_model.dart';
import 'package:libris_app/features/details/data/repos/details_repo.dart';

class DetailsRepoImpl implements DetailsRepo {
  final ApiService apiService;

  DetailsRepoImpl({required this.apiService});

  @override
  Future<Either<Failure, BookDetailModel>> fetchBookDetails(
    String workKey, {
    BookModel? book,
  }) async {
    try {
      var openLibraryKey = workKey.contains('/works/') ? workKey : null;
      if (openLibraryKey == null && book != null) {
        openLibraryKey = await _findOpenLibraryWorkKey(book);
      }

      if (openLibraryKey != null) {
        final detailModel = await _detailsFromOpenLibrary(
          openLibraryKey,
          book: book,
        );
        return right(detailModel);
      }

      final archiveId = _archiveId(workKey: workKey, book: book);
      if (archiveId != null) {
        return right(await _detailsFromArchive(archiveId, book));
      }

      return left(
        ServerFailure('Failed to load book details. Please try again.'),
      );
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

  Future<BookDetailModel> _detailsFromOpenLibrary(
    String workKey, {
    BookModel? book,
  }) async {
    final detailsDataFuture = apiService.fetchBookDetails(workKey);
    final ratingDataFuture = apiService
        .fetchBookRating(workKey)
        .catchError((_) => <String, dynamic>{});
    final editionsDataFuture = apiService
        .fetchWorkEditions(workKey)
        .catchError((_) => <String, dynamic>{});

    final results = await Future.wait([
      detailsDataFuture,
      ratingDataFuture,
      editionsDataFuture,
    ]);

    var detailModel = BookDetailModel.fromJson(
      detailsJson: results[0],
      ratingJson: results[1],
      editionsJson: results[2],
    );

    final readerTitle = detailModel.title.trim().isNotEmpty
        ? detailModel.title
        : (book?.title ?? '');
    final readerUrl = await apiService.resolveArchiveReaderUrl(
      title: readerTitle,
      author: book?.authorName,
      preferEnglish: !containsArabic(readerTitle),
    );

    if (readerUrl != null && readerUrl.isNotEmpty) {
      detailModel = detailModel.copyWith(
        readUrl: readerUrl,
        downloadUrl: readerUrl,
      );
    }
    return detailModel;
  }

  Future<String?> _findOpenLibraryWorkKey(BookModel book) async {
    final title = book.title.trim();
    if (title.isEmpty) return null;
    try {
      final data = await apiService.searchBooks(title, limit: 8);
      final candidates = BookResponseModel.fromJson(data).books;
      final target = normalizeBookTitle(title);
      if (target.isEmpty) return null;

      for (final candidate in candidates) {
        if (!candidate.key.contains('/works/')) continue;
        final candidateTitle = normalizeBookTitle(candidate.title);
        if (candidateTitle == target) return candidate.key;
      }
    } catch (_) {}
    return null;
  }

  String? _archiveId({required String workKey, BookModel? book}) {
    if (workKey.startsWith('/ia/')) {
      final id = workKey.substring(4).trim();
      return id.isEmpty ? null : id;
    }
    if (book != null && book.isArchiveBook && book.iaId != null) {
      return book.iaId!.trim();
    }
    return null;
  }

  Future<BookDetailModel> _detailsFromArchive(
    String identifier,
    BookModel? book,
  ) async {
    final title = book?.title ?? '';
    final readerUrl =
        await apiService.resolveArchiveReaderUrl(
          title: title,
          author: book?.authorName,
          preferEnglish: !containsArabic(title),
        ) ??
        archiveReaderUrl(identifier);

    try {
      final metadata = await apiService.fetchArchiveMetadata(identifier);
      return BookDetailModel.fromArchive(
        identifier: identifier,
        metadataJson: metadata,
      ).copyWith(readUrl: readerUrl, downloadUrl: readerUrl);
    } catch (_) {
      return BookDetailModel(
        key: '/ia/$identifier',
        title: book?.title ?? 'No Title',
        description: 'No description available for this book.',
        primaryCategory: 'General',
        subjects: const [],
        averageRating: 0,
        ratingCount: 0,
        readUrl: readerUrl,
        downloadUrl: readerUrl,
        language: book?.language,
      );
    }
  }
}
