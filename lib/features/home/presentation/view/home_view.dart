import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libris_app/features/home/presentation/manager/featured%20books%20cubit/featured_books_cubit.dart';
import 'package:libris_app/features/home/presentation/view/widgets/home_view_body.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FeaturedBooksCubit()..fetchFeaturedBooks(),
      child: const HomeViewBody(),
    );
  }
}
