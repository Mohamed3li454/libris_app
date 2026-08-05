import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FeatureBookItem extends StatelessWidget {
  const FeatureBookItem({super.key, required this.imageUrl});
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        GoRouter.of(context).push('/details');
      },
      child: AspectRatio(
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
            image: DecorationImage(
              image: NetworkImage(imageUrl),
              fit: BoxFit.fill,
            ),
          ),
        ),
      ),
    );
  }
}
