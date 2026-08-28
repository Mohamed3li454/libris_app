import 'package:go_router/go_router.dart';
import 'package:libris_app/core/models/book_model.dart';
import 'package:libris_app/core/widgets/page_transitions.dart';
import 'package:libris_app/features/details/presentation/view/details_view.dart';
import 'package:libris_app/features/main/presentation/view/main_navigation_view.dart';
import 'package:libris_app/features/onboarding/presentation/view/onboarding_view.dart';
import 'package:libris_app/features/settings/presentation/view/settings_view.dart';
import 'package:libris_app/features/splash/presentation/view/splash_view.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashView(),
    ),
    GoRoute(
      path: '/onboarding',
      pageBuilder: (context, state) => fadeSlidePage(
        key: state.pageKey,
        child: const OnboardingView(),
      ),
    ),
    GoRoute(
      path: '/main',
      pageBuilder: (context, state) => fadeSlidePage(
        key: state.pageKey,
        child: const MainNavigationView(),
      ),
    ),
    GoRoute(
      path: '/details',
      pageBuilder: (context, state) {
        final bookModel = state.extra as BookModel?;
        return fadeSlidePage(
          key: state.pageKey,
          child: DetailsView(bookModel: bookModel),
        );
      },
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) => fadeSlidePage(
        key: state.pageKey,
        child: const SettingsView(),
      ),
    ),
  ],
);
