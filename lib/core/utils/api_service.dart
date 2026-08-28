import 'package:dio/dio.dart';
import 'package:libris_app/core/models/book_model.dart';

class ApiService {
  final String baseUrl = "https://openlibrary.org/";
  final Dio _dio;

  ApiService(this._dio);

  Future<Map<String, dynamic>> getData({
    required String endPoint,
    Map<String, dynamic>? queryParameters,
  }) async {
    final Response response = await _dio.get(
      "$baseUrl$endPoint",
      queryParameters: queryParameters,
    );
    return response.data;
  }

  Future<Map<String, dynamic>> fetchBookDetails(String workKey) async {
    final String cleanKey = workKey.startsWith('/') ? workKey.substring(1) : workKey;
    return await getData(endPoint: "$cleanKey.json");
  }

  Future<Map<String, dynamic>> fetchBookRating(String workKey) async {
    final String cleanKey = workKey.startsWith('/') ? workKey.substring(1) : workKey;
    return await getData(endPoint: "$cleanKey/ratings.json");
  }

  Future<Map<String, dynamic>> fetchWorkEditions(
    String workKey, {
    int limit = 20,
  }) async {
    final String cleanKey = workKey.startsWith('/') ? workKey.substring(1) : workKey;
    return await getData(
      endPoint: "$cleanKey/editions.json",
      queryParameters: {'limit': limit},
    );
  }

  Future<Map<String, dynamic>> fetchTrendingBooks({int limit = 50}) async {
    return await getData(
      endPoint: "trending/weekly.json",
      queryParameters: {'limit': limit},
    );
  }

  Future<Map<String, dynamic>> searchBooks(
    String query, {
    int page = 1,
    int limit = 20,
  }) async {
    final Map<String, dynamic> params = {
      'q': query,
      'limit': limit,
      'page': page,
    };
    if (!containsArabic(query)) {
      params['language'] = 'eng';
    }
    return await getData(
      endPoint: "search.json",
      queryParameters: params,
    );
  }

  Future<Map<String, dynamic>> searchArchiveBooks(
    String query, {
    int page = 1,
    int limit = 20,
    bool publicOnly = true,
    bool applyLanguageFilter = true,
  }) async {
    final cleanQuery = query.replaceAll('"', ' ').trim();
    final isArabic = containsArabic(cleanQuery);
    final search = StringBuffer('($cleanQuery) AND mediatype:texts');
    if (applyLanguageFilter) {
      if (isArabic) {
        search.write(
          ' AND (language:ara OR language:arabic OR language:"Arabic")',
        );
      } else {
        search.write(
          ' AND (language:eng OR language:english OR language:"English")',
        );
      }
    }
    if (publicOnly) {
      search.write(
        ' AND NOT collection:inlibrary AND NOT collection:printdisabled',
      );
    }

    final response = await _dio.get(
      'https://archive.org/advancedsearch.php',
      queryParameters: {
        'q': search.toString(),
        'fl[]': [
          'identifier',
          'title',
          'creator',
          'year',
          'date',
          'language',
          'description',
        ],
        'sort[]': 'downloads desc',
        'rows': limit,
        'page': page,
        'output': 'json',
      },
    );
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> fetchArchiveMetadata(String identifier) async {
    final response = await _dio.get(
      'https://archive.org/metadata/$identifier',
    );
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> fetchBooksBySubject(
    String subject, {
    int page = 1,
    int limit = 20,
  }) async {
    return await getData(
      endPoint: "search.json",
      queryParameters: {
        'q': 'subject:$subject',
        'language': 'eng',
        'limit': limit,
        'page': page,
      },
    );
  }

  Future<String?> resolveArchiveReaderUrl({
    required String title,
    String? author,
    bool preferEnglish = true,
  }) async {
    try {
      final englishOnly = preferEnglish && !containsArabic(title);
      final identifier =
          await _searchArchiveIdentifier(
            title: title,
            author: author,
            englishOnly: englishOnly,
            publicOnly: true,
          ) ??
          await _searchArchiveIdentifier(
            title: title,
            englishOnly: englishOnly,
            publicOnly: true,
          ) ??
          await _searchArchiveIdentifier(
            title: title,
            englishOnly: englishOnly,
            publicOnly: false,
          );
      if (identifier == null || identifier.isEmpty) return null;
      return archiveReaderUrl(identifier);
    } catch (_) {
      return null;
    }
  }

  Future<String?> _searchArchiveIdentifier({
    required String title,
    String? author,
    required bool englishOnly,
    required bool publicOnly,
  }) async {
    final cleanTitle = title.split(':').first.replaceAll('"', ' ').trim();
    if (cleanTitle.isEmpty) return null;

    final query = StringBuffer('title:("$cleanTitle") AND mediatype:texts');
    if (author != null &&
        author.trim().isNotEmpty &&
        author.toLowerCase() != 'unknown author') {
      query.write(' AND creator:("${author.replaceAll('"', ' ').trim()}")');
    }
    if (englishOnly) {
      query.write(
        ' AND (language:eng OR language:english OR language:"English")',
      );
    }
    if (publicOnly) {
      query.write(
        ' AND NOT collection:inlibrary AND NOT collection:printdisabled',
      );
    }

    final response = await _dio.get(
      'https://archive.org/advancedsearch.php',
      queryParameters: {
        'q': query.toString(),
        'fl[]': ['identifier', 'language'],
        'sort[]': 'downloads desc',
        'rows': 10,
        'output': 'json',
      },
    );
    final docs = response.data is Map
        ? (response.data['response'] is Map
              ? response.data['response']['docs']
              : null)
        : null;
    if (docs is! List || docs.isEmpty) return null;

    for (final doc in docs) {
      if (doc is! Map || doc['identifier'] == null) continue;
      final id = doc['identifier'].toString().trim();
      if (id.isEmpty) continue;
      final language = languageCodeFromJson(
        doc['language'],
        preferEnglish: false,
      );
      if (englishOnly) {
        if (isEnglishLanguage(language)) return id;
        continue;
      }
      return id;
    }
    return null;
  }
}
