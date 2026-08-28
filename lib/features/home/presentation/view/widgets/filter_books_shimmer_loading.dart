import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:libris_app/core/widgets/shimmer_container.dart';

class FilterBooksShimmerLoading extends StatelessWidget {
  const FilterBooksShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ShimmerContainer(
                      height: 120,
                      width: 80,
                      borderRadius: 12,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ShimmerContainer(
                            height: 16,
                            width: double.infinity,
                          ),
                          SizedBox(height: 8),
                          ShimmerContainer(
                            height: 14,
                            width: 130,
                          ),
                          SizedBox(height: 12),
                          ShimmerContainer(
                            height: 14,
                            width: 60,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        childCount: 5,
      ),
    );
  }
}
