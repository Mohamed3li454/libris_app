import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:libris_app/core/widgets/shimmer_container.dart';

class FeaturedBooksShimmerLoading extends StatelessWidget {
  const FeaturedBooksShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
          child: AspectRatio(
            aspectRatio: 2.6 / 4,
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: const ShimmerContainer(borderRadius: 16),
            ),
          ),
        );
      },
    );
  }
}
