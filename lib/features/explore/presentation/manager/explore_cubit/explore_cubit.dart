import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libris_app/core/di/service_locator.dart';
import 'package:libris_app/core/models/book_model.dart';
import 'package:libris_app/features/explore/data/repos/search_repo.dart';

part 'explore_state.dart';

class ExploreCubit extends Cubit<ExploreState> {
  static const int _pageSize = 20;

  final SearchRepo searchRepo;
  Timer? _debounceTimer;
  int _activeRequestId = 0;
  List<BookModel> _books = [];
  int _currentPage = 1;
  bool _hasMore = false;
  bool _isLoadingMore = false;
  String _lastQuery = '';
  String _lastSubject = '';
  ExploreMode _mode = ExploreMode.none;

  ExploreCubit({SearchRepo? searchRepo})
    : searchRepo = searchRepo ?? ServiceLocator.searchRepo,
      super(ExploreInitial());

  void searchBooksDebounced(String query) {
    _debounceTimer?.cancel();
    final cleanQuery = query.trim();

    if (cleanQuery.isEmpty || cleanQuery.length < 2) {
      _activeRequestId++;
      resetSearch();
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 650), () {
      searchBooks(cleanQuery);
    });
  }

  Future<void> searchBooks(String query) async {
    _debounceTimer?.cancel();
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty || cleanQuery.length < 2) {
      _activeRequestId++;
      resetSearch();
      return;
    }

    final requestId = ++_activeRequestId;

    _mode = ExploreMode.search;
    _lastQuery = cleanQuery;
    _lastSubject = '';
    _currentPage = 1;
    _hasMore = false;
    _isLoadingMore = false;
    _books = [];

    emit(ExploreLoading());
    final result = await searchRepo.searchBooks(
      cleanQuery,
      page: _currentPage,
      limit: _pageSize,
    );
    if (isClosed || requestId != _activeRequestId) return;

    result.fold(
      (failure) {
        if (!isClosed && requestId == _activeRequestId) {
          emit(ExploreFailure(failure.errMessage));
        }
      },
      (books) {
        if (!isClosed && requestId == _activeRequestId) {
          _books = books;
          _hasMore = books.length >= _pageSize;
          _currentPage = 2;
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
    final requestId = ++_activeRequestId;
    _mode = ExploreMode.subject;
    _lastSubject = subject;
    _lastQuery = '';
    _currentPage = 1;
    _hasMore = false;
    _isLoadingMore = false;
    _books = [];

    emit(ExploreLoading());
    final result = await searchRepo.fetchBooksBySubject(
      subject,
      page: _currentPage,
      limit: _pageSize,
    );
    if (isClosed || requestId != _activeRequestId) return;

    result.fold(
      (failure) {
        if (!isClosed && requestId == _activeRequestId) {
          emit(ExploreFailure(failure.errMessage));
        }
      },
      (books) {
        if (!isClosed && requestId == _activeRequestId) {
          _books = books;
          _hasMore = books.length >= _pageSize;
          _currentPage = 2;
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
    final requestId = ++_activeRequestId;
    _mode = ExploreMode.trending;
    _lastQuery = '';
    _lastSubject = '';
    _currentPage = 1;
    _hasMore = false;
    _isLoadingMore = false;
    _books = [];

    emit(ExploreLoading());
    final result = await searchRepo.fetchTrendingBooks(limit: limit);
    if (isClosed || requestId != _activeRequestId) return;

    result.fold(
      (failure) {
        if (!isClosed && requestId == _activeRequestId) {
          emit(ExploreFailure(failure.errMessage));
        }
      },
      (books) {
        if (!isClosed && requestId == _activeRequestId) {
          _books = books;
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

    final requestId = _activeRequestId;
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

    if (isClosed || requestId != _activeRequestId) return;

    result.fold(
      (failure) {
        _isLoadingMore = false;
        if (!isClosed && requestId == _activeRequestId) {
          emit(
            ExploreSuccess(
              books: _books,
              query: current.query,
              activeCategory: current.activeCategory,
              hasMore: _hasMore,
              isLoadingMore: false,
              loadMoreError: failure.errMessage,
            ),
          );
        }
      },
      (newBooks) {
        _isLoadingMore = false;
        if (!isClosed && requestId == _activeRequestId) {
          _books = [..._books, ...newBooks];
          _hasMore = newBooks.length >= _pageSize;
          _currentPage += 1;

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
    _activeRequestId++;
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
    _activeRequestId++;
    return super.close();
  }
}

enum ExploreMode { none, search, subject, trending }
