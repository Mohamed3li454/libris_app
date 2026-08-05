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

  const BookDetailsSuccess(this.bookDetail);

  @override
  List<Object?> get props => [bookDetail];
}

class BookDetailsFailure extends BookDetailsState {
  final String errMessage;

  const BookDetailsFailure(this.errMessage);

  @override
  List<Object?> get props => [errMessage];
}
