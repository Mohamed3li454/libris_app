import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libris_app/core/models/book_model.dart';
import 'package:libris_app/core/utils/api_service.dart';
import 'package:libris_app/features/home/data/repos/home_repo_impl.dart';

part 'filter_books_state.dart';

class FilterBooksCubit extends Cubit<FilterBooksState> {
  FilterBooksCubit() : super(FilterBooksInitial());

  final homeRepo = HomeRepoImpl(apiService: ApiService(Dio()));
  String currentCategory = 'All';

  Future<void> fetchFilterBooks({required String category}) async {
    currentCategory = category;
    emit(FilterBooksLoading());

    var result = await homeRepo.fetchFilterBooks(category: category);
    result.fold(
      (failure) => emit(FilterBooksFailure(failure.errMessage)),
      (books) => emit(FilterBooksSuccess(books: books, category: category)),
    );
  }
}
