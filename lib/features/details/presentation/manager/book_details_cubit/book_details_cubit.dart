import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libris_app/core/utils/api_service.dart';
import 'package:libris_app/features/details/data/models/book_detail_model.dart';
import 'package:libris_app/features/details/data/repos/details_repo.dart';
import 'package:libris_app/features/details/data/repos/details_repo_impl.dart';

part 'book_details_state.dart';

class BookDetailsCubit extends Cubit<BookDetailsState> {
  final DetailsRepo detailsRepo;

  BookDetailsCubit({DetailsRepo? detailsRepo})
      : detailsRepo =
            detailsRepo ?? DetailsRepoImpl(apiService: ApiService(Dio())),
        super(BookDetailsInitial());

  Future<void> fetchBookDetails({required String workKey}) async {
    emit(BookDetailsLoading());

    var result = await detailsRepo.fetchBookDetails(workKey);

    if (isClosed) return;

    result.fold(
      (failure) {
        if (!isClosed) emit(BookDetailsFailure(failure.errMessage));
      },
      (bookDetail) {
        if (!isClosed) emit(BookDetailsSuccess(bookDetail));
      },
    );
  }
}
