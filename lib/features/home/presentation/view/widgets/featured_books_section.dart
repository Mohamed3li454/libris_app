import 'package:flutter/material.dart';
import 'package:libris_app/core/utils/styles.dart';

class FeaturedBooksSection extends StatelessWidget {
  const FeaturedBooksSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Featured for you",
                style: Styles.intelStyle.copyWith(fontSize: 22),
              ),
              TextButton(onPressed: () {}, child: const Text("See All")),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const SizedBox(height: 300, child: FeaturedListViewBuilder()),
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

class FeatureBookListView extends StatelessWidget {
  const FeatureBookListView({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2.6 / 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 5,
            ),
          ],
          image: const DecorationImage(
            image: AssetImage("assets/book.jpg"),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
