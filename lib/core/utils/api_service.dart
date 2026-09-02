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

  Future<String?> resolveArchivePdfUrl({
    String? identifier,
    String? title,
    String? author,
  }) async {
    if (identifier != null && identifier.trim().isNotEmpty) {
      final url = await _pdfUrlForIdentifier(identifier.trim());
      if (url != null) return url;
    }

    final searchTitle = title?.trim() ?? '';
    if (searchTitle.isEmpty) return null;

    final publicId = await _searchArchiveIdentifier(
      title: searchTitle,
      author: author,
      englishOnly: !containsArabic(searchTitle),
      publicOnly: true,
    );
    if (publicId == null || publicId.isEmpty || publicId == identifier) {
      return null;
    }
    return _pdfUrlForIdentifier(publicId);
  }

  Future<String?> _pdfUrlForIdentifier(String identifier) async {
    try {
      final metadata = await fetchArchiveMetadata(identifier);
      if (_isArchiveRestricted(metadata)) return null;
      final filename = _pickArchivePdfFilename(metadata);
      if (filename == null || filename.isEmpty) return null;
      return archivePdfDownloadUrl(identifier, filename);
    } catch (_) {
      return null;
    }
  }

  bool _isArchiveRestricted(Map<String, dynamic> metadataJson) {
    final metadata = metadataJson['metadata'];
    if (metadata is! Map) return false;
    final restricted = metadata['access-restricted-item']?.toString().toLowerCase();
    if (restricted == 'true') return true;

    final rawCollection = metadata['collection'];
    final collections = <String>[];
    if (rawCollection is List) {
      collections.addAll(rawCollection.map((item) => item.toString().toLowerCase()));
    } else if (rawCollection != null) {
      collections.add(rawCollection.toString().toLowerCase());
    }
    return collections.any(
      (collection) =>
          collection == 'inlibrary' || collection == 'printdisabled',
    );
  }

  String? _pickArchivePdfFilename(Map<String, dynamic> metadataJson) {
    final files = metadataJson['files'];
    if (files is! List) return null;

    final pdfs = <({String name, String format, int size})>[];
    for (final file in files) {
      if (file is! Map) continue;
      final name = file['name']?.toString() ?? '';
      if (!name.toLowerCase().endsWith('.pdf')) continue;
      final lowerName = name.toLowerCase();
      if (lowerName.contains('_encrypted') || lowerName.contains('ia_thumb')) {
        continue;
      }
      final format = file['format']?.toString() ?? '';
      if (format.toLowerCase().contains('page description')) continue;
      final size = int.tryParse('${file['size'] ?? 0}') ?? 0;
      pdfs.add((name: name, format: format, size: size));
    }
    if (pdfs.isEmpty) return null;

    int score(({String name, String format, int size}) file) {
      final format = file.format.toLowerCase();
      final name = file.name.toLowerCase();
      var value = 0;
      if (format == 'text pdf') value += 40;
      if (format == 'pdf') value += 30;
      if (format.contains('acrobat')) value += 20;
      if (name.contains('_text.pdf')) value += 8;
      if (file.size > 0) value += 2;
      return value;
    }

    pdfs.sort((a, b) => score(b).compareTo(score(a)));
    return pdfs.first.name;
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
