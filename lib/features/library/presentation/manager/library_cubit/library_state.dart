part of 'library_cubit.dart';

abstract class LibraryState extends Equatable {
  const LibraryState();

  @override
  List<Object?> get props => [];
}

class LibraryInitial extends LibraryState {}

class LibraryLoading extends LibraryState {}

class LibrarySuccess extends LibraryState {
  final List<BookModel> books;

  const LibrarySuccess(this.books);

  @override
  List<Object?> get props => [books];
}

class LibraryEmpty extends LibraryState {}

class LibraryFailure extends LibraryState {
  final String errMessage;

  const LibraryFailure(this.errMessage);

  @override
  List<Object?> get props => [errMessage];
}
