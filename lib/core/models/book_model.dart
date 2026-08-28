import 'package:equatable/equatable.dart';

class BookResponseModel {
  final List<BookModel> books;

  BookResponseModel({required this.books});

  factory BookResponseModel.fromJson(Map<String, dynamic> json) {
    final List rawList = json['works'] ?? json['docs'] ?? [];
    return BookResponseModel(
      books: preferEnglishBooks(
        rawList
            .map(
              (item) =>
                  BookModel.fromJson(Map<String, dynamic>.from(item as Map)),
            )
            .toList(),
      ),
    );
  }
}

class BookModel extends Equatable {
  final String key;
  final String title;
  final String authorName;
  final String coverUrl;
  final int? firstPublishYear;
  final String? collection;
  final int? addedAt;
  final int? progress;
  final String? language;
  final String? iaId;
  final String? notes;

  const BookModel({
    required this.key,
    required this.title,
    required this.authorName,
    required this.coverUrl,
    this.firstPublishYear,
    this.collection,
    this.addedAt,
    this.progress,
    this.language,
    this.iaId,
    this.notes,
  });

  @override
  List<Object?> get props => [key, title, authorName, coverUrl, firstPublishYear, collection, addedAt, progress, language, iaId, notes];

  factory BookModel.fromJson(Map<String, dynamic> json) {
    final int? coverId = json['cover_id'] ?? json['cover_i'];
    final String coverImage =
        json['cover_url'] ??
        (coverId != null
            ? 'https://covers.openlibrary.org/b/id/$coverId-L.jpg'
            : '');

    String author = 'Unknown Author';
    final rawAuthors = json['authors'];
    final rawAuthorName = json['author_name'];
    if (rawAuthors is List && rawAuthors.isNotEmpty) {
      final firstAuthor = rawAuthors.first;
      if (firstAuthor is Map) {
        author = firstAuthor['name']?.toString() ?? 'Unknown Author';
      } else {
        author = firstAuthor.toString();
      }
    } else if (rawAuthorName is List && rawAuthorName.isNotEmpty) {
      author = rawAuthorName.first.toString();
    } else if (rawAuthors is String && rawAuthors.isNotEmpty) {
      author = rawAuthors;
    } else if (rawAuthorName is String && rawAuthorName.isNotEmpty) {
      author = rawAuthorName;
    }

    return BookModel(
      key: json['key'] ?? '',
      title: json['title'] ?? 'No Title',
      authorName: author,
      coverUrl: coverImage,
      firstPublishYear: json['first_publish_year'] is int
          ? json['first_publish_year'] as int
          : int.tryParse('${json['first_publish_year'] ?? ''}'),
      collection: json['collection'] is String ? json['collection'] : null,
      addedAt: json['added_at'] is int
          ? json['added_at'] as int
          : int.tryParse('${json['added_at'] ?? ''}'),
      progress: json['progress'] is int
          ? json['progress'] as int
          : int.tryParse('${json['progress'] ?? ''}'),
      language: languageCodeFromJson(json['language'] ?? json['languages']),
      iaId: iaIdFromJson(json['ia'] ?? json['ocaid'] ?? json['ia_id']),
      notes: json['notes'] as String?,
    );
  }

  bool get isArchiveBook =>
      key.startsWith('/ia/') ||
      (iaId != null && iaId!.isNotEmpty && !key.contains('/works/'));

  String get coverHeroTag {
    if (key.isNotEmpty) return 'cover-$key';
    return 'cover-$title-$authorName';
  }

  factory BookModel.fromArchiveJson(Map<String, dynamic> json) {
    final identifier = json['identifier']?.toString().trim() ?? '';
    final rawTitle = json['title'];
    String title = 'No Title';
    if (rawTitle is List && rawTitle.isNotEmpty) {
      title = rawTitle.first.toString();
    } else if (rawTitle != null) {
      title = rawTitle.toString();
    }

    String author = 'Unknown Author';
    final rawCreator = json['creator'];
    if (rawCreator is List && rawCreator.isNotEmpty) {
      author = rawCreator.first.toString();
    } else if (rawCreator != null && rawCreator.toString().trim().isNotEmpty) {
      author = rawCreator.toString();
    }

    return BookModel(
      key: '/ia/$identifier',
      title: title,
      authorName: author,
      coverUrl: identifier.isEmpty
          ? ''
          : 'https://archive.org/services/img/$identifier',
      firstPublishYear: json['year'] is int
          ? json['year'] as int
          : int.tryParse('${json['year'] ?? json['date'] ?? ''}'),
      language: languageCodeFromJson(
        json['language'],
        preferEnglish: false,
      ),
      iaId: identifier.isEmpty ? null : identifier,
    );
  }

