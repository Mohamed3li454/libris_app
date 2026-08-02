import 'package:flutter/material.dart';
import 'package:libris_app/features/home/presentation/view/widgets/filter_book_item.dart';

class FilterBookSliverListView extends StatelessWidget {
  const FilterBookSliverListView({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 9),
          child: FilterBookItem(),
        );
      }, childCount: 10),
    );
  }
}
