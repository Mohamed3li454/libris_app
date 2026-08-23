import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libris_app/core/models/book_model.dart';
import 'package:libris_app/features/library/data/repos/favorites_repo.dart';
import 'package:libris_app/features/library/data/repos/favorites_repo_impl.dart';

part 'library_state.dart';

class LibraryCubit extends Cubit<LibraryState> {
  final FavoritesRepo favoritesRepo;
  String selectedCollection = 'All';

  static const List<String> collections = [
    'All',
    'Favorites',
    'Want to Read',
    'Finished',
  ];

  LibraryCubit({FavoritesRepo? favoritesRepo})
    : favoritesRepo = favoritesRepo ?? FavoritesRepoImpl(),
      super(LibraryInitial());

  void fetchFavoriteBooks() {
    emit(LibraryLoading());
    try {
      final books = favoritesRepo.getFavoriteBooks(
        collection: selectedCollection,
      );
      if (isClosed) return;

      if (books.isEmpty) {
        emit(LibraryEmpty(selectedCollection));
      } else {
        emit(
          LibrarySuccess(books: books, selectedCollection: selectedCollection),
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

  Future<void> moveBookToCollection(String key, String collection) async {
    await favoritesRepo.updateBookCollection(key, collection);
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
