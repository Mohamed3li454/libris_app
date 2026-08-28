import 'package:libris_app/core/models/book_model.dart';

class BookDetailModel {
  final String key;
  final String title;
  final String description;
  final String primaryCategory;
  final List<String> subjects;
  final double averageRating;
  final int ratingCount;
  final String readUrl;
  final String? downloadUrl;
  final String? language;

  BookDetailModel({
    required this.key,
    required this.title,
    required this.description,
    required this.primaryCategory,
    required this.subjects,
    required this.averageRating,
    required this.ratingCount,
    required this.readUrl,
    this.downloadUrl,
    this.language,
  });

  bool get hasPdfDownload => downloadUrl != null && downloadUrl!.isNotEmpty;

  BookDetailModel copyWith({
    String? readUrl,
    String? downloadUrl,
    String? language,
  }) {
    return BookDetailModel(
      key: key,
      title: title,
      description: description,
      primaryCategory: primaryCategory,
      subjects: subjects,
      averageRating: averageRating,
      ratingCount: ratingCount,
      readUrl: readUrl ?? this.readUrl,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      language: language ?? this.language,
    );
  }

  factory BookDetailModel.fromArchive({
    required String identifier,
    required Map<String, dynamic> metadataJson,
  }) {
    final metadata = metadataJson['metadata'] is Map
        ? Map<String, dynamic>.from(metadataJson['metadata'] as Map)
        : metadataJson;
    final rawTitle = metadata['title'];
    String title = 'No Title';
    if (rawTitle is List && rawTitle.isNotEmpty) {
      title = rawTitle.first.toString();
    } else if (rawTitle != null) {
      title = rawTitle.toString();
    }

    String descText = 'No description available for this book.';
    final rawDesc = metadata['description'];
    if (rawDesc is List && rawDesc.isNotEmpty) {
      descText = rawDesc.first.toString().trim();
    } else if (rawDesc != null && rawDesc.toString().trim().isNotEmpty) {
      descText = rawDesc.toString().trim();
    }

    final rawSubject = metadata['subject'];
    List<String> subjects = [];
    if (rawSubject is List) {
      subjects = rawSubject.map((s) => s.toString()).toList();
    } else if (rawSubject != null) {
      subjects = rawSubject
          .toString()
          .split(';')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    final readerUrl = archiveReaderUrl(identifier);
    return BookDetailModel(
      key: '/ia/$identifier',
      title: title,
      description: descText,
      primaryCategory: subjects.isNotEmpty ? subjects.first : 'General',
      subjects: subjects,
      averageRating: 0,
      ratingCount: 0,
      readUrl: readerUrl,
      downloadUrl: readerUrl,
      language: languageCodeFromJson(
        metadata['language'],
        preferEnglish: false,
      ),
    );
  }

  factory BookDetailModel.fromJson({
    required Map<String, dynamic> detailsJson,
    Map<String, dynamic>? ratingJson,
    Map<String, dynamic>? editionsJson,
  }) {
    final String keyStr = detailsJson['key'] ?? '';
    final String fullKey = keyStr.startsWith('/') ? keyStr : '/$keyStr';
    final String openLibraryReadUrl = 'https://openlibrary.org$fullKey';

    String? downloadLink;
    if (detailsJson['links'] != null && detailsJson['links'] is List) {
      for (var l in detailsJson['links']) {
        if (l is Map && l['url'] != null) {
          final String u = l['url'].toString();
          if (u.toLowerCase().endsWith('.pdf')) {
            downloadLink = u;
            break;
          }
        }
      }
    }

    String descText = 'No description available for this book.';
    final rawDesc = detailsJson['description'];
    if (rawDesc != null) {
      if (rawDesc is String && rawDesc.trim().isNotEmpty) {
        descText = rawDesc.trim();
      } else if (rawDesc is Map && rawDesc['value'] != null) {
        descText = rawDesc['value'].toString().trim();
      }
    }

    List<String> subjectList = [];
    final rawSubjects = detailsJson['subjects'];
    if (rawSubjects is List) {
      subjectList = rawSubjects.map((s) => s.toString()).toList();
    }
    final String category = subjectList.isNotEmpty ? subjectList.first : 'General';

    double avgRating = 0.0;
    int count = 0;
    if (ratingJson != null && ratingJson['summary'] != null) {
      final summary = ratingJson['summary'] as Map<String, dynamic>;
      avgRating = (summary['average'] as num?)?.toDouble() ?? 0.0;
      count = (summary['count'] as num?)?.toInt() ?? 0;
    }

    String? language = languageCodeFromJson(detailsJson['languages']);
    if ((language == null || !isEnglishLanguage(language)) &&
        editionsJson != null &&
        editionsJson['entries'] is List) {
      for (final entry in editionsJson['entries'] as List) {
        if (entry is Map) {
          final editionLanguage = languageCodeFromJson(entry['languages']);
          if (isEnglishLanguage(editionLanguage)) {
            language = editionLanguage;
            break;
          }
          language ??= editionLanguage;
        }
      }
    }

    return BookDetailModel(
      key: keyStr,
      title: detailsJson['title'] ?? 'No Title',
      description: descText,
      primaryCategory: category,
      subjects: subjectList,
      averageRating: avgRating,
      ratingCount: count,
      readUrl: openLibraryReadUrl,
      downloadUrl: downloadLink,
      language: language,
    );
  }
}
