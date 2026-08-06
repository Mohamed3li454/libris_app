part of 'explore_cubit.dart';

abstract class ExploreState extends Equatable {
  const ExploreState();

  @override
  List<Object?> get props => [];
}

class ExploreInitial extends ExploreState {}

class ExploreLoading extends ExploreState {}

class ExploreSuccess extends ExploreState {
  final List<BookModel> books;
  final String? query;
  final String? activeCategory;

  const ExploreSuccess({
    required this.books,
    this.query,
    this.activeCategory,
  });

  @override
  List<Object?> get props => [books, query, activeCategory];
}

class ExploreEmpty extends ExploreState {
  final String query;

  const ExploreEmpty(this.query);

  @override
  List<Object?> get props => [query];
}

class ExploreFailure extends ExploreState {
  final String errMessage;

  const ExploreFailure(this.errMessage);

  @override
  List<Object?> get props => [errMessage];
}
