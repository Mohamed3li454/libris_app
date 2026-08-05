part of 'featured_books_cubit.dart';

abstract class FeaturedBooksState extends Equatable {
  const FeaturedBooksState();

  @override
  List<Object> get props => [];
}

class FeaturedBooksInitial extends FeaturedBooksState {}

class FeaturedBooksLoading extends FeaturedBooksState {}

class FeaturedBooksLoaded extends FeaturedBooksState {
  final List<BookModel> books;
  const FeaturedBooksLoaded(this.books);
}

class FeaturedBooksFailure extends FeaturedBooksState {
  final String error;
  const FeaturedBooksFailure(this.error);
}
