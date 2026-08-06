import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libris_app/core/models/book_model.dart';
import 'package:libris_app/core/utils/api_service.dart';
import 'package:libris_app/features/home/data/repos/home_repo.dart';
import 'package:libris_app/features/home/data/repos/home_repo_impl.dart';

part 'filter_books_state.dart';

class FilterBooksCubit extends Cubit<FilterBooksState> {
  final HomeRepo homeRepo;
  String currentCategory = 'All';

  FilterBooksCubit({HomeRepo? homeRepo})
      : homeRepo = homeRepo ?? HomeRepoImpl(apiService: ApiService(Dio())),
        super(FilterBooksInitial());

  Future<void> fetchFilterBooks({required String category}) async {
    currentCategory = category;
    emit(FilterBooksLoading());

    var result = await homeRepo.fetchFilterBooks(category: category);
    if (isClosed) return;

    result.fold(
      (failure) {
        if (!isClosed) emit(FilterBooksFailure(failure.errMessage));
      },
      (books) {
        if (!isClosed) {
          emit(FilterBooksSuccess(books: books, category: category));
        }
      },
    );
  }
}
