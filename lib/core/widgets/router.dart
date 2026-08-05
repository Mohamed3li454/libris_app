import 'package:go_router/go_router.dart';
import 'package:libris_app/core/models/book_model.dart';
import 'package:libris_app/features/details/presentation/view/details_view.dart';
import 'package:libris_app/features/main/presentation/view/main_navigation_view.dart';

// GoRouter configuration
final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const MainNavigationView()),
    GoRoute(
      path: '/details',
      builder: (context, state) {
        final bookModel = state.extra as BookModel?;
        return DetailsView(bookModel: bookModel);
      },
    ),
  ],
);
