import 'dart:async';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libris_app/core/models/book_model.dart';
import 'package:libris_app/core/utils/api_service.dart';
import 'package:libris_app/features/explore/data/repos/search_repo.dart';
import 'package:libris_app/features/explore/data/repos/search_repo_impl.dart';

part 'explore_state.dart';

class ExploreCubit extends Cubit<ExploreState> {
  final SearchRepo searchRepo;
  Timer? _debounceTimer;

  ExploreCubit({SearchRepo? searchRepo})
      : searchRepo =
            searchRepo ?? SearchRepoImpl(apiService: ApiService(Dio())),
        super(ExploreInitial());

  void searchBooksDebounced(String query) {
    _debounceTimer?.cancel();
    final cleanQuery = query.trim();

    if (cleanQuery.isEmpty || cleanQuery.length < 3) {
      if (!isClosed) emit(ExploreInitial());
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      searchBooks(cleanQuery);
    });
  }

  Future<void> searchBooks(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty || cleanQuery.length < 3) {
      if (!isClosed) emit(ExploreInitial());
      return;
    }

    emit(ExploreLoading());
    var result = await searchRepo.searchBooks(cleanQuery);
    if (isClosed) return;

    result.fold(
      (failure) {
        if (!isClosed) emit(ExploreFailure(failure.errMessage));
      },
      (books) {
        if (!isClosed) {
          if (books.isEmpty) {
            emit(ExploreEmpty(cleanQuery));
          } else {
            emit(ExploreSuccess(books: books, query: cleanQuery));
          }
        }
      },
    );
  }

  Future<void> fetchBooksBySubject(String subject) async {
    _debounceTimer?.cancel();
    emit(ExploreLoading());
    var result = await searchRepo.fetchBooksBySubject(subject);
    if (isClosed) return;

    result.fold(
      (failure) {
        if (!isClosed) emit(ExploreFailure(failure.errMessage));
      },
      (books) {
        if (!isClosed) {
          if (books.isEmpty) {
            emit(ExploreEmpty(subject));
          } else {
            emit(ExploreSuccess(books: books, activeCategory: subject));
          }
        }
      },
    );
  }

  void resetSearch() {
    _debounceTimer?.cancel();
    if (!isClosed) emit(ExploreInitial());
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
