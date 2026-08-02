import 'package:flutter/material.dart';
import 'package:libris_app/features/home/presentation/view/widgets/feature_book_list_view.dart';

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
    return PageView.builder(
      padEnds: false,
      controller: _pageController,
      itemCount: 10,
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
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: FeatureBookListView(),
          ),
        );
      },
    );
  }
}
