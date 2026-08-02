import 'package:flutter/material.dart';
import 'package:libris_app/features/details/presentation/view/widgets/book_action_bottom_bar.dart';
import 'package:libris_app/features/details/presentation/view/widgets/details_view_body.dart';

class DetailsView extends StatelessWidget {
  const DetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: DetailsViewBody(),
      bottomNavigationBar: BookActionBottomBar(),
    );
  }
}
