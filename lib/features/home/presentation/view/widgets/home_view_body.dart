import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:libris_app/constants/app_colors.dart';
import 'package:libris_app/features/home/presentation/view/widgets/custom_appbar.dart';

class HomeViewBody extends StatelessWidget {
  const HomeViewBody({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Column(children: [CustomAppBar()]));
  }
}
