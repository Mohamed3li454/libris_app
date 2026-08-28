import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libris_app/core/widgets/custom_error_widget.dart';
import 'package:libris_app/features/home/presentation/manager/featured_books_cubit/featured_books_cubit.dart';
import 'package:libris_app/features/home/presentation/view/widgets/feature_book_item.dart';
import 'package:libris_app/features/home/presentation/view/widgets/featured_books_shimmer_loading.dart';

class FeaturedListViewBuilder extends StatefulWidget {
  const FeaturedListViewBuilder({super.key});

  @override
  State<FeaturedListViewBuilder> createState() =>
      _FeaturedListViewBuilderState();
}

class _FeaturedListViewBuilderState extends State<FeaturedListViewBuilder> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.6);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FeaturedBooksCubit, FeaturedBooksState>(
      builder: (context, state) {
        Widget child;
        if (state is FeaturedBooksLoading) {
          child = const FeaturedBooksShimmerLoading();
        } else if (state is FeaturedBooksSuccess) {
          child = PageView.builder(
            padEnds: false,
            controller: _pageController,
            itemCount: state.books.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 0.0;
                  if (_pageController.position.haveDimensions) {
                    value = (_pageController.page! - index);
                  } else {
                    value = (index == 0) ? 0 : 1;
                  }

                  double scale = (1 - (value.abs() * 0.15)).clamp(0.85, 1.0);
                  double opacity = (1 - (value.abs() * 0.3)).clamp(0.7, 1.0);

                  return Transform.scale(
                    scale: scale,
                    child: Opacity(opacity: opacity, child: child),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 8,
                  ),
                  child: FeatureBookItem(bookModel: state.books[index]),
                ),
              );
            },
            );
        } else if (state is FeaturedBooksFailure) {
          child = CustomErrorWidget(
            errMessage: state.errMessage,
            onRetry: () {
              BlocProvider.of<FeaturedBooksCubit>(
                context,
              ).fetchFeaturedBooks();
            },
          );
        } else {
          child = const SizedBox();
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: KeyedSubtree(
            key: ValueKey(state.runtimeType),
            child: child,
          ),
        );
      },
    );
  }
}
