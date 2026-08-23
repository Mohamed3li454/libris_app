class BookResponseModel {
  final List<BookModel> books;

  BookResponseModel({required this.books});

  factory BookResponseModel.fromJson(Map<String, dynamic> json) {
    List rawList = json['works'] ?? json['docs'] ?? [];
    return BookResponseModel(
      books: rawList
          .map(
            (item) =>
                BookModel.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
    );
  }
}

class BookModel {
  final String key;
  final String title;
  final String authorName;
  final String coverUrl;
  final int? firstPublishYear;
  final String? collection;

  BookModel({
    required this.key,
    required this.title,
    required this.authorName,
    required this.coverUrl,
    this.firstPublishYear,
    this.collection,
  });

  factory BookModel.fromJson(Map<String, dynamic> json) {
    final int? coverId = json['cover_id'] ?? json['cover_i'];
    final String coverImage =
        json['cover_url'] ??
        (coverId != null
            ? 'https://covers.openlibrary.org/b/id/$coverId-L.jpg'
            : 'https://via.placeholder.com/150?text=No+Cover');

    String author = 'Unknown Author';
    if (json['authors'] != null && (json['authors'] as List).isNotEmpty) {
      final firstAuthor = (json['authors'] as List).first;
      if (firstAuthor is Map) {
        author = firstAuthor['name'] ?? 'Unknown Author';
      } else {
        author = firstAuthor.toString();
      }
    } else if (json['author_name'] != null &&
        (json['author_name'] as List).isNotEmpty) {
      author = (json['author_name'] as List).first.toString();
    }

    return BookModel(
      key: json['key'] ?? '',
      title: json['title'] ?? 'No Title',
      authorName: author,
      coverUrl: coverImage,
      firstPublishYear: json['first_publish_year'],
      collection: json['collection'] is String ? json['collection'] : null,
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
    };
  }
}
