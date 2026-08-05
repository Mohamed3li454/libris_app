class BookModel {
  final String id;
  final String title;
  final String author;
  final String coverUrl;
  final String category;
  final int pageCount;
  final String language;
  final String description;
  final String readerLink;

  BookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.category,
    required this.pageCount,
    required this.language,
    required this.description,
    required this.readerLink,
  });

  factory BookModel.fromJson(Map<String, dynamic> json) {
    final volumeInfo = json['volumeInfo'] ?? {};
    final accessInfo = json['accessInfo'] ?? {};
    final imageLinks = volumeInfo['imageLinks'] ?? {};

    String rawCover =
        imageLinks['thumbnail'] ?? imageLinks['smallThumbnail'] ?? '';
    String secureCover = rawCover.replaceFirst('http://', 'https://');

    List authors = volumeInfo['authors'] ?? [];
    String authorName = authors.isNotEmpty ? authors[0] : 'Unknown Author';

    List categories = volumeInfo['categories'] ?? [];
    String categoryName = categories.isNotEmpty ? categories[0] : 'General';

    return BookModel(
      id: json['id'] ?? '',
      title: volumeInfo['title'] ?? 'No Title',
      author: authorName,
      coverUrl: secureCover,
      category: categoryName,
      pageCount: volumeInfo['pageCount'] ?? 0,
      language: (volumeInfo['language'] ?? 'EN').toString().toUpperCase(),
      description: volumeInfo['description'] ?? 'No description available.',
      readerLink: accessInfo['webReaderLink'] ?? '',
    );
  }
}
