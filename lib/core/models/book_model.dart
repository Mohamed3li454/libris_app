class BookResponseModel {
  final List<BookModel> books;

  BookResponseModel({required this.books});

  factory BookResponseModel.fromJson(Map<String, dynamic> json) {
    return BookResponseModel(
      books:
          (json['works'] as List<dynamic>?)
              ?.map((item) => BookModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class BookModel {
  final String key;
  final String title;
  final String authorName;
  final String coverUrl;
  final int? firstPublishYear;

  BookModel({
    required this.key,
    required this.title,
    required this.authorName,
    required this.coverUrl,
    this.firstPublishYear,
  });

  factory BookModel.fromJson(Map<String, dynamic> json) {
    final int? coverId = json['cover_i'];
    final String coverImage = coverId != null
        ? 'https://covers.openlibrary.org/b/id/$coverId-L.jpg'
        : 'https://via.placeholder.com/150?text=No+Cover';

    final List<dynamic>? authors = json['author_name'];
    final String author = (authors != null && authors.isNotEmpty)
        ? authors.first.toString()
        : 'Unknown Author';

    return BookModel(
      key: json['key'] ?? '',
      title: json['title'] ?? 'No Title',
      authorName: author,
      coverUrl: coverImage,
      firstPublishYear: json['first_publish_year'],
    );
  }
}
