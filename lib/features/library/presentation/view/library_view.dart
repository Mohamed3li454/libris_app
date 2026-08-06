import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libris_app/features/library/presentation/manager/library_cubit/library_cubit.dart';
import 'package:libris_app/features/library/presentation/view/widgets/library_view_body.dart';

class LibraryView extends StatelessWidget {
  const LibraryView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LibraryCubit()..fetchFavoriteBooks(),
      child: const LibraryViewBody(),
    );
  }
}
