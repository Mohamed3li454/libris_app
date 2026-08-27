import 'package:libris_app/core/utils/api_service.dart';
import 'package:libris_app/core/utils/dio_factory.dart';
import 'package:libris_app/features/details/data/repos/details_repo.dart';
import 'package:libris_app/features/details/data/repos/details_repo_impl.dart';
import 'package:libris_app/features/explore/data/repos/search_repo.dart';
import 'package:libris_app/features/explore/data/repos/search_repo_impl.dart';
import 'package:libris_app/features/home/data/repos/home_repo.dart';
import 'package:libris_app/features/home/data/repos/home_repo_impl.dart';
import 'package:libris_app/features/library/data/repos/favorites_repo.dart';
import 'package:libris_app/features/library/data/repos/favorites_repo_impl.dart';

class ServiceLocator {
  ServiceLocator._();

  static late final ApiService apiService;
  static late final HomeRepo homeRepo;
  static late final SearchRepo searchRepo;
  static late final DetailsRepo detailsRepo;
  static late final FavoritesRepo favoritesRepo;

  static void init() {
    apiService = ApiService(DioFactory.dio);
    homeRepo = HomeRepoImpl(apiService: apiService);
    searchRepo = SearchRepoImpl(apiService: apiService);
    detailsRepo = DetailsRepoImpl(apiService: apiService);
    favoritesRepo = FavoritesRepoImpl();
  }
}
