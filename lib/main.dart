import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:libris_app/constants/app_colors.dart';
import 'package:libris_app/constants/hive_constants.dart';
import 'package:libris_app/core/widgets/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Hive.initFlutter();
  await Hive.openBox(kFeaturedBox);
  await Hive.openBox(kFilterBox);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
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
      routerConfig: router,
    );
  }
}
