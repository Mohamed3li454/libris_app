import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class BookDetailsItem extends StatelessWidget {
  final String? imageUrl;
  final String? heroTag;

  const BookDetailsItem({super.key, this.imageUrl, this.heroTag});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width * 0.45;

    return SizedBox(
      width: width,
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Hero(
            tag: heroTag ?? 'cover-details',
            child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child:
                imageUrl != null && imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.book, color: Colors.grey),
                          ),
                    )
                    : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.book, color: Colors.grey),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
