import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libris_app/core/di/service_locator.dart';
import 'package:libris_app/core/models/book_model.dart';
import 'package:libris_app/features/details/data/models/book_detail_model.dart';
import 'package:libris_app/features/details/data/repos/details_repo.dart';
import 'package:libris_app/features/explore/data/repos/search_repo.dart';

part 'book_details_state.dart';

class BookDetailsCubit extends Cubit<BookDetailsState> {
  final DetailsRepo detailsRepo;
  final SearchRepo searchRepo;

  BookDetailsCubit({DetailsRepo? detailsRepo, SearchRepo? searchRepo})
    : detailsRepo = detailsRepo ?? ServiceLocator.detailsRepo,
      searchRepo = searchRepo ?? ServiceLocator.searchRepo,
      super(BookDetailsInitial());

  Future<void> fetchBookDetails({
    required String workKey,
    BookModel? book,
  }) async {
    emit(BookDetailsLoading());

    final result = await detailsRepo.fetchBookDetails(workKey, book: book);

    if (isClosed) return;

    await result.fold(
      (failure) async {
        if (!isClosed) emit(BookDetailsFailure(failure.errMessage));
      },
      (bookDetail) async {
        if (!isClosed) {
          emit(
            BookDetailsSuccess(
              bookDetail: bookDetail,
              isSimilarLoading: true,
            ),
          );
        }
        await _loadSimilarBooks(
          workKey: bookDetail.key,
          bookDetail: bookDetail,
        );
      },
    );
  }

  Future<void> _loadSimilarBooks({
    required String workKey,
    required BookDetailModel bookDetail,
  }) async {
    final subject = bookDetail.subjects.isNotEmpty
        ? bookDetail.subjects.first
        : bookDetail.primaryCategory;
    if (subject.isEmpty || subject.toLowerCase() == 'general') {
      if (!isClosed) {
        emit(BookDetailsSuccess(bookDetail: bookDetail));
      }
      return;
    }

    final similar = await searchRepo.fetchBooksBySubject(subject, limit: 10);
    if (isClosed) return;

    similar.fold(
      (_) {
        emit(BookDetailsSuccess(bookDetail: bookDetail));
      },
      (books) {
        final filtered = books
            .where((book) => book.key != workKey && book.key != bookDetail.key)
            .take(8)
            .toList();
        emit(
          BookDetailsSuccess(bookDetail: bookDetail, similarBooks: filtered),
        );
      },
    );
  }
}
