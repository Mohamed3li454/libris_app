class BookDetailModel {
  final String key;
  final String title;
  final String description;
  final String primaryCategory;
  final List<String> subjects;
  final double averageRating;
  final int ratingCount;
  final String readUrl;
  final String downloadUrl;

  BookDetailModel({
    required this.key,
    required this.title,
    required this.description,
    required this.primaryCategory,
    required this.subjects,
    required this.averageRating,
    required this.ratingCount,
    required this.readUrl,
    required this.downloadUrl,
  });

  factory BookDetailModel.fromJson({
    required Map<String, dynamic> detailsJson,
    Map<String, dynamic>? ratingJson,
  }) {
    String keyStr = detailsJson['key'] ?? '';
    String fullKey = keyStr.startsWith('/') ? keyStr : '/$keyStr';
    String defaultOpenLibUrl = 'https://openlibrary.org$fullKey';

    String? readLink;
    String? downloadLink;

    if (detailsJson['links'] != null && detailsJson['links'] is List) {
      for (var l in detailsJson['links']) {
        if (l is Map && l['url'] != null) {
          String u = l['url'].toString();
          if (u.contains('archive.org') || u.endsWith('.pdf')) {
            downloadLink = u;
          } else {
            readLink ??= u;
          }
        }
      }
    }

    readLink ??= defaultOpenLibUrl;
    downloadLink ??= defaultOpenLibUrl;

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
    String category = subjectList.isNotEmpty ? subjectList.first : 'General';

    double avgRating = 0.0;
    int count = 0;
    if (ratingJson != null && ratingJson['summary'] != null) {
      final summary = ratingJson['summary'] as Map<String, dynamic>;
      avgRating = (summary['average'] as num?)?.toDouble() ?? 0.0;
      count = (summary['count'] as num?)?.toInt() ?? 0;
    }

    return BookDetailModel(
      key: keyStr,
      title: detailsJson['title'] ?? 'No Title',
      description: descText,
      primaryCategory: category,
      subjects: subjectList,
      averageRating: avgRating,
      ratingCount: count,
      readUrl: readLink,
      downloadUrl: downloadLink,
    );
  }
}
