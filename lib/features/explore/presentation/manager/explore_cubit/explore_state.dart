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
  final bool hasMore;
  final bool isLoadingMore;

  const ExploreSuccess({
    required this.books,
    this.query,
    this.activeCategory,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  @override
  List<Object?> get props => [
    books,
    query,
    activeCategory,
    hasMore,
    isLoadingMore,
  ];
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
