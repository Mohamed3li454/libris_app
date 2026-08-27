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
  final String selectedCollection;
  final LibrarySort sort;
  final Map<String, int> counts;

  const LibrarySuccess({
    required this.books,
    required this.selectedCollection,
    required this.sort,
    required this.counts,
  });

  @override
  List<Object?> get props => [books, selectedCollection, sort, counts];
}

class LibraryEmpty extends LibraryState {
  final String selectedCollection;

  const LibraryEmpty(this.selectedCollection);

  @override
  List<Object?> get props => [selectedCollection];
}

class LibraryFailure extends LibraryState {
  final String errMessage;

  const LibraryFailure(this.errMessage);

  @override
  List<Object?> get props => [errMessage];
}
