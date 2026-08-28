import 'package:flutter_test/flutter_test.dart';
import 'package:libris_app/core/models/book_model.dart';

void main() {
  group('BookModel', () {
    test('fromJson with complete data', () {
      final json = {
        'key': '/works/OL12345W',
        'title': 'Test Book',
        'author_name': ['John Doe'],
        'cover_i': 12345,
        'first_publish_year': 2020,
        'collection': 'sci-fi',
        'added_at': 1600000000,
        'progress': 50,
        'language': ['eng'],
        'ia': ['test_book_ia']
      };

      final book = BookModel.fromJson(json);

      expect(book.key, '/works/OL12345W');
      expect(book.title, 'Test Book');
      expect(book.authorName, 'John Doe');
      expect(book.coverUrl, 'https://covers.openlibrary.org/b/id/12345-L.jpg');
      expect(book.firstPublishYear, 2020);
      expect(book.collection, 'sci-fi');
      expect(book.addedAt, 1600000000);
      expect(book.progress, 50);
      expect(book.language, 'ENG');
      expect(book.iaId, 'test_book_ia');
    });

    test('fromJson with missing fields', () {
      final json = {
        'key': '/works/OL12345W',
      };

      final book = BookModel.fromJson(json);

      expect(book.key, '/works/OL12345W');
      expect(book.title, 'No Title');
      expect(book.authorName, 'Unknown Author');
      expect(book.coverUrl, '');
      expect(book.firstPublishYear, isNull);
    });

    test('fromJson with String author_name', () {
      final json = {
        'key': '/works/OL12345W',
        'author_name': 'Jane Doe',
      };

      final book = BookModel.fromJson(json);
      expect(book.authorName, 'Jane Doe');
    });

    test('fromArchiveJson parsing', () {
      final json = {
        'identifier': 'test_identifier',
        'title': 'Archive Book',
        'creator': 'Archive Author',
        'year': 2010,
        'language': 'fre',
      };

      final book = BookModel.fromArchiveJson(json);

      expect(book.key, '/ia/test_identifier');
      expect(book.title, 'Archive Book');
      expect(book.authorName, 'Archive Author');
      expect(book.coverUrl, 'https://archive.org/services/img/test_identifier');
      expect(book.firstPublishYear, 2010);
      expect(book.language, 'FRE');
      expect(book.iaId, 'test_identifier');
    });

    test('toJson round-trip', () {
      final book = const BookModel(
        key: 'key',
        title: 'title',
        authorName: 'authorName',
        coverUrl: 'coverUrl',
        firstPublishYear: 2000,
        collection: 'col',
        addedAt: 100,
        progress: 10,
        language: 'ENG',
        iaId: 'ia',
      );

      final json = book.toJson();
      
      final book2 = BookModel.fromJson(json);
      expect(book, book2);
    });

    test('copyWith', () {
      final book = const BookModel(
        key: 'key',
        title: 'title',
        authorName: 'authorName',
        coverUrl: 'coverUrl',
      );

      final newBook = book.copyWith(title: 'new title');
      expect(newBook.title, 'new title');
      expect(newBook.key, 'key');
    });

    test('equality (Equatable)', () {
      final book1 = const BookModel(
        key: 'key',
        title: 'title',
        authorName: 'authorName',
        coverUrl: 'coverUrl',
      );
      final book2 = const BookModel(
        key: 'key',
        title: 'title',
        authorName: 'authorName',
        coverUrl: 'coverUrl',
      );

      expect(book1, book2);
      expect(book1.hashCode, book2.hashCode);
    });
  });

  group('BookModel helper methods', () {
    test('normalizeBookTitle', () {
      expect(normalizeBookTitle('Title: Subtitle'), 'title');
      expect(normalizeBookTitle('Title - Subtitle!'), 'title subtitle');
      expect(normalizeBookTitle('  Hello   World  '), 'hello world');
    });

    test('containsArabic', () {
      expect(containsArabic('Hello'), isFalse);
      expect(containsArabic('مرحبا'), isTrue);
      expect(containsArabic('Hello مرحبا'), isTrue);
    });

    test('preferEnglishBooks', () {
      final b1 = const BookModel(key: '1', title: '1', authorName: '1', coverUrl: '1', language: 'FRE');
      final b2 = const BookModel(key: '2', title: '2', authorName: '2', coverUrl: '2', language: 'ENG');
      final b3 = const BookModel(key: '3', title: '3', authorName: '3', coverUrl: '3', language: null);

      final sorted = preferEnglishBooks([b1, b2, b3]);
      expect(sorted[0].language, 'ENG');
      expect(sorted[1].language, isNull);
      expect(sorted[2].language, 'FRE');
    });

    test('languageCodeFromJson', () {
      expect(languageCodeFromJson('eng'), 'ENG');
      expect(languageCodeFromJson(['fre']), 'FRE');
      expect(languageCodeFromJson([{'key': '/languages/ara'}]), 'ARA');
      expect(languageCodeFromJson([{'key': '/languages/ara'}, 'eng'], preferEnglish: true), 'ENG');
      expect(languageCodeFromJson(null), isNull);
    });

    test('iaIdFromJson', () {
      expect(iaIdFromJson('id1'), 'id1');
      expect(iaIdFromJson(['id2']), 'id2');
      expect(iaIdFromJson([]), isNull);
      expect(iaIdFromJson(null), isNull);
      expect(iaIdFromJson('   '), isNull);
    });
  });
}
