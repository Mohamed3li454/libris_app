import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libris_app/core/models/book_model.dart';
import 'package:libris_app/core/utils/api_service.dart';
import 'package:libris_app/core/utils/dio_factory.dart';
import 'package:libris_app/features/home/data/repos/home_repo.dart';
import 'package:libris_app/features/home/data/repos/home_repo_impl.dart';

part 'featured_books_state.dart';

class FeaturedBooksCubit extends Cubit<FeaturedBooksState> {
  final HomeRepo homeRepo;

  FeaturedBooksCubit({HomeRepo? homeRepo})
    : homeRepo =
          homeRepo ?? HomeRepoImpl(apiService: ApiService(DioFactory.dio)),
      super(FeaturedBooksInitial());

  Future<void> fetchFeaturedBooks() async {
    emit(FeaturedBooksLoading());

    var result = await homeRepo.fetchFeaturedBooks();
    if (isClosed) return;

    result.fold(
      (failure) {
        if (!isClosed) emit(FeaturedBooksFailure(failure.errMessage));
      },
      (books) {
        if (!isClosed) emit(FeaturedBooksSuccess(books));
      },
    );
  }
}
