import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libris_app/features/explore/presentation/manager/explore_cubit/explore_cubit.dart';
import 'package:libris_app/features/explore/presentation/view/widgets/explore_view_body.dart';

class ExploreView extends StatelessWidget {
  final String? initialQuery;

  const ExploreView({super.key, this.initialQuery});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ExploreCubit(),
      child: ExploreViewBody(initialQuery: initialQuery),
    );
  }
}
