import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libris_app/core/models/book_model.dart';
import 'package:libris_app/features/library/data/repos/favorites_repo.dart';
import 'package:libris_app/features/library/data/repos/favorites_repo_impl.dart';

part 'library_state.dart';

class LibraryCubit extends Cubit<LibraryState> {
  final FavoritesRepo favoritesRepo;

  LibraryCubit({FavoritesRepo? favoritesRepo})
      : favoritesRepo = favoritesRepo ?? FavoritesRepoImpl(),
        super(LibraryInitial());

  void fetchFavoriteBooks() {
    emit(LibraryLoading());
    try {
      final books = favoritesRepo.getFavoriteBooks();
      if (books.isEmpty) {
        emit(LibraryEmpty());
      } else {
        emit(LibrarySuccess(books));
      }
    } catch (e) {
      emit(LibraryFailure(e.toString()));
    }
  }

  Future<bool> toggleFavoriteBook(BookModel book) async {
    final isFav = await favoritesRepo.toggleFavoriteBook(book);
    fetchFavoriteBooks();
    return isFav;
  }

  Future<void> removeFavoriteBook(String key) async {
    await favoritesRepo.removeFavoriteBook(key);
    fetchFavoriteBooks();
  }

  bool isBookFavorite(String key) {
    return favoritesRepo.isBookFavorite(key);
  }
}
