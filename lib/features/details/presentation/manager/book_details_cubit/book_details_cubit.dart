import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libris_app/core/utils/api_service.dart';
import 'package:libris_app/features/details/data/models/book_detail_model.dart';
import 'package:libris_app/features/details/data/repos/details_repo_impl.dart';

part 'book_details_state.dart';

class BookDetailsCubit extends Cubit<BookDetailsState> {
  BookDetailsCubit() : super(BookDetailsInitial());

  final detailsRepo = DetailsRepoImpl(apiService: ApiService(Dio()));

  Future<void> fetchBookDetails({required String workKey}) async {
    emit(BookDetailsLoading());

    var result = await detailsRepo.fetchBookDetails(workKey);
    result.fold(
      (failure) => emit(BookDetailsFailure(failure.errMessage)),
      (bookDetail) => emit(BookDetailsSuccess(bookDetail)),
    );
  }
}