  static List<BookModel> listFromArchiveResponse(Map<String, dynamic> json) {
    final docs = json['response'] is Map ? json['response']['docs'] : null;
    if (docs is! List) return [];
    return docs
        .whereType<Map>()
        .map((item) => BookModel.fromArchiveJson(Map<String, dynamic>.from(item)))
        .where((book) => book.iaId != null && book.iaId!.isNotEmpty)
        .toList();
  }

  BookModel copyWith({
    String? key,
    String? title,
    String? authorName,
    String? coverUrl,
    int? firstPublishYear,
    String? collection,
    int? addedAt,
    int? progress,
    String? language,
    String? iaId,
    String? notes,
  }) {
    return BookModel(
      key: key ?? this.key,
      title: title ?? this.title,
      authorName: authorName ?? this.authorName,
      coverUrl: coverUrl ?? this.coverUrl,
      firstPublishYear: firstPublishYear ?? this.firstPublishYear,
      collection: collection ?? this.collection,
      addedAt: addedAt ?? this.addedAt,
      progress: progress ?? this.progress,
      language: language ?? this.language,
      iaId: iaId ?? this.iaId,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'title': title,
      'author_name': [authorName],
      'cover_url': coverUrl,
      'first_publish_year': firstPublishYear,
      'collection': collection,
      'added_at': addedAt,
      'progress': progress,
      'language': language,
      'ia': iaId,
      'ocaid': iaId,
      'notes': notes,
    };
  }
}

bool isEnglishLanguage(String? code) {
  if (code == null || code.isEmpty) return false;
  return code == 'ENG' || code == 'EN' || code == 'ENGLISH';
}

List<BookModel> preferEnglishBooks(List<BookModel> books) {
  final english = <BookModel>[];
  final unknown = <BookModel>[];
  final other = <BookModel>[];
  for (final book in books) {
    if (isEnglishLanguage(book.language)) {
      english.add(book);
    } else if (book.language == null || book.language!.isEmpty) {
      unknown.add(book);
    } else {
      other.add(book);
    }
  }
  return [...english, ...unknown, ...other];
}

String? iaIdFromJson(dynamic raw) {
  if (raw == null) return null;
  if (raw is List) {
    if (raw.isEmpty) return null;
    final value = raw.first.toString().trim();
    return value.isEmpty ? null : value;
  }
  final value = raw.toString().trim();
  return value.isEmpty ? null : value;
}

String normalizeBookTitle(String title) {
  return title
      .toLowerCase()
      .split(':')
      .first
      .replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

bool containsArabic(String text) {
  return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
}

String archiveReaderUrl(String identifier) {
  return 'https://archive.org/details/$identifier/page/n19/mode/2up';
}

String? languageCodeFromJson(dynamic raw, {bool preferEnglish = true}) {
  if (raw == null) return null;
  final items = raw is List ? raw : [raw];
  if (items.isEmpty) return null;

  String? normalize(dynamic value) {
    String code;
    if (value is Map) {
      code = (value['key'] ?? value['code'] ?? '').toString();
    } else {
      code = value.toString();
    }
    final segment = code.split('/').last.trim();
    if (segment.isEmpty) return null;
    return segment.length <= 3
        ? segment.toUpperCase()
        : segment.substring(0, 3).toUpperCase();
  }

  final codes = items.map(normalize).whereType<String>().toList();
  if (preferEnglish) {
    for (final code in codes) {
      if (isEnglishLanguage(code)) return code;
    }
  }
  return codes.isEmpty ? null : codes.first;
}
