import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:libris_app/core/models/book_model.dart';
import 'package:libris_app/core/utils/app_routes.dart';
import 'package:libris_app/core/widgets/page_transitions.dart';
import 'package:libris_app/features/details/presentation/view/details_view.dart';
import 'package:libris_app/features/main/presentation/view/main_navigation_view.dart';
import 'package:libris_app/features/onboarding/presentation/view/onboarding_view.dart';
import 'package:libris_app/features/settings/presentation/view/settings_view.dart';
import 'package:libris_app/features/splash/presentation/view/splash_view.dart';
import 'package:libris_app/features/details/presentation/view/book_reader_view.dart';

final router = GoRouter(
  initialLocation: AppRoutes.splash,
  errorBuilder: (context, state) =>
      const Scaffold(body: Center(child: Text('Page not found'))),
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashView(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      pageBuilder: (context, state) =>
          fadeSlidePage(key: state.pageKey, child: const OnboardingView()),
    ),
    GoRoute(
      path: AppRoutes.main,
      pageBuilder: (context, state) =>
          fadeSlidePage(key: state.pageKey, child: const MainNavigationView()),
    ),
    GoRoute(
      path: AppRoutes.details,
      pageBuilder: (context, state) {
        final bookModel = state.extra as BookModel?;
        return fadeSlidePage(
          key: state.pageKey,
          child: DetailsView(bookModel: bookModel),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.settings,
      pageBuilder: (context, state) =>
          fadeSlidePage(key: state.pageKey, child: const SettingsView()),
    ),
    GoRoute(
      path: AppRoutes.bookReader,
      pageBuilder: (context, state) {
        final url = state.extra as String;
        return fadeUpFadeRightPage(
          key: state.pageKey,
          child: BookReaderView(url: url),
        );
      },
    ),
  ],
);
