part of 'book_details_cubit.dart';

abstract class BookDetailsState extends Equatable {
  const BookDetailsState();

  @override
  List<Object?> get props => [];
}

class BookDetailsInitial extends BookDetailsState {}

class BookDetailsLoading extends BookDetailsState {}

class BookDetailsSuccess extends BookDetailsState {
  final BookDetailModel bookDetail;
  final List<BookModel> similarBooks;
  final bool isSimilarLoading;

  const BookDetailsSuccess({
    required this.bookDetail,
    this.similarBooks = const [],
    this.isSimilarLoading = false,
  });

  @override
  List<Object?> get props => [bookDetail, similarBooks, isSimilarLoading];
}

class BookDetailsFailure extends BookDetailsState {
  final String errMessage;

  const BookDetailsFailure(this.errMessage);

  @override
  List<Object?> get props => [errMessage];
}
