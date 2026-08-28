import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:libris_app/core/widgets/shimmer_container.dart';

class ExploreShimmerLoading extends StatelessWidget {
  const ExploreShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 6,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: const Row(
              children: [
                ShimmerContainer(
                  width: 80,
                  height: 110,
                  borderRadius: 12,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerContainer(
                        width: double.infinity,
                        height: 16,
                      ),
                      SizedBox(height: 8),
                      ShimmerContainer(
                        width: 120,
                        height: 14,
                      ),
                      SizedBox(height: 12),
                      ShimmerContainer(
                        width: 60,
                        height: 14,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
