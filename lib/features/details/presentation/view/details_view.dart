import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libris_app/core/models/book_model.dart';
import 'package:libris_app/features/details/presentation/manager/book_details_cubit/book_details_cubit.dart';
import 'package:libris_app/features/details/presentation/view/widgets/book_action_bottom_bar.dart';
import 'package:libris_app/features/details/presentation/view/widgets/details_view_body.dart';

class DetailsView extends StatelessWidget {
  final BookModel? bookModel;

  const DetailsView({super.key, this.bookModel});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = BookDetailsCubit();
        if (bookModel != null &&
            (bookModel!.key.isNotEmpty ||
                (bookModel!.iaId != null && bookModel!.iaId!.isNotEmpty))) {
          cubit.fetchBookDetails(
            workKey: bookModel!.key.isNotEmpty
                ? bookModel!.key
                : '/ia/${bookModel!.iaId}',
            book: bookModel,
          );
        }
        return cubit;
      },
      child: Scaffold(
        body: DetailsViewBody(bookModel: bookModel),
        bottomNavigationBar: BookActionBottomBar(
          fallbackWorkKey: bookModel?.key,
        ),
      ),
    );
  }
}
