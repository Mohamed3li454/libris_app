import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:libris_app/constants/hive_constants.dart';
import 'package:libris_app/core/di/service_locator.dart';
import 'package:libris_app/core/theme/app_theme.dart';
import 'package:libris_app/core/widgets/router.dart';
import 'package:libris_app/features/library/presentation/manager/library_cubit/library_cubit.dart';
import 'package:libris_app/features/settings/presentation/manager/theme_cubit.dart';
import 'package:libris_app/core/services/connectivity_cubit.dart';
import 'package:libris_app/core/widgets/offline_banner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await _openBoxSafe(kFeaturedBox);
  await _openBoxSafe(kFilterBox);
  await _openBoxSafe(kFavoritesBox);
  ServiceLocator.init();
  runApp(const MyApp());
}

/// Opens a Hive box safely. If the box file is corrupted, it deletes the box
/// from disk and retries once. This prevents fatal startup crashes.
Future<void> _openBoxSafe(String boxName) async {
  try {
    await Hive.openBox(boxName);
  } catch (_) {
    await Hive.deleteBoxFromDisk(boxName);
    await Hive.openBox(boxName);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => LibraryCubit()..fetchFavoriteBooks()),
        BlocProvider(create: (_) => ConnectivityCubit()..checkConnectivity()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            routerConfig: router,
            builder: (context, child) {
              return Stack(
                children: [
                  ?child,
                  BlocBuilder<ConnectivityCubit, ConnectivityState>(
                    builder: (context, state) {
                      final isOffline = state is ConnectivityDisconnected;
                      return AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        top: isOffline ? 0 : -100,
                        left: 0,
                        right: 0,
                        child: const OfflineBanner(),
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
