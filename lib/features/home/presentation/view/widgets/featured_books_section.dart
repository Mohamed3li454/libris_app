import 'package:flutter/material.dart';
import 'package:libris_app/core/utils/styles.dart';

class FeaturedBooksSection extends StatelessWidget {
  const FeaturedBooksSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Featured for you",
          style: Styles.intelStyle.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 16),
        const SizedBox(height: 290, child: FeaturedListViewBuilder()),
      ],
    );
  }
}

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
    _pageController = PageController(viewportFraction: 0.55);
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
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _pageController,
          builder: (context, child) {
            double page = 0.0;
            if (_pageController.position.haveDimensions) {
              page = _pageController.page ?? 0.0;
            } else {
              page = index.toDouble();
            }

            double scale = (1 - ((page - index).abs() * 0.15)).clamp(0.8, 1.0);

            return Transform.scale(scale: scale, child: child);
          },
          child: const FeatureBookListView(),
        );
      },
    );
  }
}

class FeatureBookListView extends StatelessWidget {
  const FeatureBookListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage("assets/book.jpg"),
          fit: BoxFit.fill,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
