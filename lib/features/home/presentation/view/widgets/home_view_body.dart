import 'package:flutter/material.dart';
import 'package:libris_app/features/home/presentation/view/widgets/custom_appbar.dart';
import 'package:libris_app/features/home/presentation/view/widgets/featured_books_section.dart';
import 'package:libris_app/features/home/presentation/view/widgets/filter_chips_list.dart';

class HomeViewBody extends StatelessWidget {
  const HomeViewBody({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Column(
        children: [
          CustomAppBar(),
          SizedBox(height: 15),

          Padding(
            padding: EdgeInsets.only(left: 20),
            child: FeaturedBooksSection(),
          ),
          SizedBox(height: 48),
          Padding(padding: EdgeInsets.only(left: 20), child: FilterChipsList()),
        ],
      ),
    );
  }
}
