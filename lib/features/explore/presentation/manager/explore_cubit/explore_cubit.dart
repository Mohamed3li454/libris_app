import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libris_app/core/models/book_model.dart';
import 'package:libris_app/core/utils/api_service.dart';
import 'package:libris_app/core/utils/dio_factory.dart';
import 'package:libris_app/features/explore/data/repos/search_repo.dart';
import 'package:libris_app/features/explore/data/repos/search_repo_impl.dart';

part 'explore_state.dart';

class ExploreCubit extends Cubit<ExploreState> {
  static const int _pageSize = 20;

  final SearchRepo searchRepo;
  Timer? _debounceTimer;
  List<BookModel> _books = [];
  int _currentPage = 1;
  bool _hasMore = false;
  bool _isLoadingMore = false;
  String _lastQuery = '';
  String _lastSubject = '';
  ExploreMode _mode = ExploreMode.none;

  ExploreCubit({SearchRepo? searchRepo})
    : searchRepo =
          searchRepo ?? SearchRepoImpl(apiService: ApiService(DioFactory.dio)),
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

    _mode = ExploreMode.search;
    _lastQuery = cleanQuery;
    _lastSubject = '';
    _currentPage = 1;
    _hasMore = false;
    _isLoadingMore = false;
    _books = [];

    emit(ExploreLoading());
    var result = await searchRepo.searchBooks(
      cleanQuery,
      page: _currentPage,
      limit: _pageSize,
    );
    if (isClosed) return;

    result.fold(
      (failure) {
        if (!isClosed) emit(ExploreFailure(failure.errMessage));
      },
      (books) {
        _books = books;
        _hasMore = books.length >= _pageSize;
        _currentPage = 2;
        if (!isClosed) {
          if (_books.isEmpty) {
            emit(ExploreEmpty(cleanQuery));
          } else {
            emit(
              ExploreSuccess(
                books: _books,
                query: cleanQuery,
                hasMore: _hasMore,
              ),
            );
          }
        }
      },
    );
  }

  Future<void> fetchBooksBySubject(String subject) async {
    _debounceTimer?.cancel();
    _mode = ExploreMode.subject;
    _lastSubject = subject;
    _lastQuery = '';
    _currentPage = 1;
    _hasMore = false;
    _isLoadingMore = false;
    _books = [];

    emit(ExploreLoading());
    var result = await searchRepo.fetchBooksBySubject(
      subject,
      page: _currentPage,
      limit: _pageSize,
    );
    if (isClosed) return;

    result.fold(
      (failure) {
        if (!isClosed) emit(ExploreFailure(failure.errMessage));
      },
      (books) {
        _books = books;
        _hasMore = books.length >= _pageSize;
        _currentPage = 2;
        if (!isClosed) {
          if (_books.isEmpty) {
            emit(ExploreEmpty(subject));
          } else {
            emit(
              ExploreSuccess(
                books: _books,
                activeCategory: subject,
                hasMore: _hasMore,
              ),
            );
          }
        }
      },
    );
  }

  Future<void> fetchTrendingBooks({int limit = 50}) async {
    _debounceTimer?.cancel();
    _mode = ExploreMode.trending;
    _lastQuery = '';
    _lastSubject = '';
    _currentPage = 1;
    _hasMore = false;
    _isLoadingMore = false;
    _books = [];

    emit(ExploreLoading());
    var result = await searchRepo.fetchTrendingBooks(limit: limit);
    if (isClosed) return;

    result.fold(
      (failure) {
        if (!isClosed) emit(ExploreFailure(failure.errMessage));
      },
      (books) {
        _books = books;
        if (!isClosed) {
          if (_books.isEmpty) {
            emit(const ExploreEmpty('Featured Books'));
          } else {
            emit(
              ExploreSuccess(
                books: _books,
                query: 'Featured Books',
                hasMore: false,
              ),
            );
          }
        }
      },
    );
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    if (_mode == ExploreMode.none || _mode == ExploreMode.trending) return;
    if (state is! ExploreSuccess) return;

    _isLoadingMore = true;
    final current = state as ExploreSuccess;
    emit(
      ExploreSuccess(
        books: current.books,
        query: current.query,
        activeCategory: current.activeCategory,
        hasMore: current.hasMore,
        isLoadingMore: true,
      ),
    );

    final result = _mode == ExploreMode.search
        ? await searchRepo.searchBooks(
            _lastQuery,
            page: _currentPage,
            limit: _pageSize,
          )
        : await searchRepo.fetchBooksBySubject(
            _lastSubject,
            page: _currentPage,
            limit: _pageSize,
          );

    if (isClosed) return;

    result.fold(
      (failure) {
        _isLoadingMore = false;
        if (!isClosed) {
          emit(ExploreFailure(failure.errMessage));
        }
      },
      (newBooks) {
        _isLoadingMore = false;
        _books = [..._books, ...newBooks];
        _hasMore = newBooks.length >= _pageSize;
        _currentPage += 1;

        if (!isClosed) {
          emit(
            ExploreSuccess(
              books: _books,
              query: _mode == ExploreMode.search ? _lastQuery : null,
              activeCategory: _mode == ExploreMode.subject
                  ? _lastSubject
                  : null,
              hasMore: _hasMore,
              isLoadingMore: false,
            ),
          );
        }
      },
    );
  }

  void resetSearch() {
    _debounceTimer?.cancel();
    _books = [];
    _currentPage = 1;
    _hasMore = false;
    _isLoadingMore = false;
    _lastQuery = '';
    _lastSubject = '';
    _mode = ExploreMode.none;
    if (!isClosed) emit(ExploreInitial());
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}

enum ExploreMode { none, search, subject, trending }
