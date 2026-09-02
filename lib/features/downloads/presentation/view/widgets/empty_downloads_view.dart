import 'package:flutter/material.dart';
import 'package:libris_app/core/theme/app_theme.dart';

class EmptyDownloadsView extends StatelessWidget {
  const EmptyDownloadsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.pillColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.download_rounded,
              size: 48,
              color: context.colors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No downloads yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.colors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Books you download will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: context.mutedColor),
          ),
        ],
      ),
    );
  }
}
