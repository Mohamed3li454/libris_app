class BookResponseModel {
  final int totalItems;
  final List<BookModel> books;

  BookResponseModel({required this.totalItems, required this.books});

  factory BookResponseModel.fromJson(Map<String, dynamic> json) {
    return BookResponseModel(
      totalItems: json['totalItems'] ?? 0,
      books: json['items'] != null
          ? List<BookModel>.from(
              (json['items'] as List).map((x) => BookModel.fromJson(x)),
            )
          : [],
    );
  }
}

class BookModel {
  final String id;
  final String title;
  final String author;
  final String publisher;
  final String publishedDate;
  final String description;
  final String coverUrl;
  final String category;
  final int pageCount;
  final String language;
  final String webReaderLink;
  final String previewLink;

  BookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.publisher,
    required this.publishedDate,
    required this.description,
    required this.coverUrl,
    required this.category,
    required this.pageCount,
    required this.language,
    required this.webReaderLink,
    required this.previewLink,
  });

  factory BookModel.fromJson(Map<String, dynamic> json) {
    final volumeInfo = json['volumeInfo'] as Map<String, dynamic>? ?? {};
    final accessInfo = json['accessInfo'] as Map<String, dynamic>? ?? {};
    final imageLinks = volumeInfo['imageLinks'] as Map<String, dynamic>? ?? {};

    String rawCoverUrl =
        imageLinks['thumbnail'] ?? imageLinks['smallThumbnail'] ?? '';
    String secureCoverUrl = rawCoverUrl.replaceFirst('http://', 'https://');

    List authorsList = volumeInfo['authors'] as List? ?? [];
    String authorName = authorsList.isNotEmpty
        ? authorsList.first.toString()
        : 'Unknown Author';

    List categoriesList = volumeInfo['categories'] as List? ?? [];
    String categoryName = categoriesList.isNotEmpty
        ? categoriesList.first.toString()
        : 'General';

    return BookModel(
      id: json['id'] ?? '',
      title: volumeInfo['title'] ?? 'No Title',
      author: authorName,
      publisher: volumeInfo['publisher'] ?? 'Unknown Publisher',
      publishedDate: volumeInfo['publishedDate'] ?? '',
      description:
          volumeInfo['description'] ??
          'No description available for this book.',
      coverUrl: secureCoverUrl,
      category: categoryName,
      pageCount: volumeInfo['pageCount'] ?? 0,
      language: (volumeInfo['language'] ?? 'en').toString().toUpperCase(),
      webReaderLink: accessInfo['webReaderLink'] ?? '',
      previewLink: volumeInfo['previewLink'] ?? '',
    );
  }
}
