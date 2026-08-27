import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libris_app/core/di/service_locator.dart';
import 'package:libris_app/core/models/book_model.dart';
import 'package:libris_app/features/library/data/repos/favorites_repo.dart';

part 'library_state.dart';

enum LibrarySort { recent, title, year }

class LibraryCubit extends Cubit<LibraryState> {
  final FavoritesRepo favoritesRepo;
  String selectedCollection = 'All';
  LibrarySort selectedSort = LibrarySort.recent;
  Map<String, int> collectionCounts = const {};

  static const List<String> collections = [
    'All',
    'Want to Read',
    'Reading',
    'Finished',
    'Favorites',
  ];

  static const List<String> movableCollections = [
    'Want to Read',
    'Reading',
    'Finished',
    'Favorites',
  ];

  LibraryCubit({FavoritesRepo? favoritesRepo})
    : favoritesRepo = favoritesRepo ?? ServiceLocator.favoritesRepo,
      super(LibraryInitial());

  void fetchFavoriteBooks() {
    emit(LibraryLoading());
    try {
      final allBooks = favoritesRepo.getFavoriteBooks(collection: 'All');
      collectionCounts = {
        'All': allBooks.length,
        for (final collection in movableCollections)
          collection: allBooks
              .where((book) => (book.collection ?? 'Favorites') == collection)
              .length,
      };

      var books = selectedCollection == 'All'
          ? allBooks
          : allBooks
                .where(
                  (book) =>
                      (book.collection ?? 'Favorites') == selectedCollection,
                )
                .toList();
      books = _sortBooks(books);

      if (isClosed) return;

      if (books.isEmpty) {
        emit(LibraryEmpty(selectedCollection));
      } else {
        emit(
          LibrarySuccess(
            books: books,
            selectedCollection: selectedCollection,
            sort: selectedSort,
            counts: collectionCounts,
          ),
        );
      }
    } catch (_) {
      if (!isClosed) {
        emit(
          const LibraryFailure('Failed to load saved books. Please try again.'),
        );
      }
    }
  }

  List<BookModel> _sortBooks(List<BookModel> books) {
    final sorted = [...books];
    switch (selectedSort) {
      case LibrarySort.title:
        sorted.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
      case LibrarySort.year:
        sorted.sort(
          (a, b) =>
              (b.firstPublishYear ?? 0).compareTo(a.firstPublishYear ?? 0),
        );
      case LibrarySort.recent:
        sorted.sort((a, b) => (b.addedAt ?? 0).compareTo(a.addedAt ?? 0));
    }
    return sorted;
  }

  Future<bool> toggleFavoriteBook(BookModel book) async {
    final isFav = await favoritesRepo.toggleFavoriteBook(book);
    if (!isClosed) {
      fetchFavoriteBooks();
    }
    return isFav;
  }

  void setCollectionFilter(String collection) {
    selectedCollection = collection;
    fetchFavoriteBooks();
  }

  void setSort(LibrarySort sort) {
    selectedSort = sort;
    fetchFavoriteBooks();
  }

  Future<void> moveBookToCollection(String key, String collection) async {
    await favoritesRepo.updateBookCollection(key, collection);
    if (!isClosed) {
      fetchFavoriteBooks();
    }
  }

  Future<void> updateBookProgress(String key, int progress) async {
    await favoritesRepo.updateBookProgress(key, progress);
    if (!isClosed) {
      fetchFavoriteBooks();
    }
  }

  String exportFavoritesJson() {
    return favoritesRepo.exportFavoritesJson();
  }

  Future<void> importFavoritesJson(String rawJson) async {
    await favoritesRepo.importFavoritesJson(rawJson);
    if (!isClosed) {
      fetchFavoriteBooks();
    }
  }

  Future<void> removeFavoriteBook(String key) async {
    await favoritesRepo.removeFavoriteBook(key);
    if (!isClosed) {
      fetchFavoriteBooks();
    }
  }

  bool isBookFavorite(String key) {
    return favoritesRepo.isBookFavorite(key);
  }
}
