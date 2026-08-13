import 'package:flutter/material.dart';
import 'package:libris_app/core/utils/styles.dart';
import 'package:libris_app/features/home/presentation/view/widgets/featured_list_view_builder.dart';
import 'package:libris_app/features/main/presentation/view/main_navigation_view.dart';

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
              TextButton(
                onPressed: () {
                  MainNavigationView.of(
                    context,
                  )?.navigateToExploreWithQuery("trending_all");
                },
                child: const Text("See All"),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const SizedBox(height: 300, child: FeaturedListViewBuilder()),
      ],
    );
  }
}
