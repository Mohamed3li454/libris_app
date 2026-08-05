part of 'filter_books_cubit.dart';

abstract class FilterBooksState extends Equatable {
  const FilterBooksState();

  @override
  List<Object> get props => [];
}

class FilterBooksInitial extends FilterBooksState {}

class FilterBooksLoading extends FilterBooksState {}

class FilterBooksSuccess extends FilterBooksState {
  final List<BookModel> books;
  final String category;

  const FilterBooksSuccess({required this.books, required this.category});

  @override
  List<Object> get props => [books, category];
}

class FilterBooksFailure extends FilterBooksState {
  final String errMessage;

  const FilterBooksFailure(this.errMessage);

  @override
  List<Object> get props => [errMessage];
}
