import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:libris_app/core/models/book_model.dart';
import 'package:libris_app/core/utils/api_service.dart';

import 'package:libris_app/features/home/data/repos/home_repo_impl.dart';

part 'featured_books_state.dart';

class FeaturedBooksCubit extends Cubit<FeaturedBooksState> {
  FeaturedBooksCubit() : super(FeaturedBooksInitial());
  final homerepo = HomeRepoImpl(apiService: ApiService(dio: Dio()));
  Future<void> fetchFeaturedBooks() async {
    emit(FeaturedBooksLoading());

    var result = await homerepo.fetchFeaturedBooks();
    result.fold(
      (failure) => emit(FeaturedBooksFailure(failure.errMessage)),
      (books) => emit(FeaturedBooksSuccess(books)),
    );
  }
}
