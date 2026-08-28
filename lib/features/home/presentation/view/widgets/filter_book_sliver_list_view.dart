import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libris_app/core/widgets/custom_error_widget.dart';
import 'package:libris_app/core/widgets/fade_slide_in.dart';
import 'package:libris_app/features/home/presentation/manager/filter_books_cubit/filter_books_cubit.dart';
import 'package:libris_app/features/home/presentation/view/widgets/filter_book_item.dart';
import 'package:libris_app/features/home/presentation/view/widgets/filter_books_shimmer_loading.dart';

class FilterBookSliverListView extends StatelessWidget {
  const FilterBookSliverListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FilterBooksCubit, FilterBooksState>(
      builder: (context, state) {
        if (state is FilterBooksSuccess) {
          if (state.books.isEmpty) {
            return const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text("No books found for this category."),
                ),
              ),
            );
          }
          return SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: FadeSlideIn(
                  index: index,
                  child: FilterBookItem(bookModel: state.books[index]),
                ),
              );
            }, childCount: state.books.length),
          );
        } else if (state is FilterBooksFailure) {
          return SliverToBoxAdapter(
            child: CustomErrorWidget(
              errMessage: state.errMessage,
              onRetry: () {
                final cubit = BlocProvider.of<FilterBooksCubit>(context);
                cubit.fetchFilterBooks(category: cubit.currentCategory);
              },
            ),
          );
        } else if (state is FilterBooksLoading) {
          return const FilterBooksShimmerLoading();
        } else {
          return const SliverToBoxAdapter(child: SizedBox());
        }
      },
    );
  }
}
