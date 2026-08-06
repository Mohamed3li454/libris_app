import 'package:flutter/material.dart';

class ExploreEmptyState extends StatelessWidget {
  final String query;

  const ExploreEmptyState({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 44,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No books found for "$query"',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2416),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check for spelling errors or try searching with a different keyword.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
