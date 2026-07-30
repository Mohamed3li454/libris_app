import 'package:flutter/material.dart';
import 'package:libris_app/features/home/presentation/view/home_view.dart';
import 'constants/app_colors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.background,
          surfaceTint: AppColors.background,
        ),
        scaffoldBackgroundColor: AppColors.background,
      ),
      home: const HomeView(),
    );
  }
}
